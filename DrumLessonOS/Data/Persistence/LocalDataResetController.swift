import Foundation

@MainActor
protocol LocalDataResetStore {
    func loadOccurrencesForDataReset() async throws -> [LessonOccurrence]
    func markCalendarEventDeletedForDataReset(occurrenceId: EntityID) async throws
    func resetLocalData() async throws
}

@MainActor
final class LocalDataResetController: LocalDataResetRepository {
    private let store: LocalDataResetStore
    private let calendar: CalendarRepository
    private let writeQueue: LocalWriteQueue

    init(
        store: LocalDataResetStore,
        calendar: CalendarRepository,
        writeQueue: LocalWriteQueue
    ) {
        self.store = store
        self.calendar = calendar
        self.writeQueue = writeQueue
    }

    func resetAllData() async throws {
        let loadedOccurrences = try await store.loadOccurrencesForDataReset()
        let occurrences = loadedOccurrences.sorted {
            if $0.startsAt == $1.startsAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.startsAt < $1.startsAt
        }

        for occurrence in occurrences {
            let pendingWrites = writeQueue.writes(for: occurrence.id)
            if eventKitDeletionAlreadyCompleted(in: pendingWrites) {
                try writeQueue.removeAll(for: occurrence.id)
                try await store.markCalendarEventDeletedForDataReset(occurrenceId: occurrence.id)
                continue
            }

            let identity = calendarIdentity(for: occurrence, pendingWrites: pendingWrites)
            guard shouldDeleteCalendarEvent(
                for: occurrence,
                identity: identity,
                pendingWrites: pendingWrites
            ) else { continue }

            try await calendar.deleteLessonEventForDataReset(
                makeDraft(from: occurrence),
                existingIdentity: identity
            )
            try writeQueue.removeAll(for: occurrence.id)
            try await store.markCalendarEventDeletedForDataReset(occurrenceId: occurrence.id)
        }

        try writeQueue.removeAll()
        try await store.resetLocalData()
    }

    private func eventKitDeletionAlreadyCompleted(in writes: [QueuedWrite]) -> Bool {
        writes.contains { write in
            guard write.operation == CalendarQueueOperation.metadataUpdate.rawValue,
                  let update = write.syncUpdate else { return false }
            return update.status == .synced &&
                update.eventIdentifier == nil &&
                update.externalIdentifier == nil
        }
    }

    private func calendarIdentity(
        for occurrence: LessonOccurrence,
        pendingWrites: [QueuedWrite]
    ) -> CalendarEventIdentity {
        let pendingUpdate = pendingWrites
            .filter { $0.operation == CalendarQueueOperation.metadataUpdate.rawValue }
            .compactMap(\.syncUpdate)
            .last

        return CalendarEventIdentity(
            eventIdentifier: pendingUpdate?.eventIdentifier ?? occurrence.nativeCalendarEventIdentifier,
            calendarIdentifier: pendingUpdate?.calendarIdentifier ?? occurrence.nativeCalendarIdentifier,
            externalIdentifier: pendingUpdate?.externalIdentifier ?? occurrence.nativeCalendarExternalIdentifier
        )
    }

    private func shouldDeleteCalendarEvent(
        for occurrence: LessonOccurrence,
        identity: CalendarEventIdentity,
        pendingWrites: [QueuedWrite]
    ) -> Bool {
        let hasStableIdentity = identity.eventIdentifier != nil || identity.externalIdentifier != nil
        if hasStableIdentity { return true }

        let actionableWrites = pendingWrites.contains {
            $0.operation != CalendarQueueOperation.invalidDate.rawValue
        }
        if actionableWrites { return true }

        return occurrence.nativeCalendarSyncStatus == .pending ||
            occurrence.nativeCalendarSyncStatus == .failed
    }

    private func makeDraft(from occurrence: LessonOccurrence) throws -> LessonCalendarEventDraft {
        let formatter = ISO8601DateFormatter.plain
        guard let startsAt = ISO8601DateFormatter.withFractions.date(from: occurrence.startsAt) ?? formatter.date(from: occurrence.startsAt),
              let endsAt = ISO8601DateFormatter.withFractions.date(from: occurrence.endsAt) ?? formatter.date(from: occurrence.endsAt) else {
            throw RepositoryError(message: "Apple 캘린더에서 삭제할 레슨의 날짜를 확인할 수 없습니다.")
        }

        return LessonCalendarEventDraft(
            occurrenceId: occurrence.id,
            studentId: occurrence.studentId,
            title: occurrence.title,
            studentName: occurrence.title,
            startsAt: startsAt,
            endsAt: endsAt,
            timezone: occurrence.timezone,
            currentFocus: nil,
            firstCheck: "데이터 초기화"
        )
    }
}
