import EventKit
import Foundation

enum EventKitLessonEventBuilder {
    static func title(for draft: LessonCalendarEventDraft) -> String {
        draft.title ?? "Drum lesson - \(draft.studentName)"
    }

    static func notes(for draft: LessonCalendarEventDraft) -> String {
        [
            draft.currentFocus.map { "Current focus: \($0)" },
            "First check: \(draft.firstCheck)",
            "Student id: \(draft.studentId.uuidString)",
            "Drum Lesson OS occurrence: \(draft.occurrenceId.uuidString)"
        ]
        .compactMap(\.self)
        .joined(separator: "\n")
    }

    static func configure(_ event: EKEvent, draft: LessonCalendarEventDraft, calendar: EKCalendar) {
        event.calendar = calendar
        event.title = title(for: draft)
        event.startDate = draft.startsAt
        event.endDate = draft.endsAt
        event.timeZone = TimeZone(identifier: draft.timezone) ?? .current
        event.notes = notes(for: draft)
    }
}
