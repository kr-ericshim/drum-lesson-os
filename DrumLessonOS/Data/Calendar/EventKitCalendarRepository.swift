import EventKit
import Foundation

final class EventKitCalendarRepository: CalendarRepository {
    private let store: EKEventStore
    private let selectedCalendarKey = "DrumLessonOS.selectedCalendarIdentifier"

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    func permissionStatus() -> EventKitPermissionState {
        EventKitPermissionState(status: EKEventStore.authorizationStatus(for: .event))
    }

    func requestPermission() async throws -> EventKitPermissionState {
        if #available(macOS 14.0, *) {
            let granted = try await store.requestFullAccessToEvents()
            return granted ? .authorized : permissionStatus()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted ? .authorized : self.permissionStatus())
                    }
                }
            }
        }
    }

    func listWritableCalendars() async throws -> [WritableCalendar] {
        store.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .map { WritableCalendar(id: $0.calendarIdentifier, title: $0.title, sourceTitle: $0.source.title) }
    }

    func selectCalendar(_ calendar: WritableCalendar) async throws {
        UserDefaults.standard.set(calendar.id, forKey: selectedCalendarKey)
    }

    func selectedCalendar() -> WritableCalendar? {
        guard let id = UserDefaults.standard.string(forKey: selectedCalendarKey),
              let calendar = store.calendar(withIdentifier: id) else {
            return nil
        }
        return WritableCalendar(id: calendar.calendarIdentifier, title: calendar.title, sourceTitle: calendar.source.title)
    }

    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        guard let calendar = selectedEKCalendar() else {
            throw RepositoryError(message: "Choose a writable Apple Calendar first.")
        }
        let ekEvent = EKEvent(eventStore: store)
        EventKitLessonEventBuilder.configure(ekEvent, draft: event, calendar: calendar)
        try store.save(ekEvent, span: .thisEvent, commit: true)
        return result(for: ekEvent, calendar: calendar)
    }

    func updateLessonEvent(_ event: LessonCalendarEventDraft, existingEventIdentifier: String?) async throws -> CalendarWriteResult {
        guard let calendar = selectedEKCalendar() else {
            throw RepositoryError(message: "Choose a writable Apple Calendar first.")
        }
        let ekEvent = existingEventIdentifier.flatMap { store.event(withIdentifier: $0) } ?? EKEvent(eventStore: store)
        EventKitLessonEventBuilder.configure(ekEvent, draft: event, calendar: calendar)
        try store.save(ekEvent, span: .thisEvent, commit: true)
        return result(for: ekEvent, calendar: calendar)
    }

    func deleteLessonEvent(eventIdentifier: String) async throws {
        guard let event = store.event(withIdentifier: eventIdentifier) else {
            throw RepositoryError(message: "The Apple Calendar event is missing.")
        }
        try store.remove(event, span: .thisEvent, commit: true)
    }

    private func selectedEKCalendar() -> EKCalendar? {
        guard let id = UserDefaults.standard.string(forKey: selectedCalendarKey) else {
            return nil
        }
        return store.calendar(withIdentifier: id)
    }

    private func result(for event: EKEvent, calendar: EKCalendar) -> CalendarWriteResult {
        CalendarWriteResult(
            eventIdentifier: event.eventIdentifier,
            calendarIdentifier: calendar.calendarIdentifier,
            externalIdentifier: event.calendarItemExternalIdentifier,
            syncedAt: Date()
        )
    }
}

final class PreviewCalendarRepository: CalendarRepository {
    private var selected = WritableCalendar(id: "preview-calendar", title: "Teaching", sourceTitle: "iCloud")

    func permissionStatus() -> EventKitPermissionState { .authorized }
    func requestPermission() async throws -> EventKitPermissionState { .authorized }
    func listWritableCalendars() async throws -> [WritableCalendar] { [selected] }
    func selectCalendar(_ calendar: WritableCalendar) async throws { selected = calendar }
    func selectedCalendar() -> WritableCalendar? { selected }

    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        CalendarWriteResult(eventIdentifier: event.occurrenceId.uuidString, calendarIdentifier: selected.id, externalIdentifier: "preview-\(event.occurrenceId.uuidString)", syncedAt: Date())
    }

    func updateLessonEvent(_ event: LessonCalendarEventDraft, existingEventIdentifier: String?) async throws -> CalendarWriteResult {
        CalendarWriteResult(eventIdentifier: existingEventIdentifier ?? event.occurrenceId.uuidString, calendarIdentifier: selected.id, externalIdentifier: "preview-\(event.occurrenceId.uuidString)", syncedAt: Date())
    }

    func deleteLessonEvent(eventIdentifier: String) async throws {}
}
