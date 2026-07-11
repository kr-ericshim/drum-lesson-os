import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func appEnvironmentUsesLocalSQLiteByDefault() throws {
    let databaseURL = temporarySQLiteURL()
    defer { try? FileManager.default.removeItem(at: databaseURL.deletingLastPathComponent()) }
    let environment = try AppEnvironment.liveOrPreview(
        environment: [:],
        bundle: nil,
        databaseURL: databaseURL,
        calendar: PreviewCalendarRepository()
    )

    #expect(environment.students is LocalSQLiteRepository)
    #expect(environment.writes is LocalSQLiteRepository)
    #expect(environment.schedules is CalendarBackedScheduleRepository)
    #expect(environment.localDataDirectoryURL == databaseURL.deletingLastPathComponent())
}

@MainActor
@Test func appEnvironmentUsesIsolatedRuntimeConfiguration() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-SafeRuntime-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let databaseURL = directory.appendingPathComponent("safe.sqlite")

    let environment = try AppEnvironment.liveOrPreview(environment: [
        AppEnvironment.RuntimeEnvironment.databasePath: databaseURL.path,
        AppEnvironment.RuntimeEnvironment.previewCalendar: "1"
    ])

    #expect(environment.localDataDirectoryURL == directory)
    #expect(environment.calendar is PreviewCalendarRepository)
}

@MainActor
@Test func appEnvironmentReportsLocalStoreStartupFailure() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-InvalidStore-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    #expect(throws: Error.self) {
        _ = try AppEnvironment.liveOrPreview(databaseURL: directory)
    }

    let startup = AppStartupState.load(environment: [
        AppEnvironment.RuntimeEnvironment.databasePath: directory.path,
        AppEnvironment.RuntimeEnvironment.previewCalendar: "1"
    ], bundle: nil)
    guard case .failed(let failure) = startup else {
        Issue.record("시작 실패가 복구 화면 상태로 변환되어야 합니다.")
        return
    }
    #expect(!failure.message.isEmpty)
}

@MainActor
@Test func appPreferencesPersistUserChoices() throws {
    let suiteName = "DrumLessonOS-Preferences-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let preferences = AppPreferences(defaults: defaults)
    #expect(preferences.appearance == .system)
    #expect(preferences.defaultLessonDurationMinutes == 50)
    #expect(preferences.calendarReminderMinutes == nil)

    preferences.appearance = .dark
    preferences.defaultLessonDurationMinutes = 60
    preferences.calendarReminderMinutes = 15

    let restored = AppPreferences(defaults: defaults)
    #expect(restored.appearance == .dark)
    #expect(restored.defaultLessonDurationMinutes == 60)
    #expect(restored.calendarReminderMinutes == 15)
}

@MainActor
@Test func appEnvironmentRefreshRetriesRestoredCalendarQueue() async throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-Startup-\(UUID().uuidString)", isDirectory: true)
    let queueURL = directory.appendingPathComponent("writes.json")
    defer { try? FileManager.default.removeItem(at: directory) }

    let occurrenceId = PreviewData.occurrences[0].id
    let persistedQueue = try LocalWriteQueue(storageURL: queueURL)
    try persistedQueue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.create.rawValue,
        recordId: occurrenceId,
        payloadSummary: "김민지 드럼 레슨"
    ))

    let restoredQueue = try LocalWriteQueue(storageURL: queueURL)
    let store = PreviewRepository()
    let calendar = PreviewCalendarRepository()
    let schedules = CalendarBackedScheduleRepository(
        schedules: store,
        calendar: calendar,
        queue: restoredQueue
    )
    let environment = AppEnvironment(
        dashboard: DashboardViewModel(repository: store, scheduleRepository: schedules),
        syncStatus: SyncStatusViewModel(
            queue: restoredQueue,
            retry: RetryScheduler(writeQueue: restoredQueue),
            schedules: schedules
        ),
        students: store,
        calendar: calendar,
        writes: store,
        schedules: schedules,
        tuitionRepository: store
    )

    await environment.refresh()

    #expect(restoredQueue.writes.isEmpty)
    #expect(try await store.loadOccurrence(id: occurrenceId).nativeCalendarSyncStatus == .synced)
}

private func temporarySQLiteURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-\(UUID().uuidString)", isDirectory: true)
        .appendingPathComponent("DrumLessonOS.sqlite")
}
