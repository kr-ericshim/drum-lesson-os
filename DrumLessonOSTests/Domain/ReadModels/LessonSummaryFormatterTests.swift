import Testing
@testable import DrumLessonOS

@Test func lessonSummaryFormatterBuildsShareableKoreanSummary() {
    let summary = LessonSummaryFormatter.make(
        studentName: "김민수",
        lessonDate: "2026-07-11",
        draft: LessonCloseoutDraft(
            coveredMaterial: "싱글 스트로크 80~92 BPM",
            observations: "88 BPM부터 오른손 힘\n어깨 긴장",
            practiceAssigned: "85 BPM 3분 × 3세트",
            nextStepHint: "왼손 악센트",
            nextAction: "왼손 악센트"
        )
    )

    #expect(summary.contains("[김민수 7월 11일 레슨]"))
    #expect(summary.contains("관찰\n- 88 BPM부터 오른손 힘\n- 어깨 긴장"))
    #expect(summary.contains("연습 과제\n- 85 BPM 3분 × 3세트"))
    #expect(summary.hasSuffix("다음 확인\n- 왼손 악센트"))
}
