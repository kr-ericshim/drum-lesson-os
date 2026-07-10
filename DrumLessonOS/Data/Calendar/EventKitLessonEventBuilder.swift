import EventKit
import Foundation

enum EventKitLessonEventBuilder {
    static func occurrenceMarker(for occurrenceId: EntityID) -> String {
        "드럼 레슨 OS 일정 ID: \(occurrenceId.uuidString)"
    }

    static func title(for draft: LessonCalendarEventDraft) -> String {
        draft.title ?? "드럼 레슨 - \(draft.studentName)"
    }

    static func notes(for draft: LessonCalendarEventDraft) -> String {
        [
            draft.currentFocus.map { "현재 초점: \($0)" },
            "첫 확인: \(draft.firstCheck)",
            "학생 ID: \(draft.studentId.uuidString)",
            occurrenceMarker(for: draft.occurrenceId)
        ]
        .compactMap(\.self)
        .joined(separator: "\n")
    }

    static func alarmOffset(reminderMinutes: Int?) -> TimeInterval? {
        guard let reminderMinutes, reminderMinutes > 0 else { return nil }
        return TimeInterval(-reminderMinutes * 60)
    }

    static func configure(
        _ event: EKEvent,
        draft: LessonCalendarEventDraft,
        calendar: EKCalendar,
        reminderMinutes: Int?,
        applyDefaultReminder: Bool
    ) {
        event.calendar = calendar
        event.title = title(for: draft)
        event.startDate = draft.startsAt
        event.endDate = draft.endsAt
        event.timeZone = TimeZone(identifier: draft.timezone) ?? .current
        event.notes = notes(for: draft)
        if applyDefaultReminder {
            event.alarms = alarmOffset(reminderMinutes: reminderMinutes).map { [EKAlarm(relativeOffset: $0)] }
        }
    }
}
