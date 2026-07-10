import Foundation
import Testing
@testable import DrumLessonOS

@Test func addStudentFormBuildsCreateInput() throws {
    var form = AddStudentFormState()
    form.name = "최하늘"
    form.profileCue = "짧은 리듬 예시가 잘 맞는다."
    form.primaryWeakPoint = "왼손 고스트 노트"

    let input = form.makeInput()

    #expect(input.studentId == nil)
    #expect(input.name == "최하늘")
    #expect(input.profileCue == "짧은 리듬 예시가 잘 맞는다.")
    #expect(input.primaryWeakPoint == "왼손 고스트 노트")
    #expect(input.active)
    try StudentEditingValidation.validate(input)
}

@Test func validatesRequiredStudentName() {
    let input = StudentProfileInput(studentId: nil, name: "", profileCue: "cue", primaryWeakPoint: "weak", active: true)

    #expect(throws: ValidationError.self) {
        try StudentEditingValidation.validate(input)
    }
}

@Test func allowsKnownProgressTransition() {
    #expect(StudentEditingValidation.isProgressStatusTransitionAllowed(currentStatus: .new, nextStatus: .inProgress))
    #expect(!StudentEditingValidation.isProgressStatusTransitionAllowed(currentStatus: .new, nextStatus: .complete))
}

@MainActor
@Test func detailViewModelSavesProfileAndReloadsDetail() async throws {
    let repository = StudentDetailEditingSpyRepository()
    let viewModel = StudentDetailViewModel(studentId: repository.studentId, repository: repository, writes: repository)
    await viewModel.load()

    await viewModel.saveProfile(name: "김민지", profileCue: "새 큐", primaryWeakPoint: "새 약점", active: true)

    #expect(repository.updatedProfile?.profileCue == "새 큐")
    #expect(repository.loadDetailCount == 2)
    #expect(viewModel.detail?.profileCue == "새 큐")
}

@MainActor
@Test func detailViewModelSavesWorkbenchItemsAndReloadsDetail() async throws {
    let repository = StudentDetailEditingSpyRepository()
    let viewModel = StudentDetailViewModel(studentId: repository.studentId, repository: repository, writes: repository)
    await viewModel.load()

    await viewModel.saveTrait(traitId: nil, type: .practiceHabit, label: "짧게 자주", detail: "10분 루틴")
    _ = await viewModel.saveProgressItem(
        progressItemId: nil,
        category: .song,
        status: .inProgress,
        title: "8비트",
        detail: "착지 확인",
        tempoNote: "84 BPM",
        observedOn: "2026-05-28",
        currentFocus: true
    )
    await viewModel.saveProgressStatus(progressItemId: repository.progressItemId, nextStatus: .steady)
    await viewModel.saveAssignment(assignmentId: nil, title: "2마디 루프", status: .needsReview, dueDate: nil, detail: "천천히 5회")
    _ = await viewModel.saveLessonNote(
        lessonDate: "2026-05-28",
        coveredMaterial: "코러스 전 필인",
        observations: "어깨 긴장",
        practiceAssigned: "2마디 반복",
        nextStepHint: "1박 착지"
    )
    await viewModel.saveNextPlan(planId: nil, plannedFor: "2026-05-29", priority: .high, nextAction: "착지부터 확인", detail: "필인 뒤 1박")

    #expect(repository.savedTrait?.label == "짧게 자주")
    #expect(repository.savedProgress?.currentFocus == true)
    #expect(repository.savedProgressStatus?.nextStatus == .steady)
    #expect(repository.savedAssignment?.title == "2마디 루프")
    #expect(repository.savedLessonNote?.nextStepHint == "1박 착지")
    #expect(repository.savedNextPlan?.priority == .high)
    #expect(repository.loadDetailCount == 7)
}

@MainActor
@Test func detailViewModelSavesCloseoutAndShowsSuccessMessage() async throws {
    let repository = StudentDetailEditingSpyRepository()
    let viewModel = StudentDetailViewModel(
        studentId: repository.studentId,
        lessonContext: makeLessonContext(studentId: repository.studentId),
        repository: repository,
        writes: repository
    )
    await viewModel.load()

    viewModel.runCovered = "코러스 전 필인"
    viewModel.runObservation = "착지가 흔들림"
    viewModel.runPractice = "2마디 루프"
    viewModel.runNextHint = "1박 착지"
    viewModel.useRunNotesInCloseout()

    await viewModel.saveCloseout()

    #expect(repository.savedCloseout?.coveredMaterial == "코러스 전 필인")
    #expect(repository.savedCloseout?.nextAction == "1박 착지")
    #expect(repository.loadDetailCount == 2)
    #expect(viewModel.closeoutDraft == nil)
    #expect(viewModel.closeoutStatusMessage == "마무리 기록을 저장했습니다.")
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.runCovered.isEmpty)
    #expect(viewModel.runObservation.isEmpty)
    #expect(viewModel.runPractice.isEmpty)
    #expect(viewModel.runNextHint.isEmpty)
}

@MainActor
@Test func detailViewModelRejectsCloseoutWithoutLessonContext() async throws {
    let repository = StudentDetailEditingSpyRepository()
    let viewModel = StudentDetailViewModel(studentId: repository.studentId, repository: repository, writes: repository)
    await viewModel.load()
    viewModel.runCovered = "코러스 전 필인"
    viewModel.runObservation = "착지가 흔들림"
    viewModel.runPractice = "2마디 루프"
    viewModel.runNextHint = "1박 착지"
    viewModel.useRunNotesInCloseout()

    await viewModel.saveCloseout()

    #expect(repository.closeoutCallCount == 0)
    #expect(repository.savedCloseout == nil)
    #expect(viewModel.closeoutDraft != nil)
    #expect(viewModel.errorMessage == "예약된 레슨에서만 마무리 기록을 저장할 수 있습니다.")
}

@MainActor
@Test func detailViewModelUsesSelectedLessonDateForCloseout() async throws {
    let repository = StudentDetailEditingSpyRepository()
    let lessonContext = makeLessonContext(studentId: repository.studentId)
    let viewModel = StudentDetailViewModel(
        studentId: repository.studentId,
        lessonContext: lessonContext,
        repository: repository,
        writes: repository
    )
    await viewModel.load()
    viewModel.runCovered = "코러스 전 필인"
    viewModel.runObservation = "착지가 흔들림"
    viewModel.runPractice = "2마디 루프"
    viewModel.runNextHint = "1박 착지"
    viewModel.useRunNotesInCloseout()

    await viewModel.saveCloseout()

    #expect(repository.savedCloseout?.lessonDate == "2026-05-28")
    #expect(repository.savedCloseout?.occurrenceId == lessonContext.id)
}

@MainActor
@Test func detailViewModelIgnoresDuplicateCloseoutSaveWhileSaving() async throws {
    let repository = StudentDetailEditingSpyRepository()
    repository.closeoutDelayNanoseconds = 50_000_000
    let viewModel = StudentDetailViewModel(
        studentId: repository.studentId,
        lessonContext: makeLessonContext(studentId: repository.studentId),
        repository: repository,
        writes: repository
    )
    await viewModel.load()
    viewModel.runCovered = "코러스 전 필인"
    viewModel.runObservation = "착지가 흔들림"
    viewModel.runPractice = "2마디 루프"
    viewModel.runNextHint = "1박 착지"
    viewModel.useRunNotesInCloseout()

    let firstSave = Task { await viewModel.saveCloseout() }
    await Task.yield()
    let secondSave = Task { await viewModel.saveCloseout() }
    _ = await firstSave.value
    _ = await secondSave.value

    #expect(repository.closeoutCallCount == 1)
    #expect(viewModel.isSaving == false)
}

@MainActor
@Test func detailViewModelIgnoresDuplicateRegularSaveWhileSaving() async throws {
    let repository = StudentDetailEditingSpyRepository()
    repository.lessonNoteDelayNanoseconds = 50_000_000
    let viewModel = StudentDetailViewModel(studentId: repository.studentId, repository: repository, writes: repository)
    await viewModel.load()

    let firstSave = Task {
        await viewModel.saveLessonNote(
            lessonDate: "2026-05-28",
            coveredMaterial: "코러스 전 필인",
            observations: "착지가 흔들림",
            practiceAssigned: "2마디 루프",
            nextStepHint: "1박 착지"
        )
    }
    await Task.yield()
    let secondSave = Task {
        await viewModel.saveLessonNote(
            lessonDate: "2026-05-28",
            coveredMaterial: "코러스 전 필인",
            observations: "착지가 흔들림",
            practiceAssigned: "2마디 루프",
            nextStepHint: "1박 착지"
        )
    }
    _ = await firstSave.value
    _ = await secondSave.value

    #expect(repository.lessonNoteCallCount == 1)
    #expect(viewModel.isSaving == false)
}

private func makeLessonContext(studentId: EntityID) -> CalendarLessonEvent {
    CalendarLessonEvent(
        id: UUID(),
        studentId: studentId,
        studentName: "김민지",
        title: "김민지 드럼 레슨",
        dateKey: "2026-05-28",
        timeLabel: "19:00",
        durationMinutes: 50,
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T10:50:00Z",
        timezone: "Asia/Seoul",
        status: .scheduled,
        syncStatus: .synced,
        syncError: nil,
        firstCheck: "착지 확인",
        watchFlags: []
    )
}

@MainActor
private final class StudentDetailEditingSpyRepository: StudentRepository, StudentWriteRepository {
    let studentId = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    let progressItemId = UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!
    var loadDetailCount = 0
    var updatedProfile: StudentProfileInput?
    var savedTrait: StudentTraitInput?
    var savedProgress: ProgressItemInput?
    var savedProgressStatus: ProgressStatusTransitionInput?
    var savedAssignment: AssignmentInput?
    var savedLessonNote: LessonNoteInput?
    var savedNextPlan: NextPlanInput?
    var savedCloseout: LessonCloseoutInput?
    var closeoutCallCount = 0
    var closeoutDelayNanoseconds: UInt64 = 0
    var lessonNoteCallCount = 0
    var lessonNoteDelayNanoseconds: UInt64 = 0

    func loadCurrentInstructor() async throws -> Instructor {
        Instructor(id: UUID(), displayName: "Eric", studioName: nil, authUserId: nil)
    }

    func loadRoster() async throws -> [StudentRosterItem] { [] }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        loadDetailCount += 1
        return StudentDetail(
            id: studentId,
            name: updatedProfile?.name ?? "김민지",
            profileCue: updatedProfile?.profileCue ?? "기존 큐",
            primaryWeakPoint: updatedProfile?.primaryWeakPoint ?? "기존 약점",
            active: updatedProfile?.active ?? true,
            currentFocus: ProgressFocusSummary(
                id: progressItemId,
                title: "8비트",
                category: .song,
                status: savedProgressStatus?.nextStatus ?? .inProgress,
                observedOn: "2026-05-28",
                detail: "착지 확인",
                tempoNote: "84 BPM"
            ),
            progressItems: [
                StudentProgressItem(
                    id: progressItemId,
                    category: .song,
                    status: savedProgressStatus?.nextStatus ?? .inProgress,
                    title: "8비트",
                    currentFocus: true,
                    observedOn: "2026-05-28",
                    detail: "착지 확인",
                    tempoNote: "84 BPM"
                )
            ],
            traits: [],
            assignment: nil,
            recentNotes: [],
            nextPlan: nil,
            lessonBrief: LessonBrief(firstCheck: "착지 확인", weakPointBrief: "기존 약점", assignmentCue: nil, recentObservation: nil)
        )
    }

    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench {
        CalendarWorkbench(weekTitle: "", todayDateKey: "", days: [], todayEvents: [], roster: [], selectedEvent: nil)
    }

    func createStudent(_ input: StudentProfileInput) async throws -> EntityID { studentId }

    func updateStudentProfile(_ input: StudentProfileInput) async throws {
        updatedProfile = input
    }

    func upsertTrait(_ input: StudentTraitInput) async throws -> EntityID {
        savedTrait = input
        return input.traitId ?? UUID()
    }

    func upsertProgressItem(_ input: ProgressItemInput) async throws -> EntityID {
        savedProgress = input
        return input.progressItemId ?? progressItemId
    }

    func updateProgressStatus(_ input: ProgressStatusTransitionInput) async throws {
        savedProgressStatus = input
    }

    func upsertAssignment(_ input: AssignmentInput) async throws -> EntityID {
        savedAssignment = input
        return input.assignmentId ?? UUID()
    }

    func createLessonNote(_ input: LessonNoteInput) async throws -> EntityID {
        lessonNoteCallCount += 1
        if lessonNoteDelayNanoseconds > 0 {
            try await Task<Never, Never>.sleep(nanoseconds: lessonNoteDelayNanoseconds)
        }
        savedLessonNote = input
        return UUID()
    }

    func upsertNextPlan(_ input: NextPlanInput) async throws -> EntityID {
        savedNextPlan = input
        return input.planId ?? UUID()
    }

    func closeoutLesson(_ input: LessonCloseoutInput) async throws {
        closeoutCallCount += 1
        if closeoutDelayNanoseconds > 0 {
            try await Task<Never, Never>.sleep(nanoseconds: closeoutDelayNanoseconds)
        }
        savedCloseout = input
    }
}
