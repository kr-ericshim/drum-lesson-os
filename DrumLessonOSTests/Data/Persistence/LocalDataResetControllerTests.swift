import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func dataResetDeletesLinkedCalendarEventsThenClearsQueueAndLocalData() async throws {
    var scheduled = resetOccurrence(index: 1, status: .scheduled)
    var completed = resetOccurrence(index: 2, status: .completed)
    var canceled = resetOccurrence(index: 3, status: .canceled)
    scheduled.nativeCalendarEventIdentifier = "event-scheduled"
    completed.nativeCalendarEventIdentifier = "event-completed"
    canceled.nativeCalendarEventIdentifier = nil
    canceled.nativeCalendarExternalIdentifier = nil
    canceled.nativeCalendarSyncStatus = .failed

    let store = RecordingDataResetStore(occurrences: [canceled, completed, scheduled])
    let calendar = RecordingDataResetCalendar()
    let queue = LocalWriteQueue()
    let metadataIdentity = NativeCalendarSyncUpdateInput(
        occurrenceId: canceled.id,
        status: .synced,
        eventIdentifier: "event-canceled",
        calendarIdentifier: "calendar-1",
        externalIdentifier: "external-canceled",
        error: nil,
        syncedAt: "2026-07-11T00:00:00Z"
    )
    try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.metadataUpdate.rawValue,
        recordId: canceled.id,
        payloadSummary: canceled.title,
        syncUpdate: metadataIdentity
    ))

    let controller = LocalDataResetController(store: store, calendar: calendar, writeQueue: queue)
    try await controller.resetAllData()

    #expect(calendar.deletedOccurrenceIds == [scheduled.id, completed.id, canceled.id])
    #expect(calendar.deletedIdentities.last == CalendarEventIdentity(
        eventIdentifier: "event-canceled",
        calendarIdentifier: "calendar-1",
        externalIdentifier: "external-canceled"
    ))
    #expect(store.markedDeletedOccurrenceIds == [scheduled.id, completed.id, canceled.id])
    #expect(store.resetCallCount == 1)
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func dataResetPreservesLocalRecordsWhenCalendarDeletionFails() async throws {
    let first = resetOccurrence(index: 1, status: .scheduled)
    let second = resetOccurrence(index: 2, status: .completed)
    let store = RecordingDataResetStore(occurrences: [first, second])
    let calendar = RecordingDataResetCalendar()
    calendar.failingAttempt = 2
    let queue = LocalWriteQueue()
    for occurrence in [first, second] {
        try queue.enqueue(QueuedWrite(
            kind: .calendar,
            operation: CalendarQueueOperation.delete.rawValue,
            recordId: occurrence.id,
            payloadSummary: occurrence.title
        ))
    }
    let controller = LocalDataResetController(store: store, calendar: calendar, writeQueue: queue)

    await #expect(throws: RepositoryError.self) {
        try await controller.resetAllData()
    }

    #expect(store.resetCallCount == 0)
    #expect(store.markedDeletedOccurrenceIds == [first.id])
    #expect(queue.writes.map(\.recordId) == [second.id])
}

@MainActor
private final class RecordingDataResetStore: LocalDataResetStore {
    let occurrences: [LessonOccurrence]
    var markedDeletedOccurrenceIds: [EntityID] = []
    var resetCallCount = 0

    init(occurrences: [LessonOccurrence]) {
        self.occurrences = occurrences
    }

    func loadOccurrencesForDataReset() async throws -> [LessonOccurrence] {
        occurrences
    }

    func markCalendarEventDeletedForDataReset(occurrenceId: EntityID) async throws {
        markedDeletedOccurrenceIds.append(occurrenceId)
    }

    func resetLocalData() async throws {
        resetCallCount += 1
    }
}

@MainActor
private final class RecordingDataResetCalendar: CalendarRepository {
    var deletedOccurrenceIds: [EntityID] = []
    var deletedIdentities: [CalendarEventIdentity] = []
    var failingAttempt: Int?

    func permissionStatus() -> EventKitPermissionState { .authorized }
    func requestPermission() async throws -> EventKitPermissionState { .authorized }
    func listWritableCalendars() async throws -> [WritableCalendar] { [] }
    func selectCalendar(_ calendar: WritableCalendar) async throws {}
    func selectedCalendar() -> WritableCalendar? { nil }

    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        throw RepositoryError(message: "테스트에서 지원하지 않는 작업입니다.")
    }

    func updateLessonEvent(
        _ event: LessonCalendarEventDraft,
        existingIdentity: CalendarEventIdentity
    ) async throws -> CalendarWriteResult {
        throw RepositoryError(message: "테스트에서 지원하지 않는 작업입니다.")
    }

    func deleteLessonEvent(
        _ event: LessonCalendarEventDraft,
        existingIdentity: CalendarEventIdentity
    ) async throws {
        let attempt = deletedOccurrenceIds.count + 1
        if failingAttempt == attempt {
            throw RepositoryError(message: "Apple 캘린더 삭제 실패")
        }
        deletedOccurrenceIds.append(event.occurrenceId)
        deletedIdentities.append(existingIdentity)
    }
}

private func resetOccurrence(index: Int, status: LessonOccurrenceStatus) -> LessonOccurrence {
    LessonOccurrence(
        id: UUID(),
        instructorId: PreviewData.instructorId,
        studentId: PreviewData.minjiId,
        scheduleTemplateId: nil,
        startsAt: "2026-07-1\(index)T0\(index):00:00Z",
        endsAt: "2026-07-1\(index)T0\(index):50:00Z",
        timezone: "Asia/Seoul",
        status: status,
        title: "초기화 테스트 레슨 \(index)",
        nativeCalendarEventIdentifier: "event-\(index)",
        nativeCalendarIdentifier: "calendar-1",
        nativeCalendarExternalIdentifier: "external-\(index)",
        nativeCalendarSyncStatus: .synced,
        nativeCalendarSyncError: nil,
        nativeCalendarSyncedAt: "2026-07-11T00:00:00Z"
    )
}
