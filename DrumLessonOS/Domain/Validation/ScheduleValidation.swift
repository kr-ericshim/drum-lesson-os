import Foundation

enum ScheduleValidation {
    static func validate(_ input: ScheduleLessonInput) throws {
        try require(input.title, field: "title", max: 180)
        try validateTimeZone(input.timezone)
        let startsAt = try requireInstant(input.startsAt, field: "startsAt")
        let endsAt = try requireInstant(input.endsAt, field: "endsAt")
        try validateDuration(startsAt: startsAt, endsAt: endsAt, declaredMinutes: input.durationMinutes)
    }

    static func validate(_ input: WeeklyScheduleInput) throws {
        try require(input.title, field: "title", max: 180)
        try validateTimeZone(input.timezone)
        let startsOn = try requireDate(input.startsOn, field: "startsOn")
        let endsOn = try input.endsOn.map { try requireDate($0, field: "endsOn") }
        if let endsOn {
            guard endsOn >= startsOn else {
                throw ValidationError(field: "endsOn", message: "반복 종료일은 시작일과 같거나 이후여야 합니다.")
            }
        }
        try requireTime(input.startTime)
        guard input.defaultDurationMinutes >= 15, input.defaultDurationMinutes <= 240 else {
            throw ValidationError(field: "defaultDurationMinutes", message: "레슨 길이는 15분에서 240분 사이여야 합니다.")
        }
        guard input.recurrenceInterval >= 1, input.recurrenceInterval <= 12 else {
            throw ValidationError(field: "recurrenceInterval", message: "반복 간격은 1주에서 12주 사이여야 합니다.")
        }
        guard (0...6).contains(input.recurrenceWeekday) else {
            throw ValidationError(field: "recurrenceWeekday", message: "요일 값을 다시 확인하세요.")
        }
        if let endsOn {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
            let startWeekday = calendar.component(.weekday, from: startsOn) - 1
            let daysUntilFirstOccurrence = (input.recurrenceWeekday - startWeekday + 7) % 7
            let firstOccurrence = calendar.date(
                byAdding: .day,
                value: daysUntilFirstOccurrence,
                to: startsOn
            ) ?? startsOn
            guard firstOccurrence <= endsOn else {
                throw ValidationError(field: "endsOn", message: "반복 종료일 안에 생성되는 첫 레슨이 없습니다.")
            }
        }
    }

    static func validate(_ input: EditOccurrenceInput) throws {
        try validateTimeZone(input.timezone)
        let startsAt = try requireInstant(input.startsAt, field: "startsAt")
        let endsAt = try requireInstant(input.endsAt, field: "endsAt")
        try validateDuration(startsAt: startsAt, endsAt: endsAt, declaredMinutes: nil)
    }

    private static func validateTimeZone(_ value: String) throws {
        try require(value, field: "timezone", max: 80)
        guard TimeZone(identifier: value) != nil else {
            throw ValidationError(field: "timezone", message: "올바른 시간대를 선택하세요.")
        }
    }

    private static func requireInstant(_ value: String, field: String) throws -> Date {
        guard let date = ISO8601DateFormatter.withFractions.date(from: value) ?? ISO8601DateFormatter.plain.date(from: value) else {
            let label = field == "startsAt" ? "시작" : "종료"
            throw ValidationError(field: field, message: "올바른 \(label) 시간을 입력하세요.")
        }
        return date
    }

    private static func validateDuration(startsAt: Date, endsAt: Date, declaredMinutes: Int?) throws {
        let seconds = endsAt.timeIntervalSince(startsAt)
        guard seconds >= 15 * 60, seconds <= 240 * 60 else {
            throw ValidationError(field: "endsAt", message: "종료 시간은 시작 시간보다 15분에서 240분 뒤여야 합니다.")
        }
        if let declaredMinutes {
            guard (15...240).contains(declaredMinutes) else {
                throw ValidationError(field: "durationMinutes", message: "레슨 길이는 15분에서 240분 사이여야 합니다.")
            }
            guard abs(seconds - Double(declaredMinutes * 60)) < 1 else {
                throw ValidationError(field: "durationMinutes", message: "레슨 길이와 시작·종료 시간이 일치하지 않습니다.")
            }
        }
    }

    private static func requireDate(_ value: String, field: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard value.count == 10, let date = formatter.date(from: value) else {
            throw ValidationError(field: field, message: "날짜는 YYYY-MM-DD 형식으로 입력하세요.")
        }
        return date
    }

    private static func requireTime(_ value: String) throws {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        let validShape = (parts.count == 2 || parts.count == 3) && parts.allSatisfy { part in
            part.count == 2 && part.allSatisfy(\.isNumber)
        }
        guard validShape,
              let hour = Int(parts[0]), (0...23).contains(hour),
              let minute = Int(parts[1]), (0...59).contains(minute),
              parts.count == 2 || (Int(parts[2]).map { (0...59).contains($0) } ?? false) else {
            throw ValidationError(field: "startTime", message: "시작 시각은 HH:mm 또는 HH:mm:ss 형식으로 입력하세요.")
        }
    }

    private static func require(_ value: String, field: String, max: Int) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw ValidationError(field: field, message: "\(fieldLabel(field))을(를) 입력하세요.")
        }
        if trimmed.count > max {
            throw ValidationError(field: field, message: "\(fieldLabel(field))은(는) \(max)자 이내로 입력하세요.")
        }
    }

    private static func fieldLabel(_ field: String) -> String {
        switch field {
        case "title": "제목"
        case "timezone": "시간대"
        case "startsOn": "시작일"
        case "endsOn": "종료일"
        default: field
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
