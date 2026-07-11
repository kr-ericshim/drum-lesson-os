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

@Test func duplicateSuppressionUsesTemplateAndDateInsteadOfDateAlone() throws {
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
    let otherTemplateId = EntityID()
    let unrelatedKey = WeeklyOccurrenceExpander.occurrenceKey(
        templateId: otherTemplateId,
        dateKey: "2026-05-28"
    )

    let unaffected = WeeklyOccurrenceExpander.expand(
        template: template,
        horizonStartDate: "2026-05-28",
        horizonWeeks: 1,
        existingOccurrenceKeys: [unrelatedKey]
    )
    let ownKey = WeeklyOccurrenceExpander.occurrenceKey(
        templateId: template.id,
        dateKey: "2026-05-28"
    )
    let suppressed = WeeklyOccurrenceExpander.expand(
        template: template,
        horizonStartDate: "2026-05-28",
        horizonWeeks: 1,
        existingOccurrenceKeys: [ownKey]
    )

    #expect(unaffected.count == 1)
    #expect(suppressed.isEmpty)
}

@Test func laterExpansionKeepsMultiWeekCadenceAnchoredToTemplateStart() {
    let template = WeeklyScheduleInput(
        studentId: PreviewData.minjiId,
        title: "격주 레슨",
        defaultDurationMinutes: 50,
        timezone: "Asia/Seoul",
        recurrenceInterval: 2,
        recurrenceWeekday: 4,
        startsOn: "2026-05-28",
        endsOn: nil,
        startTime: "19:00"
    ).template(instructorId: PreviewData.instructorId)

    let offWeek = WeeklyOccurrenceExpander.expand(
        template: template,
        horizonStartDate: "2026-06-04",
        horizonWeeks: 1,
        existingOccurrenceKeys: []
    )
    let onWeek = WeeklyOccurrenceExpander.expand(
        template: template,
        horizonStartDate: "2026-06-11",
        horizonWeeks: 1,
        existingOccurrenceKeys: []
    )

    #expect(offWeek.isEmpty)
    #expect(onWeek.count == 1)
}
