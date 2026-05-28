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
    let repository = PreviewRepository()
    let model = try await repository.loadCalendarWorkbench(weekContaining: ISO8601DateFormatter.plain.date(from: "2026-05-28T00:00:00Z")!)

    #expect(model.days.count == 7)
    #expect(model.todayEvents.map(\.studentName).contains("김민지"))
}
