import Foundation

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
    func createProgressCheckpoint(_ input: ProgressCheckpointInput) async throws -> EntityID
    func updateProgressStatus(_ input: ProgressStatusTransitionInput) async throws
    func upsertAssignment(_ input: AssignmentInput) async throws -> EntityID
    func createLessonNote(_ input: LessonNoteInput) async throws -> EntityID
    func upsertNextPlan(_ input: NextPlanInput) async throws -> EntityID
    func closeoutLesson(_ input: LessonCloseoutInput) async throws
}

@MainActor
protocol LocalDataBackupRepository {
    func makeBackupData() async throws -> Data
    func restoreBackup(from data: Data) async throws -> URL
}

@MainActor
protocol ScheduleRepository {
    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence
    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence]
    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence
    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence
    func retryNativeCalendarSync(occurrenceId: EntityID) async throws
    func loadPendingNativeCalendarOccurrences() async throws -> [LessonOccurrence]
    func reconcilePendingNativeCalendarSync() async throws -> Int
    func loadOccurrence(id: EntityID) async throws -> LessonOccurrence
    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws
}

extension ScheduleRepository {
    func loadPendingNativeCalendarOccurrences() async throws -> [LessonOccurrence] { [] }
    func reconcilePendingNativeCalendarSync() async throws -> Int { 0 }
}

@MainActor
protocol CalendarRepository {
    func permissionStatus() -> EventKitPermissionState
    func requestPermission() async throws -> EventKitPermissionState
    func listWritableCalendars() async throws -> [WritableCalendar]
    func selectCalendar(_ calendar: WritableCalendar) async throws
    func selectedCalendar() -> WritableCalendar?
    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult
    func recoverOrCreateLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult
    func updateLessonEvent(_ event: LessonCalendarEventDraft, existingIdentity: CalendarEventIdentity) async throws -> CalendarWriteResult
    func deleteLessonEvent(_ event: LessonCalendarEventDraft, existingIdentity: CalendarEventIdentity) async throws
}

extension CalendarRepository {
    func recoverOrCreateLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        try await createLessonEvent(event)
    }
}

struct RepositoryError: LocalizedError, Equatable {
    var message: String

    var errorDescription: String? { message }

    static let notFound = RepositoryError(message: "요청한 기록을 찾을 수 없습니다.")
}

struct CalendarEventIdentity: Codable, Equatable {
    var eventIdentifier: String?
    var calendarIdentifier: String?
    var externalIdentifier: String?
}

struct NativeCalendarSyncUpdateInput: Codable, Equatable {
    var occurrenceId: EntityID
    var status: NativeCalendarSyncStatus
    var eventIdentifier: String?
    var calendarIdentifier: String?
    var externalIdentifier: String?
    var error: String?
    var syncedAt: String?
}
