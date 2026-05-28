import Foundation
import Observation

enum QueuedWriteKind: String, Codable, Equatable, CaseIterable {
    case supabase
    case calendar
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

    init(kind: QueuedWriteKind, operation: String, recordId: EntityID? = nil, payloadSummary: String, lastError: String? = nil) {
        self.id = UUID()
        self.kind = kind
        self.operation = operation
        self.recordId = recordId
        self.payloadSummary = payloadSummary
        self.createdAt = Date()
        self.lastError = lastError
        self.attemptCount = 0
    }
}

@Observable
@MainActor
final class LocalWriteQueue {
    private(set) var writes: [QueuedWrite] = []

    var hasPendingWrites: Bool {
        !writes.isEmpty
    }

    func enqueue(_ write: QueuedWrite) {
        writes.append(write)
    }

    func markAttempted(id: UUID, error: String?) {
        guard let index = writes.firstIndex(where: { $0.id == id }) else { return }
        writes[index].attemptCount += 1
        writes[index].lastError = error
    }

    func remove(id: UUID) {
        writes.removeAll { $0.id == id }
    }
}
