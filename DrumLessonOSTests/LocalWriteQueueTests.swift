import Testing
@testable import DrumLessonOS

@MainActor
@Test func queueKeepsFailedWritesVisible() {
    let queue = LocalWriteQueue()
    let write = QueuedWrite(kind: .calendar, operation: "eventkit_write", payloadSummary: "김민지")

    queue.enqueue(write)
    queue.markAttempted(id: write.id, error: "Permission denied")

    #expect(queue.writes.count == 1)
    #expect(queue.writes[0].attemptCount == 1)
    #expect(queue.writes[0].lastError == "Permission denied")
}
