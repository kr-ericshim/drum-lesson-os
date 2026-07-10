import Testing
@testable import DrumLessonOS

@MainActor
@Test func retryRemovesSuccessfulWrites() async throws {
    let queue = LocalWriteQueue()
    try queue.enqueue(QueuedWrite(kind: .calendar, operation: "eventkit_write", payloadSummary: "김민지"))
    let scheduler = RetryScheduler(writeQueue: queue)

    await scheduler.retryNow { _ in }

    #expect(queue.writes.isEmpty)
}
