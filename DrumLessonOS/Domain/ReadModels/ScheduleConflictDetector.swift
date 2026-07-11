import Foundation

enum ScheduleConflictDetector {
    static func detect(
        query: ScheduleConflictQuery,
        occurrences: [LessonOccurrence],
        students: [Student]
    ) -> [ScheduleConflict] {
        let proposedRanges = query.slots.compactMap { slot -> Range<Date>? in
            guard let start = ISO8601DateFormatter.withFractions.date(from: slot.startsAt)
                ?? ISO8601DateFormatter.plain.date(from: slot.startsAt),
                  let end = ISO8601DateFormatter.withFractions.date(from: slot.endsAt)
                ?? ISO8601DateFormatter.plain.date(from: slot.endsAt),
                  start < end else { return nil }
            return start..<end
        }
        let names = Dictionary(uniqueKeysWithValues: students.map { ($0.id, $0.name) })

        return occurrences.compactMap { occurrence in
            guard occurrence.status == .scheduled,
                  occurrence.id != query.excludingOccurrenceId,
                  let start = ISO8601DateFormatter.withFractions.date(from: occurrence.startsAt)
                    ?? ISO8601DateFormatter.plain.date(from: occurrence.startsAt),
                  let end = ISO8601DateFormatter.withFractions.date(from: occurrence.endsAt)
                    ?? ISO8601DateFormatter.plain.date(from: occurrence.endsAt),
                  proposedRanges.contains(where: { $0.lowerBound < end && start < $0.upperBound }) else {
                return nil
            }
            return ScheduleConflict(
                occurrenceId: occurrence.id,
                studentName: names[occurrence.studentId] ?? "학생",
                startsAt: occurrence.startsAt,
                endsAt: occurrence.endsAt,
                timezone: occurrence.timezone
            )
        }
        .sorted { $0.startsAt < $1.startsAt }
    }
}
