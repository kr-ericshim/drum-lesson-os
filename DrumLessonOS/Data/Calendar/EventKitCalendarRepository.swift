import EventKit
import Foundation

struct EventKitEventCandidate: Equatable {
    var eventIdentifier: String
    var calendarIdentifier: String
}

enum EventKitEventLocator {
    static func uniqueCandidateIndex(
        in candidates: [EventKitEventCandidate],
        preferredCalendarIdentifier: String?
    ) throws -> Int? {
        guard !candidates.isEmpty else { return nil }

        if let preferredCalendarIdentifier {
            let preferred = candidates.indices.filter {
                candidates[$0].calendarIdentifier == preferredCalendarIdentifier
            }
            if preferred.count == 1 {
                return preferred[0]
            }
            if preferred.count > 1 {
                throw RepositoryError(message: "같은 캘린더에서 일치하는 일정이 여러 개 발견되어 자동으로 처리할 수 없습니다.")
            }
        }

        guard candidates.count == 1 else {
            throw RepositoryError(message: "일치하는 Apple 캘린더 일정이 여러 개 발견되어 자동으로 처리할 수 없습니다.")
        }
        return candidates.startIndex
    }
}

enum EventKitRecoveryWindowPlanner {
    static func windows(
        from eventStart: Date,
        through eventEnd: Date,
        yearsBeforeAndAfter: Int = 10,
        chunkYears: Int = 3
    ) -> [DateInterval] {
        guard yearsBeforeAndAfter > 0, chunkYears > 0 else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard let lowerBound = calendar.date(byAdding: .year, value: -yearsBeforeAndAfter, to: eventStart),
              let upperBound = calendar.date(byAdding: .year, value: yearsBeforeAndAfter, to: eventEnd) else {
            return []
        }

        var windows: [DateInterval] = []
        var cursor = lowerBound
        while cursor < upperBound {
            guard let proposedEnd = calendar.date(byAdding: .year, value: chunkYears, to: cursor) else {
                break
            }
            let windowEnd = min(proposedEnd, upperBound)
            windows.append(DateInterval(start: cursor, end: windowEnd))
            cursor = windowEnd
        }
        return windows
    }
}

final class EventKitCalendarRepository: CalendarRepository {
    private struct LookupResult {
        var event: EKEvent?
        var externalIdentifierProvedMissing: Bool
    }

    private let store: EKEventStore
    private let reminderMinutes: () -> Int?
    private let selectedCalendarKey = "DrumLessonOS.selectedCalendarIdentifier"

    init(store: EKEventStore = EKEventStore(), reminderMinutes: @escaping () -> Int? = { nil }) {
        self.store = store
        self.reminderMinutes = reminderMinutes
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
                        let status = EventKitPermissionState(status: EKEventStore.authorizationStatus(for: .event))
                        continuation.resume(returning: granted ? .authorized : status)
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
        try saveLessonEvent(event, searchFullRecoveryWindow: false)
    }

    func recoverOrCreateLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        try saveLessonEvent(event, searchFullRecoveryWindow: true)
    }

    private func saveLessonEvent(
        _ event: LessonCalendarEventDraft,
        searchFullRecoveryWindow: Bool
    ) throws -> CalendarWriteResult {
        try requireReadableAccess()
        guard let selectedCalendar = selectedEKCalendar() else {
            throw RepositoryError(message: "먼저 쓸 수 있는 Apple 캘린더를 선택하세요.")
        }

        var existing = try eventMatchingOccurrenceMarker(
            for: event,
            preferredCalendarIdentifier: selectedCalendar.calendarIdentifier
        )
        if existing == nil, searchFullRecoveryWindow {
            existing = try eventMatchingOccurrenceMarkerAcrossRecoveryWindow(
                for: event,
                preferredCalendarIdentifier: selectedCalendar.calendarIdentifier
            )
        }
        if let existing {
            guard existing.calendar.allowsContentModifications else {
                throw RepositoryError(message: "기존 Apple 캘린더 일정을 수정할 권한이 없습니다.")
            }
            EventKitLessonEventBuilder.configure(
                existing,
                draft: event,
                calendar: existing.calendar,
                reminderMinutes: reminderMinutes(),
                applyDefaultReminder: false
            )
            try store.save(existing, span: .thisEvent, commit: true)
            return result(for: existing, calendar: existing.calendar)
        }

        let ekEvent = EKEvent(eventStore: store)
        EventKitLessonEventBuilder.configure(
            ekEvent,
            draft: event,
            calendar: selectedCalendar,
            reminderMinutes: reminderMinutes(),
            applyDefaultReminder: true
        )
        try store.save(ekEvent, span: .thisEvent, commit: true)
        return result(for: ekEvent, calendar: selectedCalendar)
    }

    func updateLessonEvent(
        _ event: LessonCalendarEventDraft,
        existingIdentity: CalendarEventIdentity
    ) async throws -> CalendarWriteResult {
        try requireReadableAccess()
        let lookup = try lookupEvent(for: event, identity: existingIdentity)
        let recovered: EKEvent?
        if lookup.event == nil {
            recovered = try eventMatchingOccurrenceMarkerAcrossRecoveryWindow(
                for: event,
                preferredCalendarIdentifier: existingIdentity.calendarIdentifier
            )
        } else {
            recovered = nil
        }
        guard let ekEvent = lookup.event ?? recovered else {
            throw RepositoryError(message: "기존 Apple 캘린더 일정을 안전하게 찾지 못했습니다. 중복 생성을 막기 위해 자동 생성하지 않았습니다.")
        }
        guard ekEvent.calendar.allowsContentModifications else {
            throw RepositoryError(message: "기존 Apple 캘린더 일정을 수정할 권한이 없습니다.")
        }
        EventKitLessonEventBuilder.configure(
            ekEvent,
            draft: event,
            calendar: ekEvent.calendar,
            reminderMinutes: reminderMinutes(),
            applyDefaultReminder: false
        )
        try store.save(ekEvent, span: .thisEvent, commit: true)
        return result(for: ekEvent, calendar: ekEvent.calendar)
    }

    func deleteLessonEvent(
        _ event: LessonCalendarEventDraft,
        existingIdentity: CalendarEventIdentity
    ) async throws {
        try requireReadableAccess()
        let lookup = try lookupEvent(for: event, identity: existingIdentity)
        if let ekEvent = lookup.event {
            try store.remove(ekEvent, span: .thisEvent, commit: true)
            return
        }

        if let recovered = try eventMatchingOccurrenceMarkerAcrossRecoveryWindow(
            for: event,
            preferredCalendarIdentifier: existingIdentity.calendarIdentifier
        ) {
            try store.remove(recovered, span: .thisEvent, commit: true)
            return
        }

        let hasStableIdentity = existingIdentity.eventIdentifier != nil ||
            existingIdentity.externalIdentifier != nil
        if !hasStableIdentity {
            return
        }

        guard lookup.externalIdentifierProvedMissing else {
            throw RepositoryError(message: "삭제할 Apple 캘린더 일정을 안전하게 식별하지 못했습니다. 다시 시도할 수 있도록 대기열에 유지합니다.")
        }
    }

    private func lookupEvent(
        for draft: LessonCalendarEventDraft,
        identity: CalendarEventIdentity
    ) throws -> LookupResult {
        if let eventIdentifier = identity.eventIdentifier,
           let event = store.event(withIdentifier: eventIdentifier) {
            return LookupResult(event: event, externalIdentifierProvedMissing: false)
        }

        var externalIdentifierProvedMissing = false
        if let externalIdentifier = identity.externalIdentifier {
            let externalMatches = store.calendarItems(withExternalIdentifier: externalIdentifier)
                .compactMap { $0 as? EKEvent }
            if externalMatches.isEmpty {
                externalIdentifierProvedMissing = true
            } else if let event = try selectEvent(
                from: externalMatches,
                occurrenceId: draft.occurrenceId,
                preferredCalendarIdentifier: identity.calendarIdentifier
            ) {
                return LookupResult(event: event, externalIdentifierProvedMissing: false)
            }
        }

        if let event = try eventMatchingOccurrenceMarker(
            for: draft,
            preferredCalendarIdentifier: identity.calendarIdentifier
        ) {
            return LookupResult(event: event, externalIdentifierProvedMissing: externalIdentifierProvedMissing)
        }

        return LookupResult(event: nil, externalIdentifierProvedMissing: externalIdentifierProvedMissing)
    }

    private func eventMatchingOccurrenceMarker(
        for draft: LessonCalendarEventDraft,
        preferredCalendarIdentifier: String?
    ) throws -> EKEvent? {
        let searchPadding: TimeInterval = 24 * 60 * 60
        let predicate = store.predicateForEvents(
            withStart: draft.startsAt.addingTimeInterval(-searchPadding),
            end: draft.endsAt.addingTimeInterval(searchPadding),
            calendars: nil
        )
        let marker = EventKitLessonEventBuilder.occurrenceMarker(for: draft.occurrenceId)
        let matches = store.events(matching: predicate).filter { event in
            event.notes?.split(separator: "\n").contains(Substring(marker)) == true
        }
        return try selectEvent(
            from: matches,
            occurrenceId: draft.occurrenceId,
            preferredCalendarIdentifier: preferredCalendarIdentifier
        )
    }

    private func eventMatchingOccurrenceMarkerAcrossRecoveryWindow(
        for draft: LessonCalendarEventDraft,
        preferredCalendarIdentifier: String?
    ) throws -> EKEvent? {
        let marker = EventKitLessonEventBuilder.occurrenceMarker(for: draft.occurrenceId)
        var matchesByIdentifier: [String: EKEvent] = [:]
        for window in EventKitRecoveryWindowPlanner.windows(
            from: draft.startsAt,
            through: draft.endsAt
        ) {
            let predicate = store.predicateForEvents(
                withStart: window.start,
                end: window.end,
                calendars: nil
            )
            for event in store.events(matching: predicate) where
                event.notes?.split(separator: "\n").contains(Substring(marker)) == true {
                let identifier = event.eventIdentifier ?? event.calendarItemIdentifier
                matchesByIdentifier[identifier] = event
            }
        }
        return try selectEvent(
            from: Array(matchesByIdentifier.values),
            occurrenceId: draft.occurrenceId,
            preferredCalendarIdentifier: preferredCalendarIdentifier
        )
    }

    private func selectEvent(
        from events: [EKEvent],
        occurrenceId: EntityID,
        preferredCalendarIdentifier: String?
    ) throws -> EKEvent? {
        let marker = EventKitLessonEventBuilder.occurrenceMarker(for: occurrenceId)
        let markedEvents = events.filter {
            $0.notes?.split(separator: "\n").contains(Substring(marker)) == true
        }
        let candidates = markedEvents.isEmpty ? events : markedEvents
        let index = try EventKitEventLocator.uniqueCandidateIndex(
            in: candidates.map {
                EventKitEventCandidate(
                    eventIdentifier: $0.eventIdentifier,
                    calendarIdentifier: $0.calendar.calendarIdentifier
                )
            },
            preferredCalendarIdentifier: preferredCalendarIdentifier
        )
        return index.map { candidates[$0] }
    }

    private func requireReadableAccess() throws {
        guard permissionStatus() == .authorized else {
            throw RepositoryError(message: "Apple 캘린더 전체 접근 권한이 필요합니다.")
        }
    }

    private func selectedEKCalendar() -> EKCalendar? {
        guard let id = UserDefaults.standard.string(forKey: selectedCalendarKey),
              let calendar = store.calendar(withIdentifier: id),
              calendar.allowsContentModifications else {
            return nil
        }
        return calendar
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
    private var selected = WritableCalendar(id: "preview-calendar", title: "수업", sourceTitle: "iCloud")

    func permissionStatus() -> EventKitPermissionState { .authorized }
    func requestPermission() async throws -> EventKitPermissionState { .authorized }
    func listWritableCalendars() async throws -> [WritableCalendar] { [selected] }
    func selectCalendar(_ calendar: WritableCalendar) async throws { selected = calendar }
    func selectedCalendar() -> WritableCalendar? { selected }

    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        CalendarWriteResult(eventIdentifier: event.occurrenceId.uuidString, calendarIdentifier: selected.id, externalIdentifier: "preview-\(event.occurrenceId.uuidString)", syncedAt: Date())
    }

    func updateLessonEvent(_ event: LessonCalendarEventDraft, existingIdentity: CalendarEventIdentity) async throws -> CalendarWriteResult {
        CalendarWriteResult(eventIdentifier: existingIdentity.eventIdentifier ?? event.occurrenceId.uuidString, calendarIdentifier: selected.id, externalIdentifier: existingIdentity.externalIdentifier ?? "preview-\(event.occurrenceId.uuidString)", syncedAt: Date())
    }

    func deleteLessonEvent(_ event: LessonCalendarEventDraft, existingIdentity: CalendarEventIdentity) async throws {}
}
