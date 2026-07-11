import Foundation
import Testing
@testable import DrumLessonOS

@Test func studentRosterQuerySearchesNamesAndTeachingCues() {
    let minji = makeRosterItem(name: "김민지", profileCue: "리듬으로 먼저 확인", weakPoint: "필인 착지")
    let joon = makeRosterItem(name: "박준", profileCue: "큰 그림 설명", weakPoint: "고스트 노트")

    #expect(StudentRosterQuery.filter([minji, joon], searchText: "민지", filter: .all).map(\.id) == [minji.id])
    #expect(StudentRosterQuery.filter([minji, joon], searchText: "고스트", filter: .all).map(\.id) == [joon.id])
    #expect(StudentRosterQuery.filter([minji, joon], searchText: "큰 그림", filter: .all).map(\.id) == [joon.id])
}

@Test func studentRosterQueryAppliesNativeRosterFilters() {
    let needsReview = makeRosterItem(
        name: "확인 학생",
        flags: [LessonAttentionFlag(kind: .needsAssignmentReview, label: "과제 확인")]
    )
    let highPriority = makeRosterItem(
        name: "우선 학생",
        currentFocus: ProgressFocusSummary(
            id: UUID(),
            title: "8비트",
            category: .song,
            status: .inProgress,
            observedOn: "2026-07-11",
            detail: "착지",
            tempoNote: nil
        ),
        nextPlan: StudentNextPlan(
            id: UUID(),
            plannedFor: nil,
            priority: .high,
            nextAction: "착지 확인",
            detail: "필인 뒤"
        )
    )
    let stale = makeRosterItem(
        name: "오래된 학생",
        lastLessonDate: "2026-05-01",
        flags: [LessonAttentionFlag(kind: .staleLesson, label: "노트 오래됨")]
    )
    let noFocus = makeRosterItem(name: "초점 없는 학생")
    let roster = [needsReview, highPriority, stale, noFocus]

    #expect(StudentRosterQuery.filter(roster, searchText: "", filter: .needsReview).map(\.id) == [needsReview.id])
    #expect(StudentRosterQuery.filter(roster, searchText: "", filter: .highPriority).map(\.id) == [highPriority.id])
    #expect(StudentRosterQuery.filter(roster, searchText: "", filter: .staleNote).map(\.id) == [needsReview.id, highPriority.id, stale.id, noFocus.id])
    #expect(StudentRosterQuery.filter(roster, searchText: "", filter: .noCurrentFocus).map(\.id) == [needsReview.id, stale.id, noFocus.id])
}

private func makeRosterItem(
    name: String,
    profileCue: String = "단서",
    weakPoint: String = "약점",
    currentFocus: ProgressFocusSummary? = nil,
    nextPlan: StudentNextPlan? = nil,
    lastLessonDate: String? = nil,
    flags: [LessonAttentionFlag] = []
) -> StudentRosterItem {
    StudentRosterItem(
        id: UUID(),
        name: name,
        profileCue: profileCue,
        primaryWeakPoint: weakPoint,
        active: true,
        currentFocus: currentFocus,
        assignmentStatus: nil,
        nextPlan: nextPlan,
        lastLessonDate: lastLessonDate,
        attentionFlags: flags
    )
}
