import Foundation
import Observation

@Observable
@MainActor
final class AppEnvironment {
    var route: AppRoute = .dashboard
    var auth: AuthViewModel
    var dashboard: DashboardViewModel
    var syncStatus: SyncStatusViewModel

    let students: StudentRepository
    let calendar: CalendarRepository
    let writes: StudentWriteRepository
    let schedules: ScheduleRepository

    init(
        auth: AuthViewModel,
        dashboard: DashboardViewModel,
        syncStatus: SyncStatusViewModel,
        students: StudentRepository,
        calendar: CalendarRepository,
        writes: StudentWriteRepository,
        schedules: ScheduleRepository
    ) {
        self.auth = auth
        self.dashboard = dashboard
        self.syncStatus = syncStatus
        self.students = students
        self.calendar = calendar
        self.writes = writes
        self.schedules = schedules
    }

    static func preview() -> AppEnvironment {
        let store = PreviewRepository()
        let calendar = PreviewCalendarRepository()
        let queue = LocalWriteQueue()
        let retry = RetryScheduler(writeQueue: queue)
        let schedules = CalendarBackedScheduleRepository(schedules: store, calendar: calendar, queue: queue)
        let sync = SyncStatusViewModel(queue: queue, retry: retry, schedules: schedules)

        return AppEnvironment(
            auth: AuthViewModel(repository: store),
            dashboard: DashboardViewModel(repository: store, scheduleRepository: schedules),
            syncStatus: sync,
            students: store,
            calendar: calendar,
            writes: store,
            schedules: schedules
        )
    }

    static func liveOrPreview(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle? = .main
    ) -> AppEnvironment {
        guard let supabase = try? SupabaseEnvironment.load(environment: environment, bundle: bundle) else {
            return preview()
        }

        let rest = SupabaseRESTClient(environment: supabase)
        let sessionStore = AuthSessionStore()
        let rpc = SupabaseRPCClient(rest: rest, sessionStore: sessionStore)
        let studentCache = LocalCacheStore()
        let students = CachedStudentRepository(
            base: SupabaseStudentRepository(rest: rest, sessionStore: sessionStore),
            cache: studentCache
        )
        let writes = SupabaseStudentWriteRepository(rpc: rpc)
        let schedules = SupabaseScheduleRepository(rpc: rpc, rest: rest, sessionStore: sessionStore)
        let calendar = EventKitCalendarRepository()
        let queue = LocalWriteQueue()
        let retry = RetryScheduler(writeQueue: queue)
        let calendarBackedSchedules = CalendarBackedScheduleRepository(schedules: schedules, calendar: calendar, queue: queue)
        let sync = SyncStatusViewModel(queue: queue, retry: retry, schedules: calendarBackedSchedules)

        return AppEnvironment(
            auth: AuthViewModel(repository: SupabaseAuthRepository(rest: rest, sessionStore: sessionStore)),
            dashboard: DashboardViewModel(repository: students, scheduleRepository: calendarBackedSchedules),
            syncStatus: sync,
            students: students,
            calendar: calendar,
            writes: writes,
            schedules: calendarBackedSchedules
        )
    }

    @MainActor
    func refresh() async {
        await dashboard.load()
        syncStatus.refresh()
    }
}
