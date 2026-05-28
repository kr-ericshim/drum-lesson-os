import Testing
@testable import DrumLessonOS

@Test func expandsWeeklyOccurrencesForEightWeeks() {
    let template = WeeklyScheduleInput(
        studentId: PreviewData.minjiId,
        title: "김민지 drum lesson",
        defaultDurationMinutes: 50,
        timezone: "Asia/Seoul",
        recurrenceInterval: 1,
        recurrenceWeekday: 4,
        startsOn: "2026-05-28",
        endsOn: nil,
        startTime: "19:00"
    ).template(instructorId: PreviewData.instructorId)

    let occurrences = WeeklyOccurrenceExpander.expand(
        template: template,
        horizonStartDate: "2026-05-28",
        existingDateKeys: []
    )

    #expect(occurrences.count == 8)
    #expect(occurrences[0].title == "김민지 drum lesson")
}
