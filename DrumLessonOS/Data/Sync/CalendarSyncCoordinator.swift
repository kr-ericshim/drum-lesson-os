import Foundation

@MainActor
final class CalendarSyncCoordinator {
    private let calendar: CalendarRepository
    private let schedules: ScheduleRepository
    private let queue: LocalWriteQueue

    init(calendar: CalendarRepository, schedules: ScheduleRepository, queue: LocalWriteQueue) {
        self.calendar = calendar
        self.schedules = schedules
        self.queue = queue
    }

    func createOrUpdateEvent(for event: CalendarLessonEvent, existingEventIdentifier: String?) async {
        let formatter = ISO8601DateFormatter.plain
        guard let startsAt = ISO8601DateFormatter.withFractions.date(from: event.startsAt) ?? formatter.date(from: event.startsAt),
              let endsAt = ISO8601DateFormatter.withFractions.date(from: event.endsAt) ?? formatter.date(from: event.endsAt) else {
            _ = try? queue.enqueue(QueuedWrite(
                kind: .calendar,
                operation: CalendarQueueOperation.invalidDate.rawValue,
                recordId: event.id,
                payloadSummary: event.title,
                lastError: "일정 날짜를 확인할 수 없습니다."
            ))
            return
        }

        let draft = LessonCalendarEventDraft(
            occurrenceId: event.id,
            studentId: event.studentId,
            title: event.title,
            studentName: event.studentName,
            startsAt: startsAt,
            endsAt: endsAt,
            timezone: event.timezone,
            currentFocus: nil,
            firstCheck: event.firstCheck
        )
        let operation: CalendarQueueOperation = existingEventIdentifier == nil ? .create : .update

        do {
            let queued = try queue.enqueue(QueuedWrite(
                kind: .calendar,
                operation: operation.rawValue,
                recordId: event.id,
                payloadSummary: event.title
            ))
            let result: CalendarWriteResult
            switch operation {
            case .create:
                result = try await calendar.createLessonEvent(draft)
            case .update:
                result = try await calendar.updateLessonEvent(
                    draft,
                    existingIdentity: CalendarEventIdentity(
                        eventIdentifier: existingEventIdentifier,
                        calendarIdentifier: nil,
                        externalIdentifier: nil
                    )
                )
            default:
                return
            }
            let update = NativeCalendarSyncUpdateInput.synced(occurrenceId: event.id, result: result)
            try queue.markEventKitCompleted(id: queued.id, syncUpdate: update)
            try await schedules.updateNativeCalendarSync(update)
            try queue.remove(id: queued.id)
        } catch {
            if let queued = queue.writes(for: event.id).first {
                try? queue.markAttempted(id: queued.id, error: error.localizedDescription)
            }
            try? await schedules.updateNativeCalendarSync(.failed(
                occurrenceId: event.id,
                eventIdentifier: existingEventIdentifier,
                calendarIdentifier: nil,
                externalIdentifier: nil,
                error: error.localizedDescription
            ))
        }
    }
}

@MainActor
final class CalendarBackedScheduleRepository: ScheduleRepository {
    private let schedules: ScheduleRepository
    private let calendar: CalendarRepository
    private let queue: LocalWriteQueue

    init(schedules: ScheduleRepository, calendar: CalendarRepository, queue: LocalWriteQueue) {
        self.schedules = schedules
        self.calendar = calendar
        self.queue = queue
    }

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        let occurrence = try await schedules.createOneOffOccurrence(input)
        return await beginCalendarWrite(for: occurrence, operation: .create)
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        let occurrences = try await schedules.createWeeklySchedule(input)
        var results: [LessonOccurrence] = []
        for occurrence in occurrences {
            results.append(await beginCalendarWrite(for: occurrence, operation: .create))
        }
        return results
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        let occurrence = try await schedules.editOccurrence(input)
        return await beginCalendarWrite(for: occurrence, operation: operationForRetrying(occurrence))
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        let previous = try await schedules.loadOccurrence(id: id)
        let pendingWrites = queue.writes(for: id)
        let occurrence = try await schedules.cancelOccurrence(id: id)
        if shouldCompleteCancellationLocally(previous: previous, pendingWrites: pendingWrites) {
            return await beginMetadataCompletion(
                for: occurrence,
                update: .deleted(occurrenceId: occurrence.id)
            )
        }
        return await beginCalendarWrite(for: occurrence, operation: .delete)
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {
        var pendingWrites = queue.writes(for: occurrenceId)
        var loadedOccurrence: LessonOccurrence?
        if pendingWrites.isEmpty {
            let occurrence = try await schedules.loadOccurrence(id: occurrenceId)
            guard occurrence.nativeCalendarSyncStatus != .synced else { return }
            let queued: QueuedWrite
            if occurrence.status == .canceled,
               !hasStableCalendarIdentity(occurrence) {
                queued = try queue.enqueue(makeMetadataWrite(
                    for: occurrence,
                    update: .deleted(occurrenceId: occurrence.id)
                ))
            } else {
                let operation = operationForRetrying(occurrence)
                queued = try queue.enqueue(makeQueuedWrite(for: occurrence, operation: operation))
            }
            pendingWrites = [queued]
            loadedOccurrence = occurrence
        }

        for write in pendingWrites {
            guard queue.writes.contains(where: { $0.id == write.id }) else { continue }
            _ = try await execute(write, occurrence: loadedOccurrence)
            loadedOccurrence = nil
        }
    }

    func loadPendingNativeCalendarOccurrences() async throws -> [LessonOccurrence] {
        try await schedules.loadPendingNativeCalendarOccurrences()
    }

    func reconcilePendingNativeCalendarSync() async throws -> Int {
        let pending = try await schedules.loadPendingNativeCalendarOccurrences()
        for occurrence in pending {
            try? await retryNativeCalendarSync(occurrenceId: occurrence.id)
        }
        return pending.count
    }

    func loadOccurrence(id: EntityID) async throws -> LessonOccurrence {
        try await schedules.loadOccurrence(id: id)
    }

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        try await schedules.updateNativeCalendarSync(input)
    }

    private func beginCalendarWrite(
        for occurrence: LessonOccurrence,
        operation: CalendarQueueOperation
    ) async -> LessonOccurrence {
        let queued: QueuedWrite
        do {
            queued = try queue.enqueue(makeQueuedWrite(for: occurrence, operation: operation))
        } catch {
            try? await markScheduleFailed(occurrence, error: error)
            return failedOccurrence(from: occurrence, error: error)
        }
        do {
            return try await execute(queued, occurrence: occurrence)
        } catch {
            return failedOccurrence(
                from: occurrence,
                queuedWriteId: queued.id,
                error: error
            )
        }
    }

    private func beginMetadataCompletion(
        for occurrence: LessonOccurrence,
        update: NativeCalendarSyncUpdateInput
    ) async -> LessonOccurrence {
        let queued: QueuedWrite
        do {
            queued = try queue.enqueue(makeMetadataWrite(for: occurrence, update: update))
        } catch {
            try? await markScheduleFailed(occurrence, error: error)
            return failedOccurrence(from: occurrence, error: error)
        }

        do {
            return try await execute(queued, occurrence: occurrence)
        } catch {
            return failedOccurrence(from: occurrence, queuedWriteId: queued.id, error: error)
        }
    }

    private func execute(
        _ queued: QueuedWrite,
        occurrence suppliedOccurrence: LessonOccurrence? = nil
    ) async throws -> LessonOccurrence {
        let occurrence = if let suppliedOccurrence {
            suppliedOccurrence
        } else {
            try await schedules.loadOccurrence(id: queued.recordId ?? UUID())
        }

        if queued.operation == CalendarQueueOperation.metadataUpdate.rawValue {
            guard let update = queued.syncUpdate else {
                throw RepositoryError(message: "캘린더 완료 상태가 대기열에 없어 다시 처리할 수 없습니다.")
            }
            do {
                try await schedules.updateNativeCalendarSync(update)
                let updatedOccurrence = applying(update, to: occurrence)
                if occurrence.status == .canceled,
                   update.eventIdentifier != nil || update.externalIdentifier != nil {
                    let deleteWrite = try queue.replaceWithCalendarOperation(
                        id: queued.id,
                        operation: .delete
                    )
                    return try await execute(deleteWrite, occurrence: updatedOccurrence)
                }
                try queue.remove(id: queued.id)
                return updatedOccurrence
            } catch {
                try? queue.markAttempted(id: queued.id, error: error.localizedDescription)
                throw error
            }
        }

        let operation = normalizedOperation(for: queued, occurrence: occurrence)
        let draft: LessonCalendarEventDraft
        do {
            draft = try makeDraft(from: occurrence)
        } catch {
            try? queue.markAttempted(id: queued.id, error: error.localizedDescription)
            try? await markScheduleFailed(occurrence, error: error)
            throw error
        }

        let syncUpdate: NativeCalendarSyncUpdateInput
        let shouldRecoverExistingCreate = queued.attemptCount > 0
        do {
            try queue.markAttempted(id: queued.id, error: nil)
            switch operation {
            case .create:
                let result = if shouldRecoverExistingCreate {
                    try await calendar.recoverOrCreateLessonEvent(draft)
                } else {
                    try await calendar.createLessonEvent(draft)
                }
                syncUpdate = .synced(occurrenceId: occurrence.id, result: result)
            case .update:
                let result = try await calendar.updateLessonEvent(
                    draft,
                    existingIdentity: identity(for: occurrence)
                )
                syncUpdate = .synced(occurrenceId: occurrence.id, result: result)
            case .delete:
                try await calendar.deleteLessonEvent(
                    draft,
                    existingIdentity: identity(for: occurrence)
                )
                syncUpdate = .deleted(occurrenceId: occurrence.id)
            default:
                throw RepositoryError(message: "지원하지 않는 캘린더 대기 작업입니다.")
            }
        } catch {
            try? queue.markAttempted(id: queued.id, error: error.localizedDescription)
            try? await markScheduleFailed(occurrence, error: error)
            throw error
        }

        do {
            try queue.markEventKitCompleted(id: queued.id, syncUpdate: syncUpdate)
        } catch {
            // EventKit work is idempotent through the occurrence marker and stable identifiers.
            // Keeping the original durable operation is safer than claiming completion.
            try? queue.markAttempted(id: queued.id, error: error.localizedDescription)
            throw error
        }

        do {
            try await schedules.updateNativeCalendarSync(syncUpdate)
            try queue.remove(id: queued.id)
            return applying(syncUpdate, to: occurrence)
        } catch {
            try? queue.markAttempted(id: queued.id, error: error.localizedDescription)
            throw error
        }
    }

    private func makeQueuedWrite(
        for occurrence: LessonOccurrence,
        operation: CalendarQueueOperation
    ) -> QueuedWrite {
        QueuedWrite(
            kind: .calendar,
            operation: operation.rawValue,
            recordId: occurrence.id,
            payloadSummary: occurrence.title
        )
    }

    private func makeMetadataWrite(
        for occurrence: LessonOccurrence,
        update: NativeCalendarSyncUpdateInput
    ) -> QueuedWrite {
        QueuedWrite(
            kind: .calendar,
            operation: CalendarQueueOperation.metadataUpdate.rawValue,
            recordId: occurrence.id,
            payloadSummary: occurrence.title,
            syncUpdate: update
        )
    }

    private func normalizedOperation(
        for queued: QueuedWrite,
        occurrence: LessonOccurrence
    ) -> CalendarQueueOperation {
        if occurrence.status == .canceled {
            return .delete
        }
        guard let operation = CalendarQueueOperation(rawValue: queued.operation) else {
            return operationForRetrying(occurrence)
        }
        switch operation {
        case .legacyWrite, .invalidDate, .metadataUpdate:
            return operationForRetrying(occurrence)
        case .update where !hasStableCalendarIdentity(occurrence):
            return .create
        case .create, .update, .delete:
            return operation
        }
    }

    private func operationForRetrying(_ occurrence: LessonOccurrence) -> CalendarQueueOperation {
        if occurrence.status == .canceled {
            return .delete
        }
        if !hasStableCalendarIdentity(occurrence) {
            return .create
        }
        return .update
    }

    private func hasStableCalendarIdentity(_ occurrence: LessonOccurrence) -> Bool {
        occurrence.nativeCalendarEventIdentifier != nil ||
            occurrence.nativeCalendarExternalIdentifier != nil
    }

    private func shouldCompleteCancellationLocally(
        previous: LessonOccurrence,
        pendingWrites: [QueuedWrite]
    ) -> Bool {
        previous.nativeCalendarSyncStatus == .notConnected &&
            !hasStableCalendarIdentity(previous) &&
            pendingWrites.isEmpty
    }

    private func identity(for occurrence: LessonOccurrence) -> CalendarEventIdentity {
        CalendarEventIdentity(
            eventIdentifier: occurrence.nativeCalendarEventIdentifier,
            calendarIdentifier: occurrence.nativeCalendarIdentifier,
            externalIdentifier: occurrence.nativeCalendarExternalIdentifier
        )
    }

    private func makeDraft(from occurrence: LessonOccurrence) throws -> LessonCalendarEventDraft {
        let formatter = ISO8601DateFormatter.plain
        guard let startsAt = ISO8601DateFormatter.withFractions.date(from: occurrence.startsAt) ?? formatter.date(from: occurrence.startsAt),
              let endsAt = ISO8601DateFormatter.withFractions.date(from: occurrence.endsAt) ?? formatter.date(from: occurrence.endsAt) else {
            throw RepositoryError(message: "일정 날짜를 확인할 수 없습니다.")
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
            firstCheck: "예정된 레슨"
        )
    }

    private func markScheduleFailed(_ occurrence: LessonOccurrence, error: Error) async throws {
        try await schedules.updateNativeCalendarSync(.failed(
            occurrenceId: occurrence.id,
            eventIdentifier: occurrence.nativeCalendarEventIdentifier,
            calendarIdentifier: occurrence.nativeCalendarIdentifier,
            externalIdentifier: occurrence.nativeCalendarExternalIdentifier,
            error: error.localizedDescription
        ))
    }

    private func applying(
        _ update: NativeCalendarSyncUpdateInput,
        to occurrence: LessonOccurrence
    ) -> LessonOccurrence {
        var updated = occurrence
        updated.nativeCalendarEventIdentifier = update.eventIdentifier
        updated.nativeCalendarIdentifier = update.calendarIdentifier
        updated.nativeCalendarExternalIdentifier = update.externalIdentifier
        updated.nativeCalendarSyncStatus = update.status
        updated.nativeCalendarSyncError = update.error
        updated.nativeCalendarSyncedAt = update.syncedAt
        return updated
    }

    private func failedOccurrence(
        from occurrence: LessonOccurrence,
        queuedWriteId: UUID,
        error: Error
    ) -> LessonOccurrence {
        var failed = occurrence
        if let update = queue.writes.first(where: { $0.id == queuedWriteId })?.syncUpdate {
            failed = applying(update, to: failed)
        }
        failed.nativeCalendarSyncStatus = .failed
        failed.nativeCalendarSyncError = error.localizedDescription
        return failed
    }

    private func failedOccurrence(
        from occurrence: LessonOccurrence,
        error: Error
    ) -> LessonOccurrence {
        var failed = occurrence
        failed.nativeCalendarSyncStatus = .failed
        failed.nativeCalendarSyncError = error.localizedDescription
        return failed
    }
}

extension NativeCalendarSyncUpdateInput {
    static func synced(occurrenceId: EntityID, result: CalendarWriteResult) -> NativeCalendarSyncUpdateInput {
        NativeCalendarSyncUpdateInput(
            occurrenceId: occurrenceId,
            status: .synced,
            eventIdentifier: result.eventIdentifier,
            calendarIdentifier: result.calendarIdentifier,
            externalIdentifier: result.externalIdentifier,
            error: nil,
            syncedAt: ISO8601DateFormatter.plain.string(from: result.syncedAt)
        )
    }

    static func deleted(occurrenceId: EntityID) -> NativeCalendarSyncUpdateInput {
        NativeCalendarSyncUpdateInput(
            occurrenceId: occurrenceId,
            status: .synced,
            eventIdentifier: nil,
            calendarIdentifier: nil,
            externalIdentifier: nil,
            error: nil,
            syncedAt: ISO8601DateFormatter.plain.string(from: Date())
        )
    }

    static func failed(
        occurrenceId: EntityID,
        eventIdentifier: String?,
        calendarIdentifier: String?,
        externalIdentifier: String?,
        error: String
    ) -> NativeCalendarSyncUpdateInput {
        NativeCalendarSyncUpdateInput(
            occurrenceId: occurrenceId,
            status: .failed,
            eventIdentifier: eventIdentifier,
            calendarIdentifier: calendarIdentifier,
            externalIdentifier: externalIdentifier,
            error: error,
            syncedAt: nil
        )
    }
}
