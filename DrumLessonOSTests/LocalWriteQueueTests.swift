import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func queueKeepsFailedWritesVisible() throws {
    let queue = LocalWriteQueue()
    let write = QueuedWrite(kind: .calendar, operation: "eventkit_write", payloadSummary: "김민지")

    try queue.enqueue(write)
    try queue.markAttempted(id: write.id, error: "Permission denied")

    #expect(queue.writes.count == 1)
    #expect(queue.writes[0].attemptCount == 1)
    #expect(queue.writes[0].lastError == "Permission denied")
}

@MainActor
@Test func queueDeduplicatesOccurrenceAndOperation() throws {
    let queue = LocalWriteQueue()
    let occurrenceId = UUID()

    let first = try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.create.rawValue,
        recordId: occurrenceId,
        payloadSummary: "첫 제목"
    ))
    let duplicate = try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.create.rawValue,
        recordId: occurrenceId,
        payloadSummary: "수정된 제목"
    ))

    #expect(queue.writes.count == 1)
    #expect(duplicate.id == first.id)
    #expect(queue.writes[0].payloadSummary == "수정된 제목")
}

@MainActor
@Test func durableQueueRestoresWriteAndMetadataStageAfterRelaunch() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-Queue-\(UUID().uuidString)", isDirectory: true)
    let url = directory.appendingPathComponent("writes.json")
    defer { try? FileManager.default.removeItem(at: directory) }

    let occurrenceId = UUID()
    let firstQueue = try LocalWriteQueue(storageURL: url)
    let write = try firstQueue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.create.rawValue,
        recordId: occurrenceId,
        payloadSummary: "김민지"
    ))
    let update = NativeCalendarSyncUpdateInput(
        occurrenceId: occurrenceId,
        status: .synced,
        eventIdentifier: "event-1",
        calendarIdentifier: "calendar-1",
        externalIdentifier: "external-1",
        error: nil,
        syncedAt: "2026-07-10T12:00:00Z"
    )
    try firstQueue.markEventKitCompleted(id: write.id, syncUpdate: update)

    let relaunchedQueue = try LocalWriteQueue(storageURL: url)

    #expect(relaunchedQueue.writes.count == 1)
    #expect(relaunchedQueue.writes[0].operation == CalendarQueueOperation.metadataUpdate.rawValue)
    #expect(relaunchedQueue.writes[0].syncUpdate == update)
}

@MainActor
@Test func queueConvertsMetadataStageToSingleDurableDelete() throws {
    let queue = LocalWriteQueue()
    let occurrenceId = UUID()
    let metadata = try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.metadataUpdate.rawValue,
        recordId: occurrenceId,
        payloadSummary: "김민지",
        syncUpdate: NativeCalendarSyncUpdateInput(
            occurrenceId: occurrenceId,
            status: .synced,
            eventIdentifier: "event-1",
            calendarIdentifier: "calendar-1",
            externalIdentifier: "external-1",
            error: nil,
            syncedAt: "2026-07-10T12:00:00Z"
        )
    ))
    _ = try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.delete.rawValue,
        recordId: occurrenceId,
        payloadSummary: "김민지"
    ))

    let converted = try queue.replaceWithCalendarOperation(id: metadata.id, operation: .delete)

    #expect(queue.writes == [converted])
    #expect(converted.operation == CalendarQueueOperation.delete.rawValue)
    #expect(converted.syncUpdate == nil)
}
