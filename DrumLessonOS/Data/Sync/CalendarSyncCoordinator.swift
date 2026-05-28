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
        guard let startsAt = formatter.date(from: event.startsAt),
              let endsAt = formatter.date(from: event.endsAt) else {
            queue.enqueue(QueuedWrite(
                kind: .calendar,
                operation: "eventkit_invalid_date",
                recordId: event.id,
                payloadSummary: event.title,
                lastError: "Invalid occurrence date."
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
            timezone: TimeZone.current.identifier,
            currentFocus: nil,
            firstCheck: event.firstCheck
        )

        do {
            let result: CalendarWriteResult
            if existingEventIdentifier == nil {
                result = try await calendar.createLessonEvent(draft)
            } else {
                result = try await calendar.updateLessonEvent(draft, existingEventIdentifier: existingEventIdentifier)
            }
            try await schedules.updateNativeCalendarSync(.synced(occurrenceId: event.id, result: result))
        } catch {
            try? await schedules.updateNativeCalendarSync(.failed(
                occurrenceId: event.id,
                eventIdentifier: existingEventIdentifier,
                calendarIdentifier: nil,
                externalIdentifier: nil,
                error: error.localizedDescription
            ))
            queue.enqueue(QueuedWrite(
                kind: .calendar,
                operation: "eventkit_write",
                recordId: event.id,
                payloadSummary: event.title,
                lastError: error.localizedDescription
            ))
        }
    }
}

@MainActor
final class CalendarBackedScheduleRepository: ScheduleRepository {
    private let schedules: ScheduleRepository
    private let calendar: CalendarRepository
    private let queue: LocalWriteQueue
    private var failedCalendarWrites: [EntityID: PendingCalendarWrite] = [:]

    init(schedules: ScheduleRepository, calendar: CalendarRepository, queue: LocalWriteQueue) {
        self.schedules = schedules
        self.calendar = calendar
        self.queue = queue
    }

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        let occurrence = try await schedules.createOneOffOccurrence(input)
        return await writeToCalendar(occurrence, operation: .create)
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        let occurrences = try await schedules.createWeeklySchedule(input)
        var synced: [LessonOccurrence] = []
        for occurrence in occurrences {
            synced.append(await writeToCalendar(occurrence, operation: .create))
        }
        return synced
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        let occurrence = try await schedules.editOccurrence(input)
        return await writeToCalendar(occurrence, operation: .update)
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        let occurrence = try await schedules.cancelOccurrence(id: id)
        return await deleteCalendarEvent(for: occurrence)
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {
        guard let pending = failedCalendarWrites[occurrenceId] else {
            try await schedules.retryNativeCalendarSync(occurrenceId: occurrenceId)
            return
        }

        let retried: LessonOccurrence
        switch pending.operation {
        case .create, .update:
            retried = await writeToCalendar(pending.occurrence, operation: pending.operation, enqueueFailure: false)
        case .delete:
            retried = await deleteCalendarEvent(for: pending.occurrence, enqueueFailure: false)
        }

        guard retried.nativeCalendarSyncStatus == .synced else {
            throw RepositoryError(message: retried.nativeCalendarSyncError ?? "Calendar retry failed.")
        }
        failedCalendarWrites.removeValue(forKey: occurrenceId)
    }

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        try await schedules.updateNativeCalendarSync(input)
    }

    private func writeToCalendar(_ occurrence: LessonOccurrence, operation: CalendarWriteOperation, enqueueFailure: Bool = true) async -> LessonOccurrence {
        do {
            let draft = try makeDraft(from: occurrence)
            let result: CalendarWriteResult
            switch operation {
            case .create:
                result = try await calendar.createLessonEvent(draft)
            case .update:
                result = try await calendar.updateLessonEvent(draft, existingEventIdentifier: occurrence.nativeCalendarEventIdentifier)
            case .delete:
                throw RepositoryError(message: "Calendar delete uses the delete flow.")
            }
            try await schedules.updateNativeCalendarSync(.synced(occurrenceId: occurrence.id, result: result))
            failedCalendarWrites.removeValue(forKey: occurrence.id)
            return synced(occurrence, with: result)
        } catch {
            try? await schedules.updateNativeCalendarSync(.failed(
                occurrenceId: occurrence.id,
                eventIdentifier: occurrence.nativeCalendarEventIdentifier,
                calendarIdentifier: occurrence.nativeCalendarIdentifier,
                externalIdentifier: occurrence.nativeCalendarExternalIdentifier,
                error: error.localizedDescription
            ))
            if enqueueFailure {
                failedCalendarWrites[occurrence.id] = PendingCalendarWrite(occurrence: occurrence, operation: operation)
                queue.enqueue(QueuedWrite(
                    kind: .calendar,
                    operation: operation.queueName,
                    recordId: occurrence.id,
                    payloadSummary: occurrence.title,
                    lastError: error.localizedDescription
                ))
            }
            return failed(occurrence, error: error)
        }
    }

    private func deleteCalendarEvent(for occurrence: LessonOccurrence, enqueueFailure: Bool = true) async -> LessonOccurrence {
        guard let eventIdentifier = occurrence.nativeCalendarEventIdentifier else {
            let syncedAt = ISO8601DateFormatter.plain.string(from: Date())
            try? await schedules.updateNativeCalendarSync(NativeCalendarSyncUpdateInput(
                occurrenceId: occurrence.id,
                status: .synced,
                eventIdentifier: nil,
                calendarIdentifier: nil,
                externalIdentifier: nil,
                error: nil,
                syncedAt: syncedAt
            ))
            var synced = occurrence
            synced.nativeCalendarEventIdentifier = nil
            synced.nativeCalendarIdentifier = nil
            synced.nativeCalendarExternalIdentifier = nil
            synced.nativeCalendarSyncStatus = .synced
            synced.nativeCalendarSyncError = nil
            synced.nativeCalendarSyncedAt = syncedAt
            failedCalendarWrites.removeValue(forKey: occurrence.id)
            return synced
        }

        do {
            try await calendar.deleteLessonEvent(eventIdentifier: eventIdentifier)
            let syncedAt = ISO8601DateFormatter.plain.string(from: Date())
            try await schedules.updateNativeCalendarSync(NativeCalendarSyncUpdateInput(
                occurrenceId: occurrence.id,
                status: .synced,
                eventIdentifier: nil,
                calendarIdentifier: nil,
                externalIdentifier: nil,
                error: nil,
                syncedAt: syncedAt
            ))
            var synced = occurrence
            synced.nativeCalendarEventIdentifier = nil
            synced.nativeCalendarIdentifier = nil
            synced.nativeCalendarExternalIdentifier = nil
            synced.nativeCalendarSyncStatus = .synced
            synced.nativeCalendarSyncError = nil
            synced.nativeCalendarSyncedAt = syncedAt
            failedCalendarWrites.removeValue(forKey: occurrence.id)
            return synced
        } catch {
            try? await schedules.updateNativeCalendarSync(.failed(
                occurrenceId: occurrence.id,
                eventIdentifier: occurrence.nativeCalendarEventIdentifier,
                calendarIdentifier: occurrence.nativeCalendarIdentifier,
                externalIdentifier: occurrence.nativeCalendarExternalIdentifier,
                error: error.localizedDescription
            ))
            if enqueueFailure {
                failedCalendarWrites[occurrence.id] = PendingCalendarWrite(occurrence: occurrence, operation: .delete)
                queue.enqueue(QueuedWrite(
                    kind: .calendar,
                    operation: "eventkit_delete",
                    recordId: occurrence.id,
                    payloadSummary: occurrence.title,
                    lastError: error.localizedDescription
                ))
            }
            return failed(occurrence, error: error)
        }
    }

    private func makeDraft(from occurrence: LessonOccurrence) throws -> LessonCalendarEventDraft {
        let formatter = ISO8601DateFormatter.plain
        guard let startsAt = formatter.date(from: occurrence.startsAt),
              let endsAt = formatter.date(from: occurrence.endsAt) else {
            throw RepositoryError(message: "Invalid occurrence date.")
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
            firstCheck: "Scheduled lesson"
        )
    }

    private func synced(_ occurrence: LessonOccurrence, with result: CalendarWriteResult) -> LessonOccurrence {
        var synced = occurrence
        synced.nativeCalendarEventIdentifier = result.eventIdentifier
        synced.nativeCalendarIdentifier = result.calendarIdentifier
        synced.nativeCalendarExternalIdentifier = result.externalIdentifier
        synced.nativeCalendarSyncStatus = .synced
        synced.nativeCalendarSyncError = nil
        synced.nativeCalendarSyncedAt = ISO8601DateFormatter.plain.string(from: result.syncedAt)
        return synced
    }

    private func failed(_ occurrence: LessonOccurrence, error: Error) -> LessonOccurrence {
        var failed = occurrence
        failed.nativeCalendarSyncStatus = .failed
        failed.nativeCalendarSyncError = error.localizedDescription
        return failed
    }
}

private struct PendingCalendarWrite {
    var occurrence: LessonOccurrence
    var operation: CalendarWriteOperation
}

private enum CalendarWriteOperation {
    case create
    case update
    case delete

    var queueName: String {
        switch self {
        case .create: "eventkit_create"
        case .update: "eventkit_update"
        case .delete: "eventkit_delete"
        }
    }
}

private extension NativeCalendarSyncUpdateInput {
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
