import Foundation

enum ScheduleValidation {
    static func validate(_ input: ScheduleLessonInput) throws {
        try require(input.title, field: "title", max: 180)
        try require(input.timezone, field: "timezone", max: 80)
        guard input.durationMinutes >= 15, input.durationMinutes <= 240 else {
            throw ValidationError(field: "durationMinutes", message: "Lesson duration must be 15 to 240 minutes.")
        }
        guard ISO8601DateFormatter.withFractions.date(from: input.startsAt) ?? ISO8601DateFormatter.plain.date(from: input.startsAt) != nil else {
            throw ValidationError(field: "startsAt", message: "Use a valid start time.")
        }
    }

    static func validate(_ input: WeeklyScheduleInput) throws {
        try require(input.title, field: "title", max: 180)
        try require(input.startsOn, field: "startsOn", max: 10)
        guard input.recurrenceInterval >= 1, input.recurrenceInterval <= 12 else {
            throw ValidationError(field: "recurrenceInterval", message: "Weekly interval must be between 1 and 12.")
        }
        guard (0...6).contains(input.recurrenceWeekday) else {
            throw ValidationError(field: "recurrenceWeekday", message: "Weekday must be 0 through 6.")
        }
    }

    private static func require(_ value: String, field: String, max: Int) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw ValidationError(field: field, message: "\(field) is required.")
        }
        if trimmed.count > max {
            throw ValidationError(field: field, message: "\(field) must be \(max) characters or less.")
        }
    }
}

struct ScheduleLessonInput: Equatable {
    var studentId: EntityID
    var title: String
    var startsAt: String
    var endsAt: String
    var timezone: String
    var durationMinutes: Int

    func makeOccurrence(instructorId: EntityID) -> LessonOccurrence {
        LessonOccurrence(
            id: UUID(),
            instructorId: instructorId,
            studentId: studentId,
            scheduleTemplateId: nil,
            startsAt: startsAt,
            endsAt: endsAt,
            timezone: timezone,
            status: .scheduled,
            title: title,
            nativeCalendarEventIdentifier: nil,
            nativeCalendarIdentifier: nil,
            nativeCalendarExternalIdentifier: nil,
            nativeCalendarSyncStatus: .pending,
            nativeCalendarSyncError: nil,
            nativeCalendarSyncedAt: nil
        )
    }
}

struct WeeklyScheduleInput: Equatable {
    var studentId: EntityID
    var title: String
    var defaultDurationMinutes: Int
    var timezone: String
    var recurrenceInterval: Int
    var recurrenceWeekday: Int
    var startsOn: String
    var endsOn: String?
    var startTime: String

    func template(instructorId: EntityID) -> LessonScheduleTemplate {
        LessonScheduleTemplate(
            id: UUID(),
            instructorId: instructorId,
            studentId: studentId,
            title: title,
            defaultDurationMinutes: defaultDurationMinutes,
            timezone: timezone,
            recurrenceKind: "weekly",
            recurrenceInterval: recurrenceInterval,
            recurrenceWeekday: recurrenceWeekday,
            startsOn: startsOn,
            endsOn: endsOn,
            startTime: startTime,
            active: true
        )
    }
}

struct EditOccurrenceInput: Equatable {
    var occurrenceId: EntityID
    var startsAt: String
    var endsAt: String
    var timezone: String
}
