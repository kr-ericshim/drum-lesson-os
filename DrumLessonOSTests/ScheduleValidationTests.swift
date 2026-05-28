import Foundation
import Testing
@testable import DrumLessonOS

@Test func rejectsShortLessonDuration() {
    let input = ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "Lesson",
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T10:10:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 10
    )

    #expect(throws: ValidationError.self) {
        try ScheduleValidation.validate(input)
    }
}

@MainActor
@Test func scheduleLessonFormBuildsInputFromSelectedRosterStudentAndFields() async throws {
    let roster = try await PreviewRepository().loadRoster()
    let joon = try #require(roster.first { $0.id == PreviewData.joonId })
    var form = ScheduleLessonFormState(roster: roster)
    form.selectedStudentId = joon.id
    form.title = "Groove check"
    form.startDate = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-28T12:30:00Z"))
    form.durationMinutes = 75
    form.timezone = "Asia/Seoul"

    let input = try form.makeOneOffInput()

    #expect(input.studentId == PreviewData.joonId)
    #expect(input.title == "Groove check")
    #expect(input.startsAt == "2026-05-28T12:30:00Z")
    #expect(input.endsAt == "2026-05-28T13:45:00Z")
    #expect(input.durationMinutes == 75)
    #expect(input.timezone == "Asia/Seoul")
}

@MainActor
@Test func scheduleLessonFormBuildsWeeklyInput() async throws {
    let roster = try await PreviewRepository().loadRoster()
    var form = ScheduleLessonFormState(roster: roster)
    form.mode = .weekly
    form.selectedStudentId = PreviewData.minjiId
    form.title = "Weekly groove"
    var components = DateComponents()
    components.calendar = .iso8601SeoulCompatible
    components.timeZone = .current
    components.year = 2026
    components.month = 5
    components.day = 29
    components.hour = 11
    components.minute = 15
    form.startDate = try #require(components.date)
    form.durationMinutes = 60
    form.timezone = "Asia/Seoul"
    form.recurrenceWeekday = 5
    form.recurrenceInterval = 2
    form.hasEndDate = true
    form.endDate = try #require(ISO8601DateFormatter.plain.date(from: "2026-07-31T00:00:00Z"))

    let input = try form.makeWeeklyInput()

    #expect(input.studentId == PreviewData.minjiId)
    #expect(input.title == "Weekly groove")
    #expect(input.defaultDurationMinutes == 60)
    #expect(input.recurrenceWeekday == 5)
    #expect(input.recurrenceInterval == 2)
    #expect(input.startsOn == "2026-05-29")
    #expect(input.endsOn == "2026-07-31")
    #expect(input.startTime == "11:15:00")
}

@Test func editOccurrenceFormBuildsEditInput() throws {
    let event = CalendarLessonEvent(
        id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        studentId: PreviewData.minjiId,
        studentName: "김민지",
        title: "김민지 drum lesson",
        dateKey: "2026-05-28",
        timeLabel: "19:00",
        durationMinutes: 80,
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T11:20:00Z",
        status: .scheduled,
        syncStatus: .pending,
        syncError: nil,
        firstCheck: "확인",
        watchFlags: []
    )
    let input = EditOccurrenceFormState(event: event).makeInput(occurrenceId: event.id)

    #expect(input.occurrenceId == event.id)
    #expect(input.startsAt == "2026-05-28T10:00:00Z")
    #expect(input.endsAt == "2026-05-28T11:20:00Z")
}
