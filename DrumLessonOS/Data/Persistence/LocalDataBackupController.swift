import Foundation
import Observation

struct AutomaticBackupStatus: Equatable {
    var lastBackupAt: Date?
    var backupCount: Int
    var lastError: String?
    var isStale: Bool

    static let unavailable = AutomaticBackupStatus(
        lastBackupAt: nil,
        backupCount: 0,
        lastError: nil,
        isStale: false
    )
}

@MainActor
@Observable
final class LocalDataBackupController: LocalDataBackupRepository {
    static let dailyRetentionCount = 7
    static let weeklyRetentionCount = 4

    private(set) var automaticBackupStatus = AutomaticBackupStatus.unavailable

    private let repository: LocalDataBackupRepository
    private let writeQueue: LocalWriteQueue
    private let automaticBackupDirectoryURL: URL?
    private let fileManager: FileManager

    init(
        repository: LocalDataBackupRepository,
        writeQueue: LocalWriteQueue,
        automaticBackupDirectoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.repository = repository
        self.writeQueue = writeQueue
        self.automaticBackupDirectoryURL = automaticBackupDirectoryURL
        self.fileManager = fileManager
    }

    func makeBackupData() async throws -> Data {
        try await repository.makeBackupData()
    }

    func restoreBackup(from data: Data) async throws -> URL {
        let safetyBackupURL = try await repository.restoreBackup(from: data)
        try writeQueue.removeAll()
        return safetyBackupURL
    }

    func runAutomaticBackupIfNeeded(now: Date = Date()) async {
        guard let automaticBackupDirectoryURL else { return }
        do {
            let existing = try automaticBackupRecords(in: automaticBackupDirectoryURL)
            if let latest = existing.first,
               Calendar.current.isDate(latest.date, inSameDayAs: now) {
                automaticBackupStatus = makeStatus(records: existing, now: now, error: nil)
                return
            }

            try fileManager.createDirectory(at: automaticBackupDirectoryURL, withIntermediateDirectories: true)
            let data = try await repository.makeBackupData()
            let url = automaticBackupDirectoryURL.appendingPathComponent(automaticBackupFilename(for: now))
            try data.write(to: url, options: .atomic)
            try fileManager.setAttributes([.modificationDate: now], ofItemAtPath: url.path)
            let retained = try pruneAutomaticBackups(in: automaticBackupDirectoryURL)
            automaticBackupStatus = makeStatus(records: retained, now: now, error: nil)
        } catch {
            let existing = (try? automaticBackupRecords(in: automaticBackupDirectoryURL)) ?? []
            automaticBackupStatus = makeStatus(
                records: existing,
                now: now,
                error: error.localizedDescription
            )
        }
    }

    func refreshAutomaticBackupStatus(now: Date = Date()) {
        guard let automaticBackupDirectoryURL else {
            automaticBackupStatus = .unavailable
            return
        }
        do {
            automaticBackupStatus = makeStatus(
                records: try automaticBackupRecords(in: automaticBackupDirectoryURL),
                now: now,
                error: automaticBackupStatus.lastError
            )
        } catch {
            automaticBackupStatus = makeStatus(
                records: [],
                now: now,
                error: error.localizedDescription
            )
        }
    }

    private func pruneAutomaticBackups(in directory: URL) throws -> [AutomaticBackupRecord] {
        let records = try automaticBackupRecords(in: directory)
        var retained: Set<URL> = []
        var dailyKeys: Set<String> = []
        var representedWeekKeys: Set<String> = []

        for record in records where dailyKeys.count < Self.dailyRetentionCount {
            let dayKey = Self.dayKey(for: record.date)
            guard dailyKeys.insert(dayKey).inserted else { continue }
            retained.insert(record.url)
            representedWeekKeys.insert(Self.weekKey(for: record.date))
        }

        var weeklyKeys: Set<String> = []
        for record in records where weeklyKeys.count < Self.weeklyRetentionCount {
            guard !retained.contains(record.url) else { continue }
            let weekKey = Self.weekKey(for: record.date)
            guard !representedWeekKeys.contains(weekKey), weeklyKeys.insert(weekKey).inserted else { continue }
            retained.insert(record.url)
        }

        for record in records where !retained.contains(record.url) {
            try fileManager.removeItem(at: record.url)
        }
        return try automaticBackupRecords(in: directory)
    }

    private func automaticBackupRecords(in directory: URL) throws -> [AutomaticBackupRecord] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        return try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "drumlessonbackup" && $0.lastPathComponent.hasPrefix("Automatic-") }
        .compactMap { url in
            guard let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                return nil
            }
            return AutomaticBackupRecord(url: url, date: date)
        }
        .sorted { $0.date > $1.date }
    }

    private func makeStatus(
        records: [AutomaticBackupRecord],
        now: Date,
        error: String?
    ) -> AutomaticBackupStatus {
        let lastBackupAt = records.first?.date
        return AutomaticBackupStatus(
            lastBackupAt: lastBackupAt,
            backupCount: records.count,
            lastError: error,
            isStale: lastBackupAt.map { now.timeIntervalSince($0) > 7 * 24 * 60 * 60 } ?? false
        )
    }

    private func automaticBackupFilename(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "Automatic-\(formatter.string(from: date))-\(UUID().uuidString.prefix(8)).drumlessonbackup"
    }

    private static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private static func weekKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
    }
}

private struct AutomaticBackupRecord {
    var url: URL
    var date: Date
}
