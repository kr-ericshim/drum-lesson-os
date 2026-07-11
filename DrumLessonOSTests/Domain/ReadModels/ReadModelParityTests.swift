import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func rosterUsesFocusedProgressAndLatestNextPlan() async throws {
    let repository = PreviewRepository()
    let roster = try await repository.loadRoster()
    let minji = try #require(roster.first { $0.name == "김민지" })

    #expect(minji.currentFocus?.title == "좋은 밤 좋은 꿈 8비트")
    #expect(minji.nextPlan?.nextAction == "필인 뒤 1박 착지부터 확인")
    #expect(minji.assignmentStatus == .needsReview)
}

@Test func closeoutDraftCopiesNextHintToNextAction() {
    let draft = LessonCloseoutDraftBuilder.build(
        coveredMaterial: "코러스 전 필인",
        observations: "착지가 흔들림",
        practiceAssigned: "2마디 루프",
        selectedChecklistLabels: ["오른발 먼저 확인"],
        nextStepHint: "",
        fallbackFirstCheck: "필인 뒤 1박 착지"
    )

    #expect(draft.nextStepHint == "필인 뒤 1박 착지")
    #expect(draft.nextAction == "필인 뒤 1박 착지")
    #expect(draft.observations.contains("오른발 먼저 확인"))
}

@MainActor
@Test func calendarWorkbenchGroupsTodayEvents() async throws {
    let targetDate = ISO8601DateFormatter.plain.date(from: "2026-05-28T00:00:00Z")!
    let repository = PreviewRepository()
    let model = CalendarWorkbenchMapper.map(
        occurrences: PreviewData.occurrences,
        students: try await repository.loadRoster(),
        weekContaining: targetDate,
        timezone: TimeZone.current.identifier,
        today: targetDate
    )

    #expect(model.days.count == 7)
    #expect(model.weekTitle == "2026년 5월 25–31일")
    #expect(model.todayEvents.map(\.studentName).contains("김민지"))
    #expect(model.todayEvents.first?.timezone == PreviewData.occurrences.first?.timezone)
}

@Test func rosterAndDetailKeepCurrentFocusNilWhenNothingIsExplicitlyFocused() throws {
    let student = Student(
        id: UUID(),
        instructorId: PreviewData.instructorId,
        name: "초점 없는 학생",
        profileCue: "천천히 확인",
        primaryWeakPoint: "기본 박자",
        active: true,
        createdAt: nil,
        updatedAt: nil
    )
    let progress = ProgressItem(
        id: UUID(),
        instructorId: PreviewData.instructorId,
        studentId: student.id,
        category: .technique,
        status: .inProgress,
        title: "최근 항목",
        currentFocus: false,
        observedOn: "2026-07-10",
        detail: "아직 초점으로 선택하지 않음",
        tempoNote: nil,
        updatedAt: "2026-07-10T10:00:00Z"
    )

    let roster = StudentRosterMapper.map(
        students: [student],
        progressItems: [progress],
        assignments: [],
        nextPlans: [],
        notes: [],
        todayDate: "2026-07-10"
    )
    let item = try #require(roster.first)
    let detail = StudentDetailMapper.map(
        student: student,
        progressItems: [progress],
        traits: [],
        assignments: [],
        notes: [],
        nextPlans: [],
        todayDate: "2026-07-10"
    )

    #expect(item.currentFocus == nil)
    #expect(item.attentionFlags.contains { $0.kind == .noCurrentFocus })
    #expect(detail.currentFocus == nil)
}

@MainActor
@Test func calendarWorkbenchDoesNotSelectLessonOutsideVisibleWeek() async throws {
    let targetDate = ISO8601DateFormatter.plain.date(from: "2026-07-10T00:00:00Z")!
    let repository = PreviewRepository()
    let model = CalendarWorkbenchMapper.map(
        occurrences: PreviewData.occurrences,
        students: try await repository.loadRoster(),
        weekContaining: targetDate,
        timezone: TimeZone.current.identifier,
        today: targetDate
    )

    #expect(model.days.flatMap(\.events).isEmpty)
    #expect(model.selectedEvent == nil)
}

@MainActor
@Test func calendarWorkbenchDoesNotMarkViewedWeekAsToday() async throws {
    let viewedDate = ISO8601DateFormatter.plain.date(from: "2026-05-28T00:00:00Z")!
    let actualToday = ISO8601DateFormatter.plain.date(from: "2026-07-10T00:00:00Z")!
    let repository = PreviewRepository()
    let model = CalendarWorkbenchMapper.map(
        occurrences: PreviewData.occurrences,
        students: try await repository.loadRoster(),
        weekContaining: viewedDate,
        timezone: TimeZone.current.identifier,
        today: actualToday
    )
    let markedTodayDays = model.days.filter(\.isToday)

    #expect(markedTodayDays.isEmpty)
    #expect(model.todayEvents.isEmpty)
    #expect(model.selectedEvent != nil)
}

@MainActor
@Test func calendarWorkbenchExcludesCanceledOccurrences() async throws {
    let repository = PreviewRepository()
    let modelBeforeCancel = try await repository.loadCalendarWorkbench(weekContaining: ISO8601DateFormatter.plain.date(from: "2026-05-28T00:00:00Z")!)
    let occurrence = try #require(modelBeforeCancel.days.flatMap(\.events).first { $0.studentName == "박준" })

    _ = try await repository.cancelOccurrence(id: occurrence.id)
    let modelAfterCancel = try await repository.loadCalendarWorkbench(weekContaining: ISO8601DateFormatter.plain.date(from: "2026-05-28T00:00:00Z")!)

    #expect(!modelAfterCancel.todayEvents.map(\.id).contains(occurrence.id))
    #expect(!modelAfterCancel.days.flatMap(\.events).map(\.id).contains(occurrence.id))
    #expect(modelAfterCancel.selectedEvent?.id != occurrence.id)
}

@Test func studentDetailTabsExposeEmptyStates() {
    #expect(StudentDetailTabContentState.progress(items: []) == .empty(
        title: "아직 진도 기록이 없습니다",
        systemImage: "target",
        description: "기록 관리 및 편집을 열어 첫 진도 항목을 추가하세요."
    ))
    #expect(StudentDetailTabContentState.notes([]) == .empty(
        title: "아직 레슨 노트가 없습니다",
        systemImage: "note.text",
        description: "레슨 노트를 추가하면 이곳에서 최근 기록을 확인할 수 있습니다."
    ))
}

@Test func studentDetailTabsTreatPopulatedContentAsPopulated() {
    let progressItem = StudentProgressItem(
        id: UUID(),
        category: .song,
        status: .inProgress,
        title: "8비트",
        currentFocus: true,
        observedOn: "2026-05-28",
        detail: "착지 확인",
        tempoNote: nil,
        checkpoints: []
    )
    let note = StudentLessonNote(
        id: UUID(),
        lessonDate: "2026-05-28",
        coveredMaterial: "코러스 전 필인",
        observations: "착지 흔들림",
        practiceAssigned: "2마디 루프",
        nextStepHint: "1박 착지"
    )

    #expect(StudentDetailTabContentState.progress(items: [progressItem]) == .populated)
    #expect(StudentDetailTabContentState.notes([note]) == .populated)
}
