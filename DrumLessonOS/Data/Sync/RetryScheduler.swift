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
                try writeQueue.remove(id: write.id)
            } catch {
                try? writeQueue.markAttempted(id: write.id, error: error.localizedDescription)
            }
        }
    }
}
