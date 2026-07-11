import Foundation

final class PreviewRepository: StudentRepository, StudentWriteRepository, ScheduleRepository, TuitionRepository, LessonDraftRepository {
    private var instructor = PreviewData.instructor
    private var students = PreviewData.students
    private var progressItems = PreviewData.progressItems
    private var progressCheckpoints = PreviewData.progressCheckpoints
    private var traits = PreviewData.traits
    private var assignments = PreviewData.assignments
    private var notes = PreviewData.notes
    private var plans = PreviewData.nextPlans
    private var occurrences = PreviewData.occurrences
    private var tuitionCycles = PreviewData.tuitionCycles
    private var lessonDrafts: [LessonDraft] = []

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

    func loadTuitionRoster() async throws -> [TuitionRosterItem] {
        students
            .filter(\.active)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { student in
                TuitionRosterItem(
                    studentId: student.id,
                    studentName: student.name,
                    cycles: tuitionCycles.filter { $0.studentId == student.id }
                )
            }
    }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        guard let student = students.first(where: { $0.id == studentId }) else {
            throw RepositoryError.notFound
        }

        return StudentDetailMapper.map(
            student: student,
            progressItems: progressItems.filter { $0.studentId == studentId },
            progressCheckpoints: progressCheckpoints.filter { $0.studentId == studentId },
            traits: traits.filter { $0.studentId == studentId },
            assignments: assignments.filter { $0.studentId == studentId },
            notes: notes.filter { $0.studentId == studentId },
            nextPlans: plans.filter { $0.studentId == studentId },
            todayDate: DateOnly.today(in: .current)
        )
    }

    func loadUpcomingLessons(studentId: EntityID, after date: Date, limit: Int) async throws -> [StudentUpcomingLesson] {
        StudentUpcomingLessonMapper.map(
            occurrences: occurrences,
            studentId: studentId,
            after: date,
            limit: limit
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
        tuitionCycles.append(TuitionCycle(
            id: UUID(),
            instructorId: instructor.id,
            studentId: id,
            sequence: 1,
            targetLessonCount: TuitionValidation.targetLessonCount,
            completedLessonCount: 0,
            paymentConfirmedOn: nil,
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

    func deleteStudent(studentId: EntityID) async throws {
        guard students.contains(where: { $0.id == studentId }) else {
            throw RepositoryError.notFound
        }
        let relatedOccurrences = occurrences.filter { $0.studentId == studentId }
        guard !relatedOccurrences.contains(where: { $0.status == .scheduled }) else {
            throw RepositoryError(message: "예정된 레슨이 있습니다. 캘린더에서 먼저 모두 취소한 뒤 학생을 삭제하세요.")
        }
        guard !relatedOccurrences.contains(where: {
            $0.nativeCalendarSyncStatus == .pending || $0.nativeCalendarSyncStatus == .failed
        }) else {
            throw RepositoryError(message: "Apple 캘린더 처리가 끝나지 않은 레슨이 있습니다. 동기화를 완료한 뒤 다시 시도하세요.")
        }

        students.removeAll { $0.id == studentId }
        progressItems.removeAll { $0.studentId == studentId }
        progressCheckpoints.removeAll { $0.studentId == studentId }
        traits.removeAll { $0.studentId == studentId }
        assignments.removeAll { $0.studentId == studentId }
        notes.removeAll { $0.studentId == studentId }
        plans.removeAll { $0.studentId == studentId }
        occurrences.removeAll { $0.studentId == studentId }
        tuitionCycles.removeAll { $0.studentId == studentId }
        lessonDrafts.removeAll { $0.studentId == studentId }
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

    func createProgressCheckpoint(_ input: ProgressCheckpointInput) async throws -> EntityID {
        guard let item = progressItems.first(where: { $0.id == input.progressItemId }),
              item.studentId == input.studentId else {
            throw RepositoryError.notFound
        }
        guard item.status == input.status else {
            throw ValidationError(field: "status", message: "진도 상태가 변경되었습니다. 새로고침 후 다시 저장하세요.")
        }
        let id = UUID()
        progressCheckpoints.append(ProgressCheckpoint(
            id: id,
            instructorId: instructor.id,
            studentId: input.studentId,
            progressItemId: input.progressItemId,
            observedOn: input.observedOn,
            bpm: input.bpm,
            status: input.status,
            note: input.note,
            createdAt: nil
        ))
        return id
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
        guard let occurrenceId = input.occurrenceId,
              let occurrenceIndex = occurrences.firstIndex(where: { $0.id == occurrenceId }),
              occurrences[occurrenceIndex].studentId == input.studentId else {
            throw ValidationError(field: "occurrenceId", message: "예약된 레슨에서만 마무리 기록을 저장할 수 있습니다.")
        }
        guard occurrences[occurrenceIndex].status == .scheduled else {
            throw ValidationError(field: "occurrenceId", message: "예정 상태인 레슨만 마무리할 수 있습니다.")
        }
        _ = try await createLessonNote(LessonNoteInput(
            studentId: input.studentId,
            lessonDate: input.lessonDate,
            coveredMaterial: input.coveredMaterial,
            observations: input.observations,
            practiceAssigned: input.practiceAssigned,
            nextStepHint: input.nextStepHint
        ))
        occurrences[occurrenceIndex].status = .completed
        advanceTuitionCycle(for: input.studentId)
        lessonDrafts.removeAll { $0.occurrenceId == occurrenceId }
    }

    func loadLessonDraft(occurrenceId: EntityID) async throws -> LessonDraft? {
        lessonDrafts.first { $0.occurrenceId == occurrenceId }
    }

    func upsertLessonDraft(_ input: LessonDraftInput) async throws -> LessonDraft {
        try StudentEditingValidation.validate(input)
        guard let occurrence = occurrences.first(where: { $0.id == input.occurrenceId }),
              occurrence.studentId == input.studentId,
              occurrence.status == .scheduled else {
            throw ValidationError(field: "occurrenceId", message: "예정 상태인 레슨에만 초안을 저장할 수 있습니다.")
        }
        let draft = LessonDraft(
            occurrenceId: input.occurrenceId,
            studentId: input.studentId,
            coveredMaterial: input.coveredMaterial,
            observations: input.observations,
            practiceAssigned: input.practiceAssigned,
            nextStepHint: input.nextStepHint,
            updatedAt: ISO8601DateFormatter.plain.string(from: Date())
        )
        lessonDrafts.removeAll { $0.occurrenceId == input.occurrenceId }
        lessonDrafts.append(draft)
        return draft
    }

    func deleteLessonDraft(occurrenceId: EntityID) async throws {
        lessonDrafts.removeAll { $0.occurrenceId == occurrenceId }
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
        lessonDrafts.removeAll { $0.occurrenceId == id }
        return occurrences[index]
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {}

    func loadOccurrence(id: EntityID) async throws -> LessonOccurrence {
        guard let occurrence = occurrences.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return occurrence
    }

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

    func configureTuitionCycle(
        studentId: EntityID,
        completedLessonCount: Int,
        paymentConfirmedOn: String?
    ) async throws -> EntityID {
        try TuitionValidation.validate(
            completedLessonCount: completedLessonCount,
            paymentConfirmedOn: paymentConfirmedOn
        )
        guard students.contains(where: { $0.id == studentId }) else {
            throw RepositoryError.notFound
        }
        guard !tuitionCycles.contains(where: { $0.studentId == studentId }) else {
            throw ValidationError(field: "studentId", message: "이미 수강비 관리가 시작된 학생입니다.")
        }
        let id = UUID()
        tuitionCycles.append(TuitionCycle(
            id: id,
            instructorId: instructor.id,
            studentId: studentId,
            sequence: 1,
            targetLessonCount: TuitionValidation.targetLessonCount,
            completedLessonCount: completedLessonCount,
            paymentConfirmedOn: paymentConfirmedOn,
            createdAt: nil,
            updatedAt: nil
        ))
        return id
    }

    func updateTuitionCycleProgress(
        cycleId: EntityID,
        studentId: EntityID,
        completedLessonCount: Int
    ) async throws {
        try TuitionValidation.validateCompletedLessonCount(completedLessonCount)
        guard let index = tuitionCycles.firstIndex(where: { $0.id == cycleId && $0.studentId == studentId }) else {
            throw RepositoryError.notFound
        }
        let currentId = tuitionCycles
            .filter { $0.studentId == studentId }
            .max { $0.sequence < $1.sequence }?
            .id
        guard currentId == cycleId else {
            throw ValidationError(field: "cycleId", message: "현재 수강 주기의 회차만 수정할 수 있습니다.")
        }
        tuitionCycles[index].completedLessonCount = completedLessonCount
    }

    func setTuitionPaymentConfirmation(
        cycleId: EntityID,
        studentId: EntityID,
        confirmedOn: String?
    ) async throws {
        try TuitionValidation.validatePaymentConfirmedOn(confirmedOn)
        guard let index = tuitionCycles.firstIndex(where: { $0.id == cycleId && $0.studentId == studentId }) else {
            throw RepositoryError.notFound
        }
        tuitionCycles[index].paymentConfirmedOn = confirmedOn
    }

    func startNextTuitionCycle(
        studentId: EntityID,
        currentCycleId: EntityID,
        paymentConfirmedOn: String?
    ) async throws -> EntityID {
        try TuitionValidation.validatePaymentConfirmedOn(paymentConfirmedOn)
        guard let current = tuitionCycles.first(where: { $0.id == currentCycleId && $0.studentId == studentId }) else {
            throw RepositoryError.notFound
        }
        guard tuitionCycles.filter({ $0.studentId == studentId }).max(by: { $0.sequence < $1.sequence })?.id == currentCycleId else {
            throw ValidationError(field: "currentCycleId", message: "가장 최근 수강 주기에서만 다음 4회를 시작할 수 있습니다.")
        }
        guard current.isComplete else {
            throw ValidationError(field: "completedLessonCount", message: "현재 4회를 모두 마친 뒤 다음 4회를 시작하세요.")
        }
        let id = UUID()
        tuitionCycles.append(TuitionCycle(
            id: id,
            instructorId: instructor.id,
            studentId: studentId,
            sequence: current.sequence + 1,
            targetLessonCount: TuitionValidation.targetLessonCount,
            completedLessonCount: 0,
            paymentConfirmedOn: paymentConfirmedOn,
            createdAt: nil,
            updatedAt: nil
        ))
        return id
    }

    private func advanceTuitionCycle(for studentId: EntityID) {
        guard let index = tuitionCycles.indices
            .filter({ tuitionCycles[$0].studentId == studentId })
            .max(by: { tuitionCycles[$0].sequence < tuitionCycles[$1].sequence }) else {
            return
        }
        let current = tuitionCycles[index]
        if current.isComplete {
            tuitionCycles.append(TuitionCycle(
                id: UUID(),
                instructorId: instructor.id,
                studentId: studentId,
                sequence: current.sequence + 1,
                targetLessonCount: TuitionValidation.targetLessonCount,
                completedLessonCount: 1,
                paymentConfirmedOn: nil,
                createdAt: nil,
                updatedAt: nil
            ))
        } else {
            tuitionCycles[index].completedLessonCount += 1
        }
    }
}

enum PreviewData {
    static let instructorId = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    static let minjiId = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    static let joonId = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!

    static let instructor = Instructor(
        id: instructorId,
        displayName: "Eric Shim",
        studioName: "드럼 레슨 OS",
        authUserId: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")
    )

    static let students = [
        Student(id: minjiId, instructorId: instructorId, name: "김민지", profileCue: "말보다 먼저 리듬으로 확인하면 빨리 열린다.", primaryWeakPoint: "필인 뒤 1박 착지", active: true, createdAt: nil, updatedAt: nil),
        Student(id: joonId, instructorId: instructorId, name: "박준", profileCue: "큰 그림을 먼저 말해주면 집중이 오래간다.", primaryWeakPoint: "왼손 고스트 노트 균일성", active: true, createdAt: nil, updatedAt: nil)
    ]

    static let progressItems = [
        ProgressItem(id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!, instructorId: instructorId, studentId: minjiId, category: .song, status: .inProgress, title: "좋은 밤 좋은 꿈 8비트", currentFocus: true, observedOn: "2026-05-28", detail: "코러스 전 필인에서 오른발이 앞선다.", tempoNote: "82 -> 88 BPM", updatedAt: "2026-05-28T08:00:00Z"),
        ProgressItem(id: UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!, instructorId: instructorId, studentId: joonId, category: .rudiment, status: .needsReview, title: "파라디들 악센트", currentFocus: true, observedOn: "2026-05-27", detail: "왼손 악센트가 작아진다.", tempoNote: "70 BPM", updatedAt: "2026-05-27T08:00:00Z")
    ]

    static let progressCheckpoints = [
        ProgressCheckpoint(
            id: UUID(),
            instructorId: instructorId,
            studentId: minjiId,
            progressItemId: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
            observedOn: "2026-05-21",
            bpm: 82,
            status: .inProgress,
            note: "필인 직전까지 안정적",
            createdAt: "2026-05-21T08:00:00Z"
        ),
        ProgressCheckpoint(
            id: UUID(),
            instructorId: instructorId,
            studentId: minjiId,
            progressItemId: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
            observedOn: "2026-05-28",
            bpm: 88,
            status: .inProgress,
            note: "착지 전 오른발이 조금 앞섬",
            createdAt: "2026-05-28T08:00:00Z"
        )
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

    static let tuitionCycles = [
        TuitionCycle(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            instructorId: instructorId,
            studentId: minjiId,
            sequence: 1,
            targetLessonCount: 4,
            completedLessonCount: 2,
            paymentConfirmedOn: "2026-05-01",
            createdAt: "2026-05-01T00:00:00Z",
            updatedAt: "2026-05-28T08:00:00Z"
        ),
        TuitionCycle(
            id: UUID(uuidString: "66666666-7777-8888-9999-000000000000")!,
            instructorId: instructorId,
            studentId: joonId,
            sequence: 1,
            targetLessonCount: 4,
            completedLessonCount: 3,
            paymentConfirmedOn: nil,
            createdAt: "2026-05-01T00:00:00Z",
            updatedAt: "2026-05-27T08:00:00Z"
        )
    ]

    static let occurrences = [
        LessonOccurrence(id: UUID(), instructorId: instructorId, studentId: minjiId, scheduleTemplateId: nil, startsAt: "2026-05-28T10:00:00Z", endsAt: "2026-05-28T10:50:00Z", timezone: TimeZone.current.identifier, status: .scheduled, title: "김민지 드럼 레슨", nativeCalendarEventIdentifier: nil, nativeCalendarIdentifier: nil, nativeCalendarExternalIdentifier: nil, nativeCalendarSyncStatus: .pending, nativeCalendarSyncError: nil, nativeCalendarSyncedAt: nil),
        LessonOccurrence(id: UUID(), instructorId: instructorId, studentId: joonId, scheduleTemplateId: nil, startsAt: "2026-05-28T12:00:00Z", endsAt: "2026-05-28T12:50:00Z", timezone: TimeZone.current.identifier, status: .scheduled, title: "박준 드럼 레슨", nativeCalendarEventIdentifier: nil, nativeCalendarIdentifier: nil, nativeCalendarExternalIdentifier: nil, nativeCalendarSyncStatus: .notConnected, nativeCalendarSyncError: nil, nativeCalendarSyncedAt: nil)
    ]
}
