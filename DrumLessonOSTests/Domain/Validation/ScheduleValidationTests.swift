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

@Test func rejectsInvalidOneOffTimezoneAndInconsistentTimeRange() {
    let invalidTimeZone = ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "Lesson",
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T11:00:00Z",
        timezone: "Mars/Studio",
        durationMinutes: 60
    )
    let invertedRange = ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "Lesson",
        startsAt: "2026-05-28T11:00:00Z",
        endsAt: "2026-05-28T10:00:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 60
    )
    let mismatchedDuration = ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "Lesson",
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T11:00:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    )

    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalidTimeZone) }
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invertedRange) }
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(mismatchedDuration) }
}

@Test func validatesWeeklyDatesTimezoneDurationAndStartTime() {
    let valid = WeeklyScheduleInput(
        studentId: PreviewData.minjiId,
        title: "Weekly lesson",
        defaultDurationMinutes: 50,
        timezone: "Asia/Seoul",
        recurrenceInterval: 1,
        recurrenceWeekday: 4,
        startsOn: "2026-05-28",
        endsOn: "2026-07-30",
        startTime: "19:00:00"
    )
    #expect(throws: Never.self) { try ScheduleValidation.validate(valid) }

    var invalid = valid
    invalid.startsOn = "2026-02-30"
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
    invalid = valid
    invalid.endsOn = "2026-05-27"
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
    invalid = valid
    invalid.timezone = "Invalid/Zone"
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
    invalid = valid
    invalid.defaultDurationMinutes = 5
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
    invalid = valid
    invalid.startTime = "25:90"
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
    invalid = valid
    invalid.startsOn = "2026-05-29"
    invalid.recurrenceWeekday = 4
    invalid.endsOn = "2026-05-30"
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
}

@Test func validatesEditedOccurrenceTimeRangeAndTimezone() {
    let valid = EditOccurrenceInput(
        occurrenceId: UUID(),
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T11:00:00Z",
        timezone: "Asia/Seoul"
    )
    #expect(throws: Never.self) { try ScheduleValidation.validate(valid) }

    var invalid = valid
    invalid.endsAt = "2026-05-28T09:00:00Z"
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
    invalid = valid
    invalid.timezone = "Invalid/Zone"
    #expect(throws: ValidationError.self) { try ScheduleValidation.validate(invalid) }
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
@Test func scheduleLessonFormUsesConfiguredDefaultDuration() async throws {
    let roster = try await PreviewRepository().loadRoster()

    let form = ScheduleLessonFormState(roster: roster, defaultDurationMinutes: 60)

    #expect(form.durationMinutes == 60)
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

@MainActor
@Test func scheduleLessonFormSerializesWeeklyWallTimeInSelectedTimezone() async throws {
    let roster = try await PreviewRepository().loadRoster()
    var form = ScheduleLessonFormState(roster: roster)
    form.mode = .weekly
    form.timezone = "America/New_York"
    form.startDate = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-29T01:15:00Z"))
    form.recurrenceWeekday = 4

    let input = try form.makeWeeklyInput()

    #expect(input.startsOn == "2026-05-28")
    #expect(input.startTime == "21:15:00")
    #expect(input.timezone == "America/New_York")
}

@MainActor
@Test func scheduleLessonFormUpdatesOnlySuggestedTitlesWhenStudentChanges() async throws {
    let roster = try await PreviewRepository().loadRoster()
    let minji = try #require(roster.first { $0.id == PreviewData.minjiId })
    let joon = try #require(roster.first { $0.id == PreviewData.joonId })
    var form = ScheduleLessonFormState(roster: roster)

    form.selectStudent(joon.id)
    #expect(form.title == "\(joon.name) 드럼 레슨")

    form.updateTitle("합주 전 최종 점검")
    form.selectStudent(minji.id)
    #expect(form.title == "합주 전 최종 점검")
    #expect(!form.isUsingSuggestedTitle)
}

@Test func scheduleLessonFormSummarizesRecurringPatternInKorean() throws {
    var form = ScheduleLessonFormState(roster: [], now: Date(timeIntervalSince1970: 0))
    form.mode = .weekly
    form.recurrenceWeekday = 5
    form.recurrenceInterval = 2

    #expect(ScheduleLessonMode.oneOff.label == "한 번")
    #expect(ScheduleLessonMode.weekly.label == "반복")
    #expect(ScheduleLessonMode.weekly.explanation == "정한 요일과 간격에 맞춰 레슨을 반복합니다.")
    #expect(form.recurrenceSummary.contains("2주마다 금요일"))
    #expect(form.recurrenceSummary.contains("부터"))
    #expect(form.recurrenceSummary.hasSuffix("종료일 없음"))

    var endComponents = DateComponents()
    endComponents.calendar = .iso8601SeoulCompatible
    endComponents.timeZone = .current
    endComponents.year = 2026
    endComponents.month = 7
    endComponents.day = 31
    form.endDate = try #require(endComponents.date)
    form.hasEndDate = true

    #expect(form.recurrenceSummary.contains("2주마다 금요일"))
    #expect(form.recurrenceSummary.hasSuffix("2026년 7월 31일까지"))
    #expect(!form.timezoneDisplayName.isEmpty)
}

@Test func scheduleAndStudentFormsExposeReadinessForRequiredFields() {
    var schedule = ScheduleLessonFormState(roster: [])
    #expect(!schedule.canSubmit)
    schedule.selectedStudentId = PreviewData.minjiId
    #expect(schedule.canSubmit)
    schedule.title = "   "
    #expect(!schedule.canSubmit)

    var student = AddStudentFormState()
    #expect(!student.canSubmit)
    student.name = "김민지"
    student.profileCue = "짧은 시범이 효과적"
    student.primaryWeakPoint = "필인 뒤 첫 박"
    #expect(student.canSubmit)
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
        timezone: "America/New_York",
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
    #expect(input.timezone == "America/New_York")
}
