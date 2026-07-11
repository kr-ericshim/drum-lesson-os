import Foundation

@MainActor
final class LocalDataBackupController: LocalDataBackupRepository {
    private let repository: LocalDataBackupRepository
    private let writeQueue: LocalWriteQueue

    init(repository: LocalDataBackupRepository, writeQueue: LocalWriteQueue) {
        self.repository = repository
        self.writeQueue = writeQueue
    }

    func makeBackupData() async throws -> Data {
        try await repository.makeBackupData()
    }

    func restoreBackup(from data: Data) async throws -> URL {
        let safetyBackupURL = try await repository.restoreBackup(from: data)
        try writeQueue.removeAll()
        return safetyBackupURL
    }
}
