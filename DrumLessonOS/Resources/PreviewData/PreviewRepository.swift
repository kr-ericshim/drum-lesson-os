import Foundation

final class PreviewRepository: AuthRepository, StudentRepository, StudentWriteRepository, ScheduleRepository {
    private var instructor = PreviewData.instructor
    private var students = PreviewData.students
    private var progressItems = PreviewData.progressItems
    private var traits = PreviewData.traits
    private var assignments = PreviewData.assignments
    private var notes = PreviewData.notes
    private var plans = PreviewData.nextPlans
    private var occurrences = PreviewData.occurrences

    func restoreSession() async throws -> Instructor? {
        instructor
    }

    func signIn(email: String, password: String) async throws -> Instructor {
        guard email.contains("@"), !password.isEmpty else {
            throw RepositoryError(message: "Email and password are required.")
        }
        return instructor
    }

    func signOut() async throws {}

    func openPasswordRecovery(email: String) async throws {}

    func loadCurrentInstructor() async throws -> Instructor {
        instructor
    }

    func loadRoster() async throws -> [StudentRosterItem] {
        StudentRosterMapper.map(
            students: students,
            progressItems: progressItems,
            assignments: assignments,
            nextPlans: plans,
            notes: notes,
            todayDate: DateOnly.today(in: .current)
        )
    }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        guard let student = students.first(where: { $0.id == studentId }) else {
            throw RepositoryError.notFound
        }

        return StudentDetailMapper.map(
            student: student,
            progressItems: progressItems.filter { $0.studentId == studentId },
            traits: traits.filter { $0.studentId == studentId },
            assignments: assignments.filter { $0.studentId == studentId },
            notes: notes.filter { $0.studentId == studentId },
            nextPlans: plans.filter { $0.studentId == studentId },
            todayDate: DateOnly.today(in: .current)
        )
    }

    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench {
        let roster = try await loadRoster()
        return CalendarWorkbenchMapper.map(
            occurrences: occurrences,
            students: roster,
            weekContaining: date,
            timezone: TimeZone.current.identifier
        )
    }

    func createStudent(_ input: StudentProfileInput) async throws -> EntityID {
        let id = UUID()
        students.append(Student(
            id: id,
            instructorId: instructor.id,
            name: input.name,
            profileCue: input.profileCue,
            primaryWeakPoint: input.primaryWeakPoint,
            active: input.active,
            createdAt: nil,
            updatedAt: nil
        ))
        return id
    }

    func updateStudentProfile(_ input: StudentProfileInput) async throws {
        guard let id = input.studentId, let index = students.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        students[index].name = input.name
        students[index].profileCue = input.profileCue
        students[index].primaryWeakPoint = input.primaryWeakPoint
        students[index].active = input.active
    }

    func upsertTrait(_ input: StudentTraitInput) async throws -> EntityID {
        let id = input.traitId ?? UUID()
        traits.removeAll { $0.id == id }
        traits.append(StudentTrait(
            id: id,
            instructorId: instructor.id,
            studentId: input.studentId,
            type: input.type,
            label: input.label,
            detail: input.detail
        ))
        return id
    }

    func upsertProgressItem(_ input: ProgressItemInput) async throws -> EntityID {
        let id = input.progressItemId ?? UUID()
        if input.currentFocus {
            for index in progressItems.indices where progressItems[index].studentId == input.studentId {
                progressItems[index].currentFocus = false
            }
        }
        progressItems.removeAll { $0.id == id }
        progressItems.append(ProgressItem(
            id: id,
            instructorId: instructor.id,
            studentId: input.studentId,
            category: input.category,
            status: input.status,
            title: input.title,
            currentFocus: input.currentFocus,
            observedOn: input.observedOn,
            detail: input.detail,
            tempoNote: input.tempoNote,
            updatedAt: nil
        ))
        return id
    }

    func updateProgressStatus(_ input: ProgressStatusTransitionInput) async throws {
        guard let index = progressItems.firstIndex(where: { $0.id == input.progressItemId }) else {
            throw RepositoryError.notFound
        }
        progressItems[index].status = input.nextStatus
    }

    func upsertAssignment(_ input: AssignmentInput) async throws -> EntityID {
        let id = input.assignmentId ?? UUID()
        assignments.removeAll { $0.id == id }
        assignments.append(Assignment(
            id: id,
            instructorId: instructor.id,
            studentId: input.studentId,
            title: input.title,
            status: input.status,
            dueDate: input.dueDate,
            detail: input.detail,
            updatedAt: nil
        ))
        return id
    }

    func createLessonNote(_ input: LessonNoteInput) async throws -> EntityID {
        let id = UUID()
        notes.append(LessonNote(
            id: id,
            instructorId: instructor.id,
            studentId: input.studentId,
            lessonDate: input.lessonDate,
            coveredMaterial: input.coveredMaterial,
            observations: input.observations,
            practiceAssigned: input.practiceAssigned,
            nextStepHint: input.nextStepHint,
            createdAt: nil
        ))
        return id
    }

    func upsertNextPlan(_ input: NextPlanInput) async throws -> EntityID {
        let id = input.planId ?? UUID()
        plans.removeAll { $0.id == id }
        plans.append(NextLessonPlan(
            id: id,
            instructorId: instructor.id,
            studentId: input.studentId,
            plannedFor: input.plannedFor,
            priority: input.priority,
            nextAction: input.nextAction,
            detail: input.detail,
            createdAt: nil,
            updatedAt: nil
        ))
        return id
    }

    func closeoutLesson(_ input: LessonCloseoutInput) async throws {
        _ = try await createLessonNote(LessonNoteInput(
            studentId: input.studentId,
            lessonDate: input.lessonDate,
            coveredMaterial: input.coveredMaterial,
            observations: input.observations,
            practiceAssigned: input.practiceAssigned,
            nextStepHint: input.nextStepHint
        ))
    }

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        let occurrence = input.makeOccurrence(instructorId: instructor.id)
        occurrences.append(occurrence)
        return occurrence
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        let expanded = WeeklyOccurrenceExpander.expand(
            template: input.template(instructorId: instructor.id),
            horizonStartDate: input.startsOn,
            existingDateKeys: []
        )
        occurrences.append(contentsOf: expanded)
        return expanded
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        guard let index = occurrences.firstIndex(where: { $0.id == input.occurrenceId }) else {
            throw RepositoryError.notFound
        }
        occurrences[index].startsAt = input.startsAt
        occurrences[index].endsAt = input.endsAt
        occurrences[index].nativeCalendarSyncStatus = .pending
        return occurrences[index]
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        guard let index = occurrences.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        occurrences[index].status = .canceled
        occurrences[index].nativeCalendarSyncStatus = .pending
        return occurrences[index]
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {}

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        guard let index = occurrences.firstIndex(where: { $0.id == input.occurrenceId }) else {
            throw RepositoryError.notFound
        }
        occurrences[index].nativeCalendarEventIdentifier = input.eventIdentifier
        occurrences[index].nativeCalendarIdentifier = input.calendarIdentifier
        occurrences[index].nativeCalendarExternalIdentifier = input.externalIdentifier
        occurrences[index].nativeCalendarSyncStatus = input.status
        occurrences[index].nativeCalendarSyncError = input.error
        occurrences[index].nativeCalendarSyncedAt = input.syncedAt
    }
}

enum PreviewData {
    static let instructorId = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    static let minjiId = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    static let joonId = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!

    static let instructor = Instructor(
        id: instructorId,
        displayName: "Eric Shim",
        studioName: "Drum Lesson OS",
        authUserId: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")
    )

    static let students = [
        Student(id: minjiId, instructorId: instructorId, name: "김민지", profileCue: "말보다 먼저 리듬으로 확인하면 빨리 열린다.", primaryWeakPoint: "필인 뒤 1박 착지", active: true, createdAt: nil, updatedAt: nil),
        Student(id: joonId, instructorId: instructorId, name: "박준", profileCue: "큰 그림을 먼저 말해주면 집중이 오래간다.", primaryWeakPoint: "왼손 고스트 노트 균일성", active: true, createdAt: nil, updatedAt: nil)
    ]

    static let progressItems = [
        ProgressItem(id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!, instructorId: instructorId, studentId: minjiId, category: .song, status: .inProgress, title: "좋은 밤 좋은 꿈 8비트", currentFocus: true, observedOn: "2026-05-28", detail: "코러스 전 필인에서 오른발이 앞선다.", tempoNote: "82 -> 88 BPM", updatedAt: "2026-05-28T08:00:00Z"),
        ProgressItem(id: UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!, instructorId: instructorId, studentId: joonId, category: .rudiment, status: .needsReview, title: "Paradiddle accent", currentFocus: true, observedOn: "2026-05-27", detail: "왼손 악센트가 작아진다.", tempoNote: "70 BPM", updatedAt: "2026-05-27T08:00:00Z")
    ]

    static let traits = [
        StudentTrait(id: UUID(), instructorId: instructorId, studentId: minjiId, type: .strength, label: "청음 빠름", detail: "멜로디를 듣고 구조를 잘 기억한다."),
        StudentTrait(id: UUID(), instructorId: instructorId, studentId: minjiId, type: .practiceHabit, label: "짧게 자주", detail: "10분 루틴을 지키면 안정적이다.")
    ]

    static let assignments = [
        Assignment(id: UUID(), instructorId: instructorId, studentId: minjiId, title: "코러스 전 2마디 반복", status: .needsReview, dueDate: "2026-05-29", detail: "메트로놈 84 BPM으로 5회.")
    ]

    static let notes = [
        LessonNote(id: UUID(), instructorId: instructorId, studentId: minjiId, lessonDate: "2026-05-27", coveredMaterial: "8비트 그루브와 코러스 전 필인", observations: "필인에서 어깨 긴장이 올라간다.", practiceAssigned: "2마디 루프를 천천히 반복", nextStepHint: "필인 뒤 1박 착지를 먼저 확인", createdAt: "2026-05-27T08:00:00Z")
    ]

    static let nextPlans = [
        NextLessonPlan(id: UUID(), instructorId: instructorId, studentId: minjiId, plannedFor: "2026-05-29", priority: .high, nextAction: "필인 뒤 1박 착지부터 확인", detail: "곡 전체보다 코러스 직전 2마디에 집중.", createdAt: nil, updatedAt: "2026-05-28T07:00:00Z")
    ]

    static let occurrences = [
        LessonOccurrence(id: UUID(), instructorId: instructorId, studentId: minjiId, scheduleTemplateId: nil, startsAt: "2026-05-28T10:00:00Z", endsAt: "2026-05-28T10:50:00Z", timezone: TimeZone.current.identifier, status: .scheduled, title: "김민지 drum lesson", nativeCalendarEventIdentifier: nil, nativeCalendarIdentifier: nil, nativeCalendarExternalIdentifier: nil, nativeCalendarSyncStatus: .pending, nativeCalendarSyncError: nil, nativeCalendarSyncedAt: nil),
        LessonOccurrence(id: UUID(), instructorId: instructorId, studentId: joonId, scheduleTemplateId: nil, startsAt: "2026-05-28T12:00:00Z", endsAt: "2026-05-28T12:50:00Z", timezone: TimeZone.current.identifier, status: .scheduled, title: "박준 drum lesson", nativeCalendarEventIdentifier: nil, nativeCalendarIdentifier: nil, nativeCalendarExternalIdentifier: nil, nativeCalendarSyncStatus: .notConnected, nativeCalendarSyncError: nil, nativeCalendarSyncedAt: nil)
    ]
}
