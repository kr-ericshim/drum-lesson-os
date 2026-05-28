import Foundation

@MainActor
final class LocalCacheStore {
    private var instructor: Instructor?
    private var roster: [StudentRosterItem]?
    private var dashboard: CalendarWorkbench?
    private var details: [EntityID: StudentDetail] = [:]

    func cacheInstructor(_ instructor: Instructor) {
        self.instructor = instructor
    }

    func cachedInstructor() -> Instructor? {
        instructor
    }

    func cacheRoster(_ roster: [StudentRosterItem]) {
        self.roster = roster
    }

    func cachedRoster() -> [StudentRosterItem]? {
        roster
    }

    func cacheDashboard(_ model: CalendarWorkbench) {
        dashboard = model
    }

    func cachedDashboard() -> CalendarWorkbench? {
        dashboard
    }

    func cacheStudentDetail(_ detail: StudentDetail) {
        details[detail.id] = detail
    }

    func cachedStudentDetail(id: EntityID) -> StudentDetail? {
        details[id]
    }
}
