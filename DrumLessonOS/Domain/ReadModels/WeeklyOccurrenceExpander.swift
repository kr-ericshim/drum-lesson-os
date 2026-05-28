import Foundation

enum WeeklyOccurrenceExpander {
    static func expand(
        template: LessonScheduleTemplate,
        horizonStartDate: String,
        horizonWeeks: Int = 8,
        existingDateKeys: Set<String>
    ) -> [LessonOccurrence] {
        let interval = max(1, template.recurrenceInterval)
        let calendar = Calendar.iso8601SeoulCompatible
        let horizonStart = parseDate(horizonStartDate)
        let templateStart = parseDate(template.startsOn)
        let searchStart = max(horizonStart, templateStart)
        let horizonEnd = calendar.date(byAdding: .day, value: horizonWeeks * 7, to: horizonStart) ?? horizonStart
        let endsOn = template.endsOn.map(parseDate)
        var current = align(searchStart, toWeekday: template.recurrenceWeekday, calendar: calendar)
        var results: [LessonOccurrence] = []

        while current < horizonEnd {
            let dateKey = DateOnly.string(from: current, timeZone: TimeZone(secondsFromGMT: 0) ?? .current)

            if dateKey >= template.startsOn,
               endsOn.map({ current <= $0 }) ?? true,
               !existingDateKeys.contains(dateKey) {
                let startsAt = utcInstant(dateKey: dateKey, time: template.startTime, timezone: template.timezone)
                let startDate = ISO8601DateFormatter.plain.date(from: startsAt) ?? Date()
                let endDate = calendar.date(byAdding: .minute, value: template.defaultDurationMinutes, to: startDate) ?? startDate
                let endsAt = ISO8601DateFormatter.plain.string(from: endDate)

                results.append(LessonOccurrence(
                    id: UUID(),
                    instructorId: template.instructorId,
                    studentId: template.studentId,
                    scheduleTemplateId: template.id,
                    startsAt: startsAt,
                    endsAt: endsAt,
                    timezone: template.timezone,
                    status: .scheduled,
                    title: template.title,
                    nativeCalendarEventIdentifier: nil,
                    nativeCalendarIdentifier: nil,
                    nativeCalendarExternalIdentifier: nil,
                    nativeCalendarSyncStatus: .pending,
                    nativeCalendarSyncError: nil,
                    nativeCalendarSyncedAt: nil
                ))
            }

            guard let next = calendar.date(byAdding: .day, value: 7 * interval, to: current) else {
                break
            }
            current = next
        }

        return results
    }

    private static func parseDate(_ dateKey: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateKey) ?? Date(timeIntervalSince1970: 0)
    }

    private static func align(_ date: Date, toWeekday weekday: Int, calendar: Calendar) -> Date {
        let current = calendar.component(.weekday, from: date) - 1
        let delta = (weekday - current + 7) % 7
        return calendar.date(byAdding: .day, value: delta, to: date) ?? date
    }

    private static func utcInstant(dateKey: String, time: String, timezone: String) -> String {
        let parts = dateKey.split(separator: "-").compactMap { Int($0) }
        let timeParts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3, timeParts.count >= 2 else {
            return "\(dateKey)T00:00:00Z"
        }

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: timezone) ?? .current
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = timeParts[0]
        components.minute = timeParts[1]

        let date = components.date ?? Date()
        return ISO8601DateFormatter.plain.string(from: date)
    }
}
