import Foundation

@MainActor
protocol AuthRepository {
    func restoreSession() async throws -> Instructor?
    func signIn(email: String, password: String) async throws -> Instructor
    func signOut() async throws
    func openPasswordRecovery(email: String) async throws
}

@MainActor
protocol StudentRepository {
    func loadCurrentInstructor() async throws -> Instructor
    func loadRoster() async throws -> [StudentRosterItem]
    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail
    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench
}

@MainActor
protocol StudentWriteRepository {
    func createStudent(_ input: StudentProfileInput) async throws -> EntityID
    func updateStudentProfile(_ input: StudentProfileInput) async throws
    func upsertTrait(_ input: StudentTraitInput) async throws -> EntityID
    func upsertProgressItem(_ input: ProgressItemInput) async throws -> EntityID
    func updateProgressStatus(_ input: ProgressStatusTransitionInput) async throws
    func upsertAssignment(_ input: AssignmentInput) async throws -> EntityID
    func createLessonNote(_ input: LessonNoteInput) async throws -> EntityID
    func upsertNextPlan(_ input: NextPlanInput) async throws -> EntityID
    func closeoutLesson(_ input: LessonCloseoutInput) async throws
}

@MainActor
protocol ScheduleRepository {
    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence
    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence]
    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence
    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence
    func retryNativeCalendarSync(occurrenceId: EntityID) async throws
    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws
}

@MainActor
protocol CalendarRepository {
    func permissionStatus() -> EventKitPermissionState
    func requestPermission() async throws -> EventKitPermissionState
    func listWritableCalendars() async throws -> [WritableCalendar]
    func selectCalendar(_ calendar: WritableCalendar) async throws
    func selectedCalendar() -> WritableCalendar?
    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult
    func updateLessonEvent(_ event: LessonCalendarEventDraft, existingEventIdentifier: String?) async throws -> CalendarWriteResult
    func deleteLessonEvent(eventIdentifier: String) async throws
}

struct RepositoryError: LocalizedError, Equatable {
    var message: String

    var errorDescription: String? { message }

    static let signedOut = RepositoryError(message: "Sign in is required.")
    static let notFound = RepositoryError(message: "The requested record was not found.")
}

struct NativeCalendarSyncUpdateInput: Equatable {
    var occurrenceId: EntityID
    var status: NativeCalendarSyncStatus
    var eventIdentifier: String?
    var calendarIdentifier: String?
    var externalIdentifier: String?
    var error: String?
    var syncedAt: String?
}
