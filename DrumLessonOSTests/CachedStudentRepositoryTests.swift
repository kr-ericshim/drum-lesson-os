import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func cachedStudentRepositoryFallsBackToLastDashboardWhenBaseFails() async throws {
    let base = FlakyStudentRepository()
    let repository = CachedStudentRepository(base: base, cache: LocalCacheStore())

    let loaded = try await repository.loadCalendarWorkbench(weekContaining: Date())
    base.shouldFail = true
    let cached = try await repository.loadCalendarWorkbench(weekContaining: Date())

    #expect(cached.weekTitle == loaded.weekTitle)
    #expect(cached.roster == loaded.roster)
}

@MainActor
@Test func cachedStudentRepositoryFallsBackToLastStudentDetailWhenBaseFails() async throws {
    let base = FlakyStudentRepository()
    let repository = CachedStudentRepository(base: base, cache: LocalCacheStore())

    let loaded = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)
    base.shouldFail = true
    let cached = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)

    #expect(cached.id == loaded.id)
    #expect(cached.name == loaded.name)
}

@MainActor
private final class FlakyStudentRepository: StudentRepository {
    var shouldFail = false
    private let preview = PreviewRepository()

    func loadCurrentInstructor() async throws -> Instructor {
        if shouldFail { throw RepositoryError(message: "Offline") }
        return try await preview.loadCurrentInstructor()
    }

    func loadRoster() async throws -> [StudentRosterItem] {
        if shouldFail { throw RepositoryError(message: "Offline") }
        return try await preview.loadRoster()
    }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        if shouldFail { throw RepositoryError(message: "Offline") }
        return try await preview.loadStudentDetail(studentId: studentId)
    }

    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench {
        if shouldFail { throw RepositoryError(message: "Offline") }
        return try await preview.loadCalendarWorkbench(weekContaining: date)
    }
}
