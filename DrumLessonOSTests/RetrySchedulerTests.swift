import Testing
@testable import DrumLessonOS

@MainActor
@Test func retryRemovesSuccessfulWrites() async {
    let queue = LocalWriteQueue()
    queue.enqueue(QueuedWrite(kind: .supabase, operation: "native_create_student", payloadSummary: "김민지"))
    let scheduler = RetryScheduler(writeQueue: queue)

    await scheduler.retryNow { _ in }

    #expect(queue.writes.isEmpty)
}
