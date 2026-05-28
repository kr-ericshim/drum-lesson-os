import Foundation

@MainActor
final class SupabaseStudentRepository: StudentRepository {
    private let rest: SupabaseRESTClient
    private let sessionStore: SupabaseSessionStoring
    private let timeZone: TimeZone

    init(
        rest: SupabaseRESTClient,
        sessionStore: SupabaseSessionStoring = AuthSessionStore(),
        timeZone: TimeZone = .current
    ) {
        self.rest = rest
        self.sessionStore = sessionStore
        self.timeZone = timeZone
    }

    func loadCurrentInstructor() async throws -> Instructor {
        let instructors: [Instructor] = try await select(
            table: "instructors",
            queryItems: [URLQueryItem(name: "limit", value: "1")]
        )
        guard let instructor = instructors.first else {
            throw RepositoryError(message: "Instructor profile was not found for this Supabase account.")
        }
        return instructor
    }

    func loadRoster() async throws -> [StudentRosterItem] {
        let snapshot = try await loadSnapshot()
        return StudentRosterMapper.map(
            students: snapshot.students,
            progressItems: snapshot.progressItems,
            assignments: snapshot.assignments,
            nextPlans: snapshot.nextPlans,
            notes: snapshot.notes,
            todayDate: DateOnly.today(in: timeZone)
        )
    }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        let students: [Student] = try await select(
            table: "students",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(studentId.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        guard let student = students.first else {
            throw RepositoryError.notFound
        }

        let progressItems: [ProgressItem] = try await select(table: "progress_items", studentFilter: studentId)
        let traits: [StudentTrait] = try await select(table: "student_traits", studentFilter: studentId)
        let assignments: [Assignment] = try await select(table: "assignments", studentFilter: studentId)
        let notes: [LessonNote] = try await select(table: "lesson_notes", studentFilter: studentId)
        let nextPlans: [NextLessonPlan] = try await select(table: "next_lesson_plans", studentFilter: studentId)

        return StudentDetailMapper.map(
            student: student,
            progressItems: progressItems,
            traits: traits,
            assignments: assignments,
            notes: notes,
            nextPlans: nextPlans,
            todayDate: DateOnly.today(in: timeZone)
        )
    }

    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench {
        let roster = try await loadRoster()
        let calendar = Calendar.iso8601SeoulCompatible
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? date
        let formatter = ISO8601DateFormatter.plain
        let occurrences: [LessonOccurrence] = try await select(
            table: "lesson_occurrences",
            queryItems: [
                URLQueryItem(name: "starts_at", value: "gte.\(formatter.string(from: weekStart))"),
                URLQueryItem(name: "starts_at", value: "lt.\(formatter.string(from: weekEnd))"),
                URLQueryItem(name: "order", value: "starts_at.asc")
            ]
        )

        return CalendarWorkbenchMapper.map(
            occurrences: occurrences,
            students: roster,
            weekContaining: date,
            timezone: timeZone.identifier
        )
    }

    private func loadSnapshot() async throws -> SupabaseRosterSnapshot {
        SupabaseRosterSnapshot(
            students: try await select(table: "students", queryItems: [URLQueryItem(name: "order", value: "name.asc")]),
            progressItems: try await select(table: "progress_items", queryItems: [URLQueryItem(name: "order", value: "observed_on.desc")]),
            assignments: try await select(table: "assignments", queryItems: [URLQueryItem(name: "order", value: "updated_at.desc")]),
            nextPlans: try await select(table: "next_lesson_plans", queryItems: [URLQueryItem(name: "order", value: "updated_at.desc")]),
            notes: try await select(table: "lesson_notes", queryItems: [URLQueryItem(name: "order", value: "lesson_date.desc")])
        )
    }

    private func select<T: Decodable>(table: String, studentFilter studentId: EntityID) async throws -> [T] {
        try await select(
            table: table,
            queryItems: [URLQueryItem(name: "student_id", value: "eq.\(studentId.uuidString.lowercased())")]
        )
    }

    private func select<T: Decodable>(table: String, queryItems: [URLQueryItem]) async throws -> [T] {
        guard let session = try sessionStore.loadSession() else {
            throw RepositoryError.signedOut
        }
        return try await rest.select([T].self, table: table, queryItems: queryItems, accessToken: session.accessToken)
    }
}

private struct SupabaseRosterSnapshot {
    var students: [Student]
    var progressItems: [ProgressItem]
    var assignments: [Assignment]
    var nextPlans: [NextLessonPlan]
    var notes: [LessonNote]
}
