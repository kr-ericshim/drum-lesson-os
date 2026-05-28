import Foundation

@MainActor
final class RetryScheduler {
    private let writeQueue: LocalWriteQueue

    init(writeQueue: LocalWriteQueue) {
        self.writeQueue = writeQueue
    }

    func retryNow(handler: (QueuedWrite) async throws -> Void) async {
        for write in writeQueue.writes {
            do {
                try await handler(write)
                writeQueue.remove(id: write.id)
            } catch {
                writeQueue.markAttempted(id: write.id, error: error.localizedDescription)
            }
        }
    }
}
