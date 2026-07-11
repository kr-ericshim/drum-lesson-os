import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func automaticBackupRunsAtMostOncePerCalendarDay() async throws {
    let directory = temporaryAutomaticBackupDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let repository = AutomaticBackupRepositorySpy()
    let controller = LocalDataBackupController(
        repository: repository,
        writeQueue: LocalWriteQueue(),
        automaticBackupDirectoryURL: directory
    )
    let morning = try testDate("2026-07-11T01:00:00Z")
    let evening = try testDate("2026-07-11T12:00:00Z")

    await controller.runAutomaticBackupIfNeeded(now: morning)
    await controller.runAutomaticBackupIfNeeded(now: evening)

    #expect(repository.makeBackupCallCount == 1)
    #expect(controller.automaticBackupStatus.backupCount == 1)
    #expect(controller.automaticBackupStatus.lastError == nil)
}

@MainActor
@Test func automaticBackupRetainsSevenDailyAndFourOlderWeeklySnapshots() async throws {
    let directory = temporaryAutomaticBackupDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let repository = AutomaticBackupRepositorySpy()
    let controller = LocalDataBackupController(
        repository: repository,
        writeQueue: LocalWriteQueue(),
        automaticBackupDirectoryURL: directory
    )
    let start = try testDate("2026-05-01T03:00:00Z")

    for dayOffset in 0..<60 {
        let date = try #require(Calendar.current.date(byAdding: .day, value: dayOffset, to: start))
        await controller.runAutomaticBackupIfNeeded(now: date)
    }

    let files = try automaticBackupFiles(in: directory)
    #expect(files.count == LocalDataBackupController.dailyRetentionCount + LocalDataBackupController.weeklyRetentionCount)
    #expect(controller.automaticBackupStatus.backupCount == files.count)
}

@MainActor
@Test func automaticBackupStatusWarnsAfterSevenDaysWithoutSuccess() async throws {
    let directory = temporaryAutomaticBackupDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let repository = AutomaticBackupRepositorySpy()
    let controller = LocalDataBackupController(
        repository: repository,
        writeQueue: LocalWriteQueue(),
        automaticBackupDirectoryURL: directory
    )
    let savedAt = try testDate("2026-07-01T03:00:00Z")
    let checkedAt = try testDate("2026-07-09T03:00:01Z")
    await controller.runAutomaticBackupIfNeeded(now: savedAt)

    controller.refreshAutomaticBackupStatus(now: checkedAt)

    #expect(controller.automaticBackupStatus.isStale)
    #expect(controller.automaticBackupStatus.lastBackupAt == savedAt)
}

@MainActor
private final class AutomaticBackupRepositorySpy: LocalDataBackupRepository {
    var makeBackupCallCount = 0

    func makeBackupData() async throws -> Data {
        makeBackupCallCount += 1
        return Data("backup-\(makeBackupCallCount)".utf8)
    }

    func restoreBackup(from data: Data) async throws -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("unused.backup")
    }
}

private func temporaryAutomaticBackupDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-AutomaticBackup-\(UUID().uuidString)", isDirectory: true)
}

private func automaticBackupFiles(in directory: URL) throws -> [URL] {
    try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "drumlessonbackup" }
}

private func testDate(_ value: String) throws -> Date {
    try #require(ISO8601DateFormatter.plain.date(from: value))
}
