import Foundation

@MainActor
final class CachedStudentRepository: StudentRepository {
    private let base: StudentRepository
    private let cache: LocalCacheStore

    init(base: StudentRepository, cache: LocalCacheStore) {
        self.base = base
        self.cache = cache
    }

    func loadCurrentInstructor() async throws -> Instructor {
        do {
            let instructor = try await base.loadCurrentInstructor()
            cache.cacheInstructor(instructor)
            return instructor
        } catch {
            if let cached = cache.cachedInstructor() {
                return cached
            }
            throw error
        }
    }

    func loadRoster() async throws -> [StudentRosterItem] {
        do {
            let roster = try await base.loadRoster()
            cache.cacheRoster(roster)
            return roster
        } catch {
            if let cached = cache.cachedRoster() {
                return cached
            }
            throw error
        }
    }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        do {
            let detail = try await base.loadStudentDetail(studentId: studentId)
            cache.cacheStudentDetail(detail)
            return detail
        } catch {
            if let cached = cache.cachedStudentDetail(id: studentId) {
                return cached
            }
            throw error
        }
    }

    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench {
        do {
            let dashboard = try await base.loadCalendarWorkbench(weekContaining: date)
            cache.cacheDashboard(dashboard)
            cache.cacheRoster(dashboard.roster)
            return dashboard
        } catch {
            if let cached = cache.cachedDashboard() {
                return cached
            }
            throw error
        }
    }
}
