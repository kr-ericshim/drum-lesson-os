import Foundation
import Observation

enum QueuedWriteKind: String, Codable, Equatable, CaseIterable {
    case calendar

    var label: String {
        switch self {
        case .calendar: "캘린더"
        }
    }
}

enum CalendarQueueOperation: String, Codable, Equatable {
    case create = "eventkit_create"
    case update = "eventkit_update"
    case delete = "eventkit_delete"
    case metadataUpdate = "eventkit_metadata_update"
    case invalidDate = "eventkit_invalid_date"
    case legacyWrite = "eventkit_write"
}

struct QueuedWrite: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: QueuedWriteKind
    var operation: String
    var recordId: EntityID?
    var payloadSummary: String
    var createdAt: Date
    var lastError: String?
    var attemptCount: Int
    var syncUpdate: NativeCalendarSyncUpdateInput?

    init(
        kind: QueuedWriteKind,
        operation: String,
        recordId: EntityID? = nil,
        payloadSummary: String,
        lastError: String? = nil,
        syncUpdate: NativeCalendarSyncUpdateInput? = nil
    ) {
        self.id = UUID()
        self.kind = kind
        self.operation = operation
        self.recordId = recordId
        self.payloadSummary = payloadSummary
        self.createdAt = Date()
        self.lastError = lastError
        self.attemptCount = 0
        self.syncUpdate = syncUpdate
    }

    var operationLabel: String {
        switch operation {
        case CalendarQueueOperation.create.rawValue: "캘린더 생성"
        case CalendarQueueOperation.update.rawValue: "캘린더 수정"
        case CalendarQueueOperation.delete.rawValue: "캘린더 삭제"
        case CalendarQueueOperation.metadataUpdate.rawValue: "캘린더 상태 저장"
        case CalendarQueueOperation.legacyWrite.rawValue: "캘린더 저장"
        case CalendarQueueOperation.invalidDate.rawValue: "캘린더 날짜 오류"
        default: operation
        }
    }
}

@Observable
@MainActor
final class LocalWriteQueue {
    private(set) var writes: [QueuedWrite] = []
    private let storageURL: URL?

    var hasPendingWrites: Bool {
        !writes.isEmpty
    }

    /// Creates an in-memory queue for previews and isolated tests.
    init() {
        storageURL = nil
    }

    /// Creates a queue backed by an atomically replaced JSON file.
    init(storageURL: URL) throws {
        self.storageURL = storageURL
        let directory = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        let data = try Data(contentsOf: storageURL)
        writes = try JSONDecoder().decode([QueuedWrite].self, from: data)
    }

    @discardableResult
    func enqueue(_ write: QueuedWrite) throws -> QueuedWrite {
        if let index = deduplicatedIndex(for: write) {
            return try mutate {
                writes[index].payloadSummary = write.payloadSummary
                if let lastError = write.lastError {
                    writes[index].lastError = lastError
                }
                if let syncUpdate = write.syncUpdate {
                    writes[index].syncUpdate = syncUpdate
                }
                return writes[index]
            }
        }

        return try mutate {
            writes.append(write)
            return write
        }
    }

    func markAttempted(id: UUID, error: String?) throws {
        guard let index = writes.firstIndex(where: { $0.id == id }) else { return }
        try mutate {
            writes[index].attemptCount += 1
            writes[index].lastError = error
        }
    }

    func markEventKitCompleted(id: UUID, syncUpdate: NativeCalendarSyncUpdateInput) throws {
        guard let index = writes.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError(message: "완료 상태를 저장할 캘린더 대기 작업을 찾을 수 없습니다.")
        }
        try mutate {
            let recordId = writes[index].recordId
            writes.removeAll {
                $0.id != id
                    && $0.kind == .calendar
                    && $0.recordId == recordId
                    && $0.operation == CalendarQueueOperation.metadataUpdate.rawValue
            }
            guard let updatedIndex = writes.firstIndex(where: { $0.id == id }) else { return }
            writes[updatedIndex].operation = CalendarQueueOperation.metadataUpdate.rawValue
            writes[updatedIndex].syncUpdate = syncUpdate
            writes[updatedIndex].lastError = nil
        }
    }

    @discardableResult
    func replaceWithCalendarOperation(id: UUID, operation: CalendarQueueOperation) throws -> QueuedWrite {
        guard let index = writes.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError(message: "전환할 캘린더 대기 작업을 찾을 수 없습니다.")
        }
        return try mutate {
            let recordId = writes[index].recordId
            writes[index].operation = operation.rawValue
            writes[index].syncUpdate = nil
            writes[index].lastError = nil
            let updated = writes[index]
            writes.removeAll {
                $0.id != id &&
                    $0.kind == .calendar &&
                    $0.recordId == recordId &&
                    $0.operation == operation.rawValue
            }
            return updated
        }
    }

    func remove(id: UUID) throws {
        guard writes.contains(where: { $0.id == id }) else { return }
        try mutate {
            writes.removeAll { $0.id == id }
        }
    }

    func removeAll() throws {
        guard !writes.isEmpty else { return }
        try mutate {
            writes.removeAll()
        }
    }

    func writes(for recordId: EntityID) -> [QueuedWrite] {
        writes.filter { $0.recordId == recordId }
    }

    private func deduplicatedIndex(for write: QueuedWrite) -> Int? {
        guard let recordId = write.recordId else { return nil }
        return writes.firstIndex {
            $0.kind == write.kind
                && $0.recordId == recordId
                && $0.operation == write.operation
        }
    }

    private func mutate<Result>(_ mutation: () -> Result) throws -> Result {
        let previous = writes
        let result = mutation()
        do {
            try persist()
            return result
        } catch {
            writes = previous
            throw error
        }
    }

    private func persist() throws {
        guard let storageURL else { return }
        let data = try JSONEncoder().encode(writes)
        try data.write(to: storageURL, options: .atomic)
    }
}
