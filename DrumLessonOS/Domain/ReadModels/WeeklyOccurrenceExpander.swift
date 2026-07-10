import Foundation

enum WeeklyOccurrenceExpander {
    static func expand(
        template: LessonScheduleTemplate,
        horizonStartDate: String,
        horizonWeeks: Int = 8,
        existingOccurrenceKeys: Set<String>
    ) -> [LessonOccurrence] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard horizonWeeks > 0,
              let horizonStart = parseDate(horizonStartDate),
              let templateStart = parseDate(template.startsOn) else {
            return []
        }

        let intervalDays = max(1, template.recurrenceInterval) * 7
        let horizonEnd = calendar.date(byAdding: .day, value: horizonWeeks * 7, to: horizonStart) ?? horizonStart
        let endsOn = template.endsOn.flatMap(parseDate)
        var current = align(templateStart, toWeekday: template.recurrenceWeekday, calendar: calendar)
        var results: [LessonOccurrence] = []

        while current < horizonStart {
            guard let next = calendar.date(byAdding: .day, value: intervalDays, to: current) else {
                return results
            }
            current = next
        }

        while current < horizonEnd {
            let dateKey = DateOnly.string(from: current, timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
            let occurrenceKey = occurrenceKey(templateId: template.id, dateKey: dateKey)

            if dateKey >= template.startsOn,
               endsOn.map({ current <= $0 }) ?? true,
               !existingOccurrenceKeys.contains(occurrenceKey),
               let startsAt = utcInstant(dateKey: dateKey, time: template.startTime, timezone: template.timezone),
               let startDate = ISO8601DateFormatter.plain.date(from: startsAt) {
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
                    nativeCalendarSyncedAt: nil,
                    recurrenceSlotDate: dateKey
                ))
            }

            guard let next = calendar.date(byAdding: .day, value: intervalDays, to: current) else {
                break
            }
            current = next
        }

        return results
    }

    static func occurrenceKey(templateId: EntityID, dateKey: String) -> String {
        "\(templateId.uuidString.lowercased())|\(dateKey)"
    }

    static func expand(
        template: LessonScheduleTemplate,
        horizonStartDate: String,
        horizonWeeks: Int = 8,
        existingDateKeys: Set<String>
    ) -> [LessonOccurrence] {
        expand(
            template: template,
            horizonStartDate: horizonStartDate,
            horizonWeeks: horizonWeeks,
            existingOccurrenceKeys: Set(existingDateKeys.map {
                occurrenceKey(templateId: template.id, dateKey: $0)
            })
        )
    }

    private static func parseDate(_ dateKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard dateKey.count == 10 else { return nil }
        return formatter.date(from: dateKey)
    }

    private static func align(_ date: Date, toWeekday weekday: Int, calendar: Calendar) -> Date {
        let current = calendar.component(.weekday, from: date) - 1
        let delta = (weekday - current + 7) % 7
        return calendar.date(byAdding: .day, value: delta, to: date) ?? date
    }

    private static func utcInstant(dateKey: String, time: String, timezone: String) -> String? {
        let parts = dateKey.split(separator: "-").compactMap { Int($0) }
        let timeParts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3,
              timeParts.count >= 2,
              let timeZone = TimeZone(identifier: timezone) else {
            return nil
        }

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = timeParts[0]
        components.minute = timeParts[1]

        guard let date = components.date else { return nil }
        return ISO8601DateFormatter.plain.string(from: date)
    }
}
