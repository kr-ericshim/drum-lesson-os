import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func coordinatorQueuesInvalidCalendarDates() async {
    let queue = LocalWriteQueue()
    let coordinator = CalendarSyncCoordinator(
        calendar: PreviewCalendarRepository(),
        schedules: PreviewRepository(),
        queue: queue
    )
    let event = CalendarLessonEvent(
        id: UUID(),
        studentId: PreviewData.minjiId,
        studentName: "김민지",
        title: "Bad event",
        dateKey: "bad",
        timeLabel: "--",
        durationMinutes: 0,
        startsAt: "bad",
        endsAt: "bad",
        status: .scheduled,
        syncStatus: .pending,
        syncError: nil,
        firstCheck: "확인",
        watchFlags: []
    )

    await coordinator.createOrUpdateEvent(for: event, existingEventIdentifier: nil)

    #expect(queue.writes.first?.operation == "eventkit_invalid_date")
}

@MainActor
@Test func calendarBackedRepositoryCreatesSupabaseFirstThenEventKitAndMarksSynced() async throws {
    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.createOneOffOccurrence(sampleScheduleInput())

    #expect(schedules.createdInputs.count == 1)
    #expect(calendar.createdDrafts.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.first?.status == .synced)
    #expect(schedules.syncUpdates.first?.eventIdentifier == "event-\(occurrence.id)")
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryKeepsSupabaseCreateWhenEventKitFails() async throws {
    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    calendar.createError = RepositoryError(message: "Calendar denied")
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.createOneOffOccurrence(sampleScheduleInput())

    #expect(schedules.createdInputs.count == 1)
    #expect(occurrence.nativeCalendarSyncStatus == .failed)
    #expect(occurrence.nativeCalendarSyncError == "Calendar denied")
    #expect(schedules.syncUpdates.first?.status == .failed)
    #expect(queue.writes.first?.operation == "eventkit_create")
    #expect(queue.writes.first?.recordId == occurrence.id)
}

@MainActor
@Test func calendarBackedRepositoryRetriesQueuedEventKitFailure() async throws {
    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    calendar.createError = RepositoryError(message: "Calendar denied")
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.createOneOffOccurrence(sampleScheduleInput())
    calendar.createError = nil

    try await repository.retryNativeCalendarSync(occurrenceId: occurrence.id)

    #expect(calendar.createdDrafts.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.map(\.status) == [.failed, .synced])
}

@MainActor
@Test func calendarBackedRepositoryDeletesEventKitAfterCancelWhenIdentifierExists() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.nativeCalendarEventIdentifier = "event-123"
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.cancelOccurrence(id: schedules.nextOccurrence.id)

    #expect(schedules.canceledOccurrenceIds == [schedules.nextOccurrence.id])
    #expect(calendar.deletedEventIdentifiers == ["event-123"])
    #expect(schedules.syncUpdates.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.first?.status == .synced)
    #expect(schedules.syncUpdates.first?.eventIdentifier == nil)
}

private func sampleScheduleInput() -> ScheduleLessonInput {
    ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "김민지 lesson",
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    )
}

@MainActor
private final class RecordingScheduleRepository: ScheduleRepository {
    var nextOccurrence = sampleScheduleInput().makeOccurrence(instructorId: PreviewData.instructorId)
    var createdInputs: [ScheduleLessonInput] = []
    var editedInputs: [EditOccurrenceInput] = []
    var canceledOccurrenceIds: [EntityID] = []
    var retriedOccurrenceIds: [EntityID] = []
    var syncUpdates: [NativeCalendarSyncUpdateInput] = []

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        createdInputs.append(input)
        nextOccurrence = input.makeOccurrence(instructorId: PreviewData.instructorId)
        return nextOccurrence
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        []
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        editedInputs.append(input)
        nextOccurrence.startsAt = input.startsAt
        nextOccurrence.endsAt = input.endsAt
        nextOccurrence.timezone = input.timezone
        return nextOccurrence
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        canceledOccurrenceIds.append(id)
        nextOccurrence.status = .canceled
        return nextOccurrence
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {
        retriedOccurrenceIds.append(occurrenceId)
    }

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        syncUpdates.append(input)
    }
}

@MainActor
private final class RecordingCalendarRepository: CalendarRepository {
    var selected = WritableCalendar(id: "calendar-1", title: "Teaching", sourceTitle: "iCloud")
    var createError: Error?
    var createdDrafts: [LessonCalendarEventDraft] = []
    var updatedDrafts: [LessonCalendarEventDraft] = []
    var deletedEventIdentifiers: [String] = []

    func permissionStatus() -> EventKitPermissionState { .authorized }
    func requestPermission() async throws -> EventKitPermissionState { .authorized }
    func listWritableCalendars() async throws -> [WritableCalendar] { [selected] }
    func selectCalendar(_ calendar: WritableCalendar) async throws { selected = calendar }
    func selectedCalendar() -> WritableCalendar? { selected }

    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        if let createError { throw createError }
        createdDrafts.append(event)
        return CalendarWriteResult(eventIdentifier: "event-\(event.occurrenceId)", calendarIdentifier: selected.id, externalIdentifier: nil, syncedAt: Date())
    }

    func updateLessonEvent(_ event: LessonCalendarEventDraft, existingEventIdentifier: String?) async throws -> CalendarWriteResult {
        updatedDrafts.append(event)
        return CalendarWriteResult(eventIdentifier: existingEventIdentifier ?? "event-\(event.occurrenceId)", calendarIdentifier: selected.id, externalIdentifier: nil, syncedAt: Date())
    }

    func deleteLessonEvent(eventIdentifier: String) async throws {
        deletedEventIdentifiers.append(eventIdentifier)
    }
}
