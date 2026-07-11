import Foundation
import Observation
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "시스템"
        case .light: "라이트"
        case .dark: "다크"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@Observable
@MainActor
final class AppPreferences {
    static let lessonDurationOptions = [30, 45, 50, 60, 90]
    static let calendarReminderOptions: [Int?] = [nil, 10, 15, 30, 60]

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    var defaultLessonDurationMinutes: Int {
        didSet { defaults.set(defaultLessonDurationMinutes, forKey: Keys.defaultLessonDurationMinutes) }
    }
    var calendarReminderMinutes: Int? {
        didSet {
            if let calendarReminderMinutes {
                defaults.set(calendarReminderMinutes, forKey: Keys.calendarReminderMinutes)
            } else {
                defaults.removeObject(forKey: Keys.calendarReminderMinutes)
            }
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedAppearance = defaults.string(forKey: Keys.appearance)
            .flatMap(AppAppearance.init(rawValue:))
        appearance = storedAppearance ?? .system

        let storedDuration = defaults.integer(forKey: Keys.defaultLessonDurationMinutes)
        defaultLessonDurationMinutes = Self.lessonDurationOptions.contains(storedDuration) ? storedDuration : 50

        let storedReminder = defaults.object(forKey: Keys.calendarReminderMinutes) as? Int
        calendarReminderMinutes = Self.calendarReminderOptions.contains(storedReminder) ? storedReminder : nil
    }

    private enum Keys {
        static let appearance = "DrumLessonOS.appearance"
        static let defaultLessonDurationMinutes = "DrumLessonOS.defaultLessonDurationMinutes"
        static let calendarReminderMinutes = "DrumLessonOS.calendarReminderMinutes"
    }
}

@Observable
@MainActor
final class AppEnvironment {
    var route: AppRoute = .dashboard
    var dashboard: DashboardViewModel
    var syncStatus: SyncStatusViewModel
    var tuition: TuitionViewModel

    let students: StudentRepository
    let calendar: CalendarRepository
    let writes: StudentWriteRepository
    let lessonDrafts: LessonDraftRepository
    let schedules: ScheduleRepository
    let preferences: AppPreferences
    let localDataDirectoryURL: URL?
    let localDataBackup: LocalDataBackupRepository?
    let localDataReset: LocalDataResetRepository?

    init(
        dashboard: DashboardViewModel,
        syncStatus: SyncStatusViewModel,
        students: StudentRepository,
        calendar: CalendarRepository,
        writes: StudentWriteRepository,
        lessonDrafts: LessonDraftRepository,
        schedules: ScheduleRepository,
        tuitionRepository: TuitionRepository,
        preferences: AppPreferences = AppPreferences(),
        localDataDirectoryURL: URL? = nil,
        localDataBackup: LocalDataBackupRepository? = nil,
        localDataReset: LocalDataResetRepository? = nil
    ) {
        self.dashboard = dashboard
        self.syncStatus = syncStatus
        self.students = students
        self.calendar = calendar
        self.writes = writes
        self.lessonDrafts = lessonDrafts
        self.schedules = schedules
        tuition = TuitionViewModel(repository: tuitionRepository)
        self.preferences = preferences
        self.localDataDirectoryURL = localDataDirectoryURL
        self.localDataBackup = localDataBackup
        self.localDataReset = localDataReset
    }

    static func preview() -> AppEnvironment {
        let store = PreviewRepository()
        let calendar = PreviewCalendarRepository()
        let queue = LocalWriteQueue()
        let retry = RetryScheduler(writeQueue: queue)
        let schedules = CalendarBackedScheduleRepository(schedules: store, calendar: calendar, queue: queue)
        let sync = SyncStatusViewModel(queue: queue, retry: retry, schedules: schedules)

        return AppEnvironment(
            dashboard: DashboardViewModel(repository: store, scheduleRepository: schedules),
            syncStatus: sync,
            students: store,
            calendar: calendar,
            writes: store,
            lessonDrafts: store,
            schedules: schedules,
            tuitionRepository: store
        )
    }

    static func local(
        databaseURL: URL? = nil,
        calendar: CalendarRepository? = nil,
        preferences: AppPreferences = AppPreferences()
    ) throws -> AppEnvironment {
        let resolvedDatabaseURL = try databaseURL ?? LocalSQLiteRepository.defaultDatabaseURL()
        let store = try LocalSQLiteRepository(databaseURL: resolvedDatabaseURL)
        let queue = try LocalWriteQueue(storageURL: writeQueueURL(for: resolvedDatabaseURL))

        let calendar = calendar ?? EventKitCalendarRepository {
            preferences.calendarReminderMinutes
        }
        let retry = RetryScheduler(writeQueue: queue)
        let schedules = CalendarBackedScheduleRepository(schedules: store, calendar: calendar, queue: queue)
        let sync = SyncStatusViewModel(queue: queue, retry: retry, schedules: schedules)
        let backup = LocalDataBackupController(repository: store, writeQueue: queue)
        let reset = LocalDataResetController(store: store, calendar: calendar, writeQueue: queue)

        return AppEnvironment(
            dashboard: DashboardViewModel(repository: store, scheduleRepository: schedules),
            syncStatus: sync,
            students: store,
            calendar: calendar,
            writes: store,
            lessonDrafts: store,
            schedules: schedules,
            tuitionRepository: store,
            preferences: preferences,
            localDataDirectoryURL: resolvedDatabaseURL.deletingLastPathComponent(),
            localDataBackup: backup,
            localDataReset: reset
        )
    }

    static func liveOrPreview(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle? = .main,
        databaseURL: URL? = nil,
        calendar: CalendarRepository? = nil,
        preferences: AppPreferences = AppPreferences()
    ) throws -> AppEnvironment {
        _ = bundle
        let configuredDatabaseURL = databaseURL ?? environment[RuntimeEnvironment.databasePath]
            .map { URL(fileURLWithPath: $0) }
        let configuredCalendar = calendar ?? (
            environment[RuntimeEnvironment.previewCalendar] == "1"
                ? PreviewCalendarRepository()
                : nil
        )
        return try local(
            databaseURL: configuredDatabaseURL,
            calendar: configuredCalendar,
            preferences: preferences
        )
    }

    @MainActor
    func refresh() async {
        await syncStatus.retryNow()
        await dashboard.load()
        await tuition.load()
        syncStatus.refresh()
    }

    private static func writeQueueURL(for databaseURL: URL) -> URL {
        databaseURL.appendingPathExtension("calendar-write-queue.json")
    }

    enum RuntimeEnvironment {
        static let databasePath = "DRUM_LESSON_OS_DATABASE_PATH"
        static let previewCalendar = "DRUM_LESSON_OS_PREVIEW_CALENDAR"
    }
}
