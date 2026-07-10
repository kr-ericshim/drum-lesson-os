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

    let students: StudentRepository
    let calendar: CalendarRepository
    let writes: StudentWriteRepository
    let schedules: ScheduleRepository
    let preferences: AppPreferences
    let localDataDirectoryURL: URL?

    init(
        dashboard: DashboardViewModel,
        syncStatus: SyncStatusViewModel,
        students: StudentRepository,
        calendar: CalendarRepository,
        writes: StudentWriteRepository,
        schedules: ScheduleRepository,
        preferences: AppPreferences = AppPreferences(),
        localDataDirectoryURL: URL? = nil
    ) {
        self.dashboard = dashboard
        self.syncStatus = syncStatus
        self.students = students
        self.calendar = calendar
        self.writes = writes
        self.schedules = schedules
        self.preferences = preferences
        self.localDataDirectoryURL = localDataDirectoryURL
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
            schedules: schedules
        )
    }

    static func local(
        databaseURL: URL? = nil,
        calendar: CalendarRepository? = nil,
        preferences: AppPreferences = AppPreferences()
    ) -> AppEnvironment {
        let store: LocalSQLiteRepository
        let queue: LocalWriteQueue
        let resolvedDatabaseURL: URL
        do {
            resolvedDatabaseURL = try databaseURL ?? LocalSQLiteRepository.defaultDatabaseURL()
            store = try LocalSQLiteRepository(databaseURL: resolvedDatabaseURL)
            queue = try LocalWriteQueue(storageURL: writeQueueURL(for: resolvedDatabaseURL))
        } catch {
            preconditionFailure("Local store failed: \(error.localizedDescription)")
        }

        let calendar = calendar ?? EventKitCalendarRepository {
            preferences.calendarReminderMinutes
        }
        let retry = RetryScheduler(writeQueue: queue)
        let schedules = CalendarBackedScheduleRepository(schedules: store, calendar: calendar, queue: queue)
        let sync = SyncStatusViewModel(queue: queue, retry: retry, schedules: schedules)

        return AppEnvironment(
            dashboard: DashboardViewModel(repository: store, scheduleRepository: schedules),
            syncStatus: sync,
            students: store,
            calendar: calendar,
            writes: store,
            schedules: schedules,
            preferences: preferences,
            localDataDirectoryURL: resolvedDatabaseURL.deletingLastPathComponent()
        )
    }

    static func liveOrPreview(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle? = .main,
        databaseURL: URL? = nil,
        calendar: CalendarRepository? = nil,
        preferences: AppPreferences = AppPreferences()
    ) -> AppEnvironment {
        _ = environment
        _ = bundle
        return local(databaseURL: databaseURL, calendar: calendar, preferences: preferences)
    }

    @MainActor
    func refresh() async {
        await syncStatus.retryNow()
        await dashboard.load()
        syncStatus.refresh()
    }

    private static func writeQueueURL(for databaseURL: URL) -> URL {
        databaseURL.appendingPathExtension("calendar-write-queue.json")
    }
}
