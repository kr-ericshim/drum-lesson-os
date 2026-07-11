import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func dashboardKeepsCommittedWeekWhenNewWeekLoadFails() async throws {
    let firstAnchor = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-25T00:00:00Z"))
    let nextAnchor = try #require(ISO8601DateFormatter.plain.date(from: "2026-06-01T00:00:00Z"))
    let firstModel = makeDashboardWorkbench(title: "5월 마지막 주")
    let repository = DashboardStudentRepositoryFake(results: [
        .success(firstModel),
        .failure(RepositoryError(message: "다음 주를 불러오지 못했습니다."))
    ])
    let viewModel = DashboardViewModel(
        repository: repository,
        scheduleRepository: DashboardScheduleRepositoryFake(),
        weekAnchor: firstAnchor
    )

    await viewModel.load()
    let committedSelection = viewModel.selectedEvent
    await viewModel.load(weekContaining: nextAnchor)

    #expect(viewModel.weekAnchor == firstAnchor)
    #expect(viewModel.model == firstModel)
    #expect(viewModel.selectedEvent == committedSelection)
    #expect(viewModel.errorMessage == "다음 주를 불러오지 못했습니다.")
    #expect(!viewModel.isLoading)
}

@MainActor
@Test func dashboardIgnoresAnOlderLoadThatFinishesLast() async throws {
    let firstAnchor = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-25T00:00:00Z"))
    let nextAnchor = try #require(ISO8601DateFormatter.plain.date(from: "2026-06-01T00:00:00Z"))
    let firstModel = makeDashboardWorkbench(title: "이전 요청")
    let nextModel = makeDashboardWorkbench(title: "최신 요청")
    let repository = DashboardStudentRepositoryFake()
    let viewModel = DashboardViewModel(
        repository: repository,
        scheduleRepository: DashboardScheduleRepositoryFake(),
        weekAnchor: firstAnchor
    )

    let firstLoad = Task { await viewModel.load(weekContaining: firstAnchor) }
    try await waitForPendingLoadCount(1, repository: repository)
    let nextLoad = Task { await viewModel.load(weekContaining: nextAnchor) }
    try await waitForPendingLoadCount(2, repository: repository)

    repository.resumePendingLoad(at: 1, with: .success(nextModel))
    await nextLoad.value
    repository.resumePendingLoad(at: 0, with: .success(firstModel))
    await firstLoad.value

    #expect(viewModel.weekAnchor == nextAnchor)
    #expect(viewModel.model == nextModel)
    #expect(viewModel.selectedEvent == nextModel.selectedEvent)
    #expect(viewModel.errorMessage == nil)
    #expect(!viewModel.isLoading)
}

@MainActor
@Test func dashboardReloadsWorkbenchAfterReconcilingPendingCalendarEvents() async throws {
    let anchor = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-25T00:00:00Z"))
    let beforeReconciliation = makeDashboardWorkbench(title: "동기화 전", syncStatus: .pending)
    let afterReconciliation = makeDashboardWorkbench(title: "동기화 후", syncStatus: .synced)
    let repository = DashboardStudentRepositoryFake(results: [
        .success(beforeReconciliation),
        .success(afterReconciliation)
    ])
    let schedules = DashboardScheduleRepositoryFake(reconciledCount: 1)
    let viewModel = DashboardViewModel(
        repository: repository,
        scheduleRepository: schedules,
        weekAnchor: anchor
    )

    await viewModel.load()

    #expect(repository.requestedAnchors == [anchor, anchor])
    #expect(schedules.reconcileCallCount == 1)
    #expect(viewModel.model == afterReconciliation)
    #expect(viewModel.selectedEvent?.syncStatus == .synced)
}

@MainActor
@Test func dashboardCalendarActionsUseCapturedOccurrenceIdentifier() async {
    let initial = makeDashboardWorkbench(title: "처음")
    let afterCancel = makeDashboardWorkbench(title: "취소 후")
    let afterRetry = makeDashboardWorkbench(title: "재시도 후")
    let repository = DashboardStudentRepositoryFake(results: [
        .success(initial),
        .success(afterCancel),
        .success(afterRetry)
    ])
    let schedules = DashboardScheduleRepositoryFake()
    let viewModel = DashboardViewModel(repository: repository, scheduleRepository: schedules)
    let capturedCancelId = UUID()
    let capturedRetryId = UUID()

    await viewModel.load()
    await viewModel.cancelOccurrence(id: capturedCancelId)
    await viewModel.retryCalendarSync(occurrenceId: capturedRetryId)

    #expect(schedules.canceledOccurrenceIds == [capturedCancelId])
    #expect(schedules.retriedOccurrenceIds == [capturedRetryId])
}

@MainActor
@Test func dashboardDragMovePreservesLocalTimeWhenChangingDay() async throws {
    let initial = makeDashboardWorkbench(title: "이동 전")
    let moved = makeDashboardWorkbench(title: "이동 후")
    let repository = DashboardStudentRepositoryFake(results: [
        .success(initial),
        .success(moved)
    ])
    let schedules = DashboardScheduleRepositoryFake()
    let viewModel = DashboardViewModel(repository: repository, scheduleRepository: schedules)
    let event = try #require(initial.selectedEvent)

    await viewModel.load()
    await viewModel.moveOccurrence(event, toDateKey: "2026-05-29")

    let input = try #require(schedules.editedInputs.first)
    #expect(input.occurrenceId == event.id)
    #expect(input.startsAt == "2026-05-29T10:00:00Z")
    #expect(input.endsAt == "2026-05-29T10:50:00Z")
    #expect(viewModel.model == moved)
}

@MainActor
@Test func dashboardDragMoveKeepsRenderedEventStableUntilEditCompletes() async throws {
    let initial = makeDashboardWorkbench(title: "이동 전")
    let moved = makeDashboardWorkbench(title: "이동 후")
    let repository = DashboardStudentRepositoryFake(results: [
        .success(initial),
        .success(moved)
    ])
    let schedules = DashboardScheduleRepositoryFake(suspendEdits: true)
    let viewModel = DashboardViewModel(repository: repository, scheduleRepository: schedules)
    let event = try #require(initial.selectedEvent)

    await viewModel.load()
    let move = Task {
        await viewModel.moveOccurrence(event, toDateKey: "2026-05-29")
    }
    try await waitForPendingEditCount(1, repository: schedules)

    #expect(viewModel.model == initial)
    #expect(viewModel.selectedEvent == initial.selectedEvent)
    #expect(viewModel.movingOccurrenceIDs == [event.id])

    await viewModel.moveOccurrence(event, toDateKey: "2026-05-30")
    #expect(schedules.editedInputs.count == 1)

    schedules.resumePendingEdit(at: 0)
    await move.value

    #expect(viewModel.model == moved)
    #expect(viewModel.selectedEvent == moved.selectedEvent)
    #expect(viewModel.movingOccurrenceIDs.isEmpty)
}

@Test func calendarDragMoveUsesDroppedMinuteInLessonTimezone() throws {
    let event = try #require(makeDashboardWorkbench(title: "시간 이동").selectedEvent)

    let input = try ScheduleMoveInputFactory.makeInput(
        event: event,
        targetDateKey: "2026-05-29",
        targetMinuteOfDay: 20 * 60 + 15
    )

    #expect(input.startsAt == "2026-05-29T11:15:00Z")
    #expect(input.endsAt == "2026-05-29T12:05:00Z")
}

@Test func lessonEventDragPayloadResolvesTheDraggedEvent() throws {
    let model = makeDashboardWorkbench(title: "드래그 대상")
    let event = try #require(model.selectedEvent)

    let resolved = LessonEventDragPayload.event(
        from: [LessonEventDragPayload.value(for: event)],
        in: model.days.flatMap(\.events)
    )

    #expect(resolved == event)
    #expect(LessonEventDragPayload.event(from: ["invalid"], in: [event]) == nil)
}

@MainActor
private func waitForPendingLoadCount(
    _ expectedCount: Int,
    repository: DashboardStudentRepositoryFake
) async throws {
    for _ in 0..<1_000 {
        if repository.pendingLoads.count >= expectedCount { return }
        await Task.yield()
    }
    _ = try #require(
        repository.pendingLoads.count >= expectedCount,
        "대시보드 로드 요청이 제한 시간 안에 시작되지 않았습니다."
    )
}

@MainActor
private func waitForPendingEditCount(
    _ expectedCount: Int,
    repository: DashboardScheduleRepositoryFake
) async throws {
    for _ in 0..<1_000 {
        if repository.pendingEditContinuations.count >= expectedCount { return }
        await Task.yield()
    }
    _ = try #require(
        repository.pendingEditContinuations.count >= expectedCount,
        "일정 이동 요청이 제한 시간 안에 시작되지 않았습니다."
    )
}

private func makeDashboardWorkbench(
    title: String,
    syncStatus: NativeCalendarSyncStatus = .synced
) -> CalendarWorkbench {
    let event = CalendarLessonEvent(
        id: UUID(),
        studentId: PreviewData.minjiId,
        studentName: "김민지",
        title: "김민지 드럼 레슨",
        dateKey: "2026-05-28",
        timeLabel: "19:00",
        durationMinutes: 50,
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T10:50:00Z",
        timezone: "Asia/Seoul",
        status: .scheduled,
        syncStatus: syncStatus,
        syncError: nil,
        firstCheck: "착지 확인",
        watchFlags: []
    )
    let day = CalendarDay(
        dateKey: event.dateKey,
        label: title,
        isToday: false,
        events: [event]
    )
    return CalendarWorkbench(
        weekTitle: title,
        todayDateKey: "2026-05-28",
        days: [day],
        todayEvents: [],
        roster: [],
        selectedEvent: event
    )
}

@MainActor
private final class DashboardStudentRepositoryFake: StudentRepository {
    struct PendingLoad {
        var anchor: Date
        var continuation: CheckedContinuation<CalendarWorkbench, Error>
    }

    var requestedAnchors: [Date] = []
    var pendingLoads: [PendingLoad] = []
    private var results: [Result<CalendarWorkbench, RepositoryError>]

    init(results: [Result<CalendarWorkbench, RepositoryError>] = []) {
        self.results = results
    }

    func loadCurrentInstructor() async throws -> Instructor {
        throw RepositoryError.notFound
    }

    func loadRoster() async throws -> [StudentRosterItem] {
        throw RepositoryError.notFound
    }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        throw RepositoryError.notFound
    }

    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench {
        requestedAnchors.append(date)
        if !results.isEmpty {
            return try results.removeFirst().get()
        }
        return try await withCheckedThrowingContinuation { continuation in
            pendingLoads.append(PendingLoad(anchor: date, continuation: continuation))
        }
    }

    func resumePendingLoad(
        at index: Int,
        with result: Result<CalendarWorkbench, RepositoryError>
    ) {
        switch result {
        case .success(let model):
            pendingLoads[index].continuation.resume(returning: model)
        case .failure(let error):
            pendingLoads[index].continuation.resume(throwing: error)
        }
    }
}

@MainActor
private final class DashboardScheduleRepositoryFake: ScheduleRepository {
    var reconcileCallCount = 0
    var canceledOccurrenceIds: [EntityID] = []
    var retriedOccurrenceIds: [EntityID] = []
    var editedInputs: [EditOccurrenceInput] = []
    var pendingEditContinuations: [CheckedContinuation<LessonOccurrence, Never>] = []
    private var pendingEditOccurrences: [LessonOccurrence] = []
    private let reconciledCount: Int
    private let suspendEdits: Bool

    init(reconciledCount: Int = 0, suspendEdits: Bool = false) {
        self.reconciledCount = reconciledCount
        self.suspendEdits = suspendEdits
    }

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        throw RepositoryError.notFound
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        throw RepositoryError.notFound
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        editedInputs.append(input)
        var occurrence = ScheduleLessonInput(
            studentId: PreviewData.minjiId,
            title: "김민지 드럼 레슨",
            startsAt: input.startsAt,
            endsAt: input.endsAt,
            timezone: input.timezone,
            durationMinutes: DateOnly.minutes(from: input.startsAt, to: input.endsAt)
        ).makeOccurrence(instructorId: PreviewData.instructorId)
        occurrence.id = input.occurrenceId
        occurrence.nativeCalendarSyncStatus = .synced
        if suspendEdits {
            return await withCheckedContinuation { continuation in
                pendingEditOccurrences.append(occurrence)
                pendingEditContinuations.append(continuation)
            }
        }
        return occurrence
    }

    func resumePendingEdit(at index: Int) {
        pendingEditContinuations[index].resume(returning: pendingEditOccurrences[index])
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        canceledOccurrenceIds.append(id)
        var occurrence = ScheduleLessonInput(
            studentId: PreviewData.minjiId,
            title: "김민지 드럼 레슨",
            startsAt: "2026-05-28T10:00:00Z",
            endsAt: "2026-05-28T10:50:00Z",
            timezone: "Asia/Seoul",
            durationMinutes: 50
        ).makeOccurrence(instructorId: PreviewData.instructorId)
        occurrence.id = id
        occurrence.status = .canceled
        return occurrence
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {
        retriedOccurrenceIds.append(occurrenceId)
    }

    func reconcilePendingNativeCalendarSync() async throws -> Int {
        reconcileCallCount += 1
        return reconciledCount
    }

    func loadOccurrence(id: EntityID) async throws -> LessonOccurrence {
        throw RepositoryError.notFound
    }

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        throw RepositoryError.notFound
    }
}
