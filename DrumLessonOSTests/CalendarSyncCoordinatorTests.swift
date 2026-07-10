import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func coordinatorQueuesInvalidCalendarDates() async {
    let queue = LocalWriteQueue()
    let coordinator = CalendarSyncCoordinator(
        calendar: PreviewCalendarRepository(),
        schedules: PreviewRepository(),
        queue: queue
    )
    let event = CalendarLessonEvent(
        id: UUID(),
        studentId: PreviewData.minjiId,
        studentName: "김민지",
        title: "Bad event",
        dateKey: "bad",
        timeLabel: "--",
        durationMinutes: 0,
        startsAt: "bad",
        endsAt: "bad",
        timezone: "Asia/Seoul",
        status: .scheduled,
        syncStatus: .pending,
        syncError: nil,
        firstCheck: "확인",
        watchFlags: []
    )

    await coordinator.createOrUpdateEvent(for: event, existingEventIdentifier: nil)

    #expect(queue.writes.first?.operation == "eventkit_invalid_date")
}

@MainActor
@Test func calendarBackedRepositoryCreatesLocalOccurrenceThenEventKitAndMarksSynced() async throws {
    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )
    calendar.onCreate = { occurrenceId in
        #expect(queue.writes.contains {
            $0.recordId == occurrenceId && $0.operation == CalendarQueueOperation.create.rawValue
        })
    }

    let occurrence = try await repository.createOneOffOccurrence(sampleScheduleInput())

    #expect(schedules.createdInputs.count == 1)
    #expect(calendar.createdDrafts.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.first?.status == .synced)
    #expect(schedules.syncUpdates.first?.eventIdentifier == "event-\(occurrence.id)")
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryKeepsLocalCreateWhenEventKitFails() async throws {
    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    calendar.createError = RepositoryError(message: "Calendar denied")
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.createOneOffOccurrence(sampleScheduleInput())

    #expect(schedules.createdInputs.count == 1)
    #expect(occurrence.nativeCalendarSyncStatus == .failed)
    #expect(occurrence.nativeCalendarSyncError == "Calendar denied")
    #expect(schedules.syncUpdates.first?.status == .failed)
    #expect(queue.writes.first?.operation == "eventkit_create")
    #expect(queue.writes.first?.recordId == occurrence.id)
}

@MainActor
@Test func calendarBackedRepositoryRetriesQueuedEventKitFailure() async throws {
    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    calendar.createError = RepositoryError(message: "Calendar denied")
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.createOneOffOccurrence(sampleScheduleInput())
    calendar.createError = nil

    try await repository.retryNativeCalendarSync(occurrenceId: occurrence.id)

    #expect(calendar.createdDrafts.map(\.occurrenceId) == [occurrence.id])
    #expect(calendar.recoveredCreateDrafts.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.map(\.status) == [.failed, .synced])
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryUsesBroadRecoveryForInterruptedCreateAttempt() async throws {
    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    var interruptedCreate = QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.create.rawValue,
        recordId: schedules.nextOccurrence.id,
        payloadSummary: schedules.nextOccurrence.title
    )
    interruptedCreate.attemptCount = 1
    try queue.enqueue(interruptedCreate)
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    try await repository.retryNativeCalendarSync(occurrenceId: schedules.nextOccurrence.id)

    #expect(calendar.recoveredCreateDrafts.map(\.occurrenceId) == [schedules.nextOccurrence.id])
    #expect(calendar.createdDrafts.map(\.occurrenceId) == [schedules.nextOccurrence.id])
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryRetriesFailedOccurrenceAfterRelaunch() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.nativeCalendarSyncStatus = .failed
    schedules.nextOccurrence.nativeCalendarSyncError = "Calendar denied"
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    try await repository.retryNativeCalendarSync(occurrenceId: schedules.nextOccurrence.id)

    #expect(schedules.loadedOccurrenceIds == [schedules.nextOccurrence.id])
    #expect(calendar.createdDrafts.map(\.occurrenceId) == [schedules.nextOccurrence.id])
    #expect(schedules.syncUpdates.map(\.status) == [.synced])
}

@MainActor
@Test func calendarBackedRepositoryDoesNotDuplicateCreateAfterSyncMetadataFailure() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.syncUpdateErrors = [RepositoryError(message: "Temporary database failure")]
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.createOneOffOccurrence(sampleScheduleInput())

    #expect(occurrence.nativeCalendarSyncStatus == .failed)
    #expect(occurrence.nativeCalendarEventIdentifier == "event-\(occurrence.id)")
    #expect(calendar.createdDrafts.count == 1)

    try await repository.retryNativeCalendarSync(occurrenceId: occurrence.id)

    #expect(calendar.createdDrafts.count == 1)
    #expect(calendar.updatedDrafts.isEmpty)
    #expect(schedules.syncUpdates.map(\.status) == [.synced])
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryAcceptsFractionalOccurrenceDatesFromLocalStore() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.nativeCalendarEventIdentifier = "event-existing"
    schedules.nextOccurrence.nativeCalendarExternalIdentifier = "external-existing"
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.editOccurrence(EditOccurrenceInput(
        occurrenceId: schedules.nextOccurrence.id,
        startsAt: "2026-05-28T10:00:00.123Z",
        endsAt: "2026-05-28T10:50:00.456Z",
        timezone: "Asia/Seoul"
    ))

    #expect(calendar.updatedDrafts.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.first?.status == .synced)
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryCreatesCalendarEventWhenEditingNeverSyncedOccurrence() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.nativeCalendarSyncStatus = .notConnected
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.editOccurrence(EditOccurrenceInput(
        occurrenceId: schedules.nextOccurrence.id,
        startsAt: "2026-05-29T10:00:00Z",
        endsAt: "2026-05-29T10:50:00Z",
        timezone: "Asia/Seoul"
    ))

    #expect(calendar.createdDrafts.map(\.occurrenceId) == [occurrence.id])
    #expect(calendar.updatedDrafts.isEmpty)
    #expect(schedules.syncUpdates.first?.status == .synced)
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryDeletesEventKitAfterCancelWhenIdentifierExists() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.nativeCalendarEventIdentifier = "event-123"
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.cancelOccurrence(id: schedules.nextOccurrence.id)

    #expect(schedules.canceledOccurrenceIds == [schedules.nextOccurrence.id])
    #expect(calendar.deletedEventIdentifiers == ["event-123"])
    #expect(schedules.syncUpdates.map(\.occurrenceId) == [occurrence.id])
    #expect(schedules.syncUpdates.first?.status == .synced)
    #expect(schedules.syncUpdates.first?.eventIdentifier == nil)
}

@MainActor
@Test func calendarBackedRepositoryCompletesNeverSyncedCancellationWithoutEventKit() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.nativeCalendarSyncStatus = .notConnected
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.cancelOccurrence(id: schedules.nextOccurrence.id)

    #expect(calendar.deletedEventIdentifiers.isEmpty)
    #expect(occurrence.status == .canceled)
    #expect(occurrence.nativeCalendarSyncStatus == .synced)
    #expect(schedules.syncUpdates.first?.eventIdentifier == nil)
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryReconcilesCanceledOccurrenceWithoutIdentityLocally() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.status = .canceled
    schedules.nextOccurrence.nativeCalendarSyncStatus = .pending
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    try await repository.retryNativeCalendarSync(occurrenceId: schedules.nextOccurrence.id)

    #expect(calendar.deletedEventIdentifiers.isEmpty)
    #expect(schedules.syncUpdates.first?.status == .synced)
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryRetriesDeleteAfterSyncMetadataFailure() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.nativeCalendarEventIdentifier = "event-123"
    schedules.syncUpdateErrors = [RepositoryError(message: "Temporary database failure")]
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let occurrence = try await repository.cancelOccurrence(id: schedules.nextOccurrence.id)

    #expect(occurrence.nativeCalendarSyncStatus == .failed)
    #expect(calendar.deletedEventIdentifiers == ["event-123"])

    try await repository.retryNativeCalendarSync(occurrenceId: occurrence.id)

    #expect(calendar.deletedEventIdentifiers == ["event-123"])
    #expect(schedules.syncUpdates.map(\.status) == [.synced])
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func canceledOccurrenceConvertsInterruptedCreateMetadataIntoDurableDelete() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.status = .canceled
    schedules.nextOccurrence.nativeCalendarSyncStatus = .pending
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let result = CalendarWriteResult(
        eventIdentifier: "event-123",
        calendarIdentifier: "calendar-1",
        externalIdentifier: "external-123",
        syncedAt: Date()
    )
    try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.metadataUpdate.rawValue,
        recordId: schedules.nextOccurrence.id,
        payloadSummary: schedules.nextOccurrence.title,
        syncUpdate: .synced(occurrenceId: schedules.nextOccurrence.id, result: result)
    ))
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    try await repository.retryNativeCalendarSync(occurrenceId: schedules.nextOccurrence.id)

    #expect(calendar.deletedEventIdentifiers == ["event-123"])
    #expect(schedules.syncUpdates.count == 2)
    #expect(schedules.syncUpdates.first?.eventIdentifier == "event-123")
    #expect(schedules.syncUpdates.last?.eventIdentifier == nil)
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func calendarBackedRepositoryRetriesDurableWriteAfterQueueRelaunch() async throws {
    let queueURL = temporaryQueueURL()
    defer { try? FileManager.default.removeItem(at: queueURL.deletingLastPathComponent()) }

    let schedules = RecordingScheduleRepository()
    let calendar = RecordingCalendarRepository()
    calendar.createError = RepositoryError(message: "Calendar unavailable")
    let firstQueue = try LocalWriteQueue(storageURL: queueURL)
    let firstRepository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: firstQueue
    )

    let occurrence = try await firstRepository.createOneOffOccurrence(sampleScheduleInput())
    #expect(firstQueue.writes.count == 1)

    calendar.createError = nil
    let relaunchedQueue = try LocalWriteQueue(storageURL: queueURL)
    let relaunchedRepository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: relaunchedQueue
    )
    try await relaunchedRepository.retryNativeCalendarSync(occurrenceId: occurrence.id)

    #expect(relaunchedQueue.writes.isEmpty)
    #expect(calendar.createdDrafts.map(\.occurrenceId) == [occurrence.id])
}

@MainActor
@Test func calendarBackedRepositoryReconcilesNewPendingOccurrences() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.pendingOccurrences = [schedules.nextOccurrence]
    let calendar = RecordingCalendarRepository()
    let queue = LocalWriteQueue()
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )

    let count = try await repository.reconcilePendingNativeCalendarSync()

    #expect(count == 1)
    #expect(calendar.createdDrafts.map(\.occurrenceId) == [schedules.nextOccurrence.id])
    #expect(queue.writes.isEmpty)
}

@MainActor
@Test func settingsRetryKeepsLaterOperationWhenEarlierOperationFails() async throws {
    let schedules = RecordingScheduleRepository()
    schedules.nextOccurrence.status = .canceled
    let calendar = RecordingCalendarRepository()
    calendar.deleteError = RepositoryError(message: "Calendar unavailable")
    let queue = LocalWriteQueue()
    let occurrenceId = schedules.nextOccurrence.id
    try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.create.rawValue,
        recordId: occurrenceId,
        payloadSummary: schedules.nextOccurrence.title
    ))
    try queue.enqueue(QueuedWrite(
        kind: .calendar,
        operation: CalendarQueueOperation.delete.rawValue,
        recordId: occurrenceId,
        payloadSummary: schedules.nextOccurrence.title
    ))
    let repository = CalendarBackedScheduleRepository(
        schedules: schedules,
        calendar: calendar,
        queue: queue
    )
    let viewModel = SyncStatusViewModel(
        queue: queue,
        retry: RetryScheduler(writeQueue: queue),
        schedules: repository
    )

    await viewModel.retryNow()

    #expect(queue.writes.map(\.operation) == [
        CalendarQueueOperation.create.rawValue,
        CalendarQueueOperation.delete.rawValue
    ])
}

@MainActor
@Test func calendarSettingsRequestsAccessAndLoadsCurrentSelection() async {
    let calendar = RecordingCalendarRepository()
    calendar.permission = .notDetermined
    calendar.requestedPermission = .authorized
    calendar.availableCalendars = [
        WritableCalendar(id: "calendar-2", title: "Personal", sourceTitle: "iCloud"),
        calendar.selected
    ]
    let viewModel = CalendarSettingsViewModel(calendar: calendar)

    await viewModel.refresh()
    #expect(viewModel.permission == .notDetermined)
    #expect(viewModel.calendars.isEmpty)

    await viewModel.requestPermission()

    #expect(viewModel.permission == .authorized)
    #expect(viewModel.calendars.map(\.id) == ["calendar-2", "calendar-1"])
    #expect(viewModel.selectedCalendarID == calendar.selected.id)
    #expect(viewModel.feedback?.kind == .success)
    #expect(viewModel.isBusy == false)
}

@MainActor
@Test func calendarSettingsReportsSelectionFailureAndKeepsCurrentCalendar() async {
    let calendar = RecordingCalendarRepository()
    let other = WritableCalendar(id: "calendar-2", title: "스튜디오", sourceTitle: "Google")
    calendar.availableCalendars = [calendar.selected, other]
    let viewModel = CalendarSettingsViewModel(calendar: calendar)
    await viewModel.refresh()
    calendar.selectError = RepositoryError(message: "선택 저장 실패")

    await viewModel.selectCalendar(other)

    #expect(viewModel.selectedCalendarID == calendar.selected.id)
    #expect(viewModel.feedback?.kind == .error)
    #expect(viewModel.feedback?.message.contains("선택 저장 실패") == true)
    #expect(viewModel.isBusy == false)
}

@MainActor
@Test func calendarSettingsUpdatesSelectionAndShowsSuccess() async {
    let calendar = RecordingCalendarRepository()
    let other = WritableCalendar(id: "calendar-2", title: "스튜디오", sourceTitle: "Google")
    calendar.availableCalendars = [calendar.selected, other]
    let viewModel = CalendarSettingsViewModel(calendar: calendar)
    await viewModel.refresh()

    await viewModel.selectCalendar(other)

    #expect(viewModel.selectedCalendarID == other.id)
    #expect(calendar.selected == other)
    #expect(viewModel.feedback?.kind == .success)
    #expect(viewModel.feedback?.message.contains("스튜디오") == true)
}

private func temporaryQueueURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-Queue-\(UUID().uuidString)", isDirectory: true)
        .appendingPathComponent("writes.json")
}

private func sampleScheduleInput() -> ScheduleLessonInput {
    ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "김민지 lesson",
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    )
}

@MainActor
private final class RecordingScheduleRepository: ScheduleRepository {
    var nextOccurrence = sampleScheduleInput().makeOccurrence(instructorId: PreviewData.instructorId)
    var createdInputs: [ScheduleLessonInput] = []
    var editedInputs: [EditOccurrenceInput] = []
    var canceledOccurrenceIds: [EntityID] = []
    var retriedOccurrenceIds: [EntityID] = []
    var loadedOccurrenceIds: [EntityID] = []
    var syncUpdates: [NativeCalendarSyncUpdateInput] = []
    var syncUpdateErrors: [Error] = []
    var pendingOccurrences: [LessonOccurrence] = []

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        createdInputs.append(input)
        nextOccurrence = input.makeOccurrence(instructorId: PreviewData.instructorId)
        return nextOccurrence
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        []
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        editedInputs.append(input)
        nextOccurrence.startsAt = input.startsAt
        nextOccurrence.endsAt = input.endsAt
        nextOccurrence.timezone = input.timezone
        return nextOccurrence
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        canceledOccurrenceIds.append(id)
        nextOccurrence.status = .canceled
        return nextOccurrence
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {
        retriedOccurrenceIds.append(occurrenceId)
    }

    func loadPendingNativeCalendarOccurrences() async throws -> [LessonOccurrence] {
        pendingOccurrences
    }

    func loadOccurrence(id: EntityID) async throws -> LessonOccurrence {
        loadedOccurrenceIds.append(id)
        guard nextOccurrence.id == id else {
            throw RepositoryError.notFound
        }
        return nextOccurrence
    }

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        if !syncUpdateErrors.isEmpty {
            throw syncUpdateErrors.removeFirst()
        }
        syncUpdates.append(input)
        nextOccurrence.nativeCalendarEventIdentifier = input.eventIdentifier
        nextOccurrence.nativeCalendarIdentifier = input.calendarIdentifier
        nextOccurrence.nativeCalendarExternalIdentifier = input.externalIdentifier
        nextOccurrence.nativeCalendarSyncStatus = input.status
        nextOccurrence.nativeCalendarSyncError = input.error
        nextOccurrence.nativeCalendarSyncedAt = input.syncedAt
    }
}

@MainActor
private final class RecordingCalendarRepository: CalendarRepository {
    var selected = WritableCalendar(id: "calendar-1", title: "Teaching", sourceTitle: "iCloud")
    var permission: EventKitPermissionState = .authorized
    var requestedPermission: EventKitPermissionState?
    var availableCalendars: [WritableCalendar]?
    var selectError: Error?
    var createError: Error?
    var deleteError: Error?
    var createdDrafts: [LessonCalendarEventDraft] = []
    var recoveredCreateDrafts: [LessonCalendarEventDraft] = []
    var updatedDrafts: [LessonCalendarEventDraft] = []
    var deletedEventIdentifiers: [String] = []
    var onCreate: ((EntityID) -> Void)?

    func permissionStatus() -> EventKitPermissionState { permission }
    func requestPermission() async throws -> EventKitPermissionState {
        permission = requestedPermission ?? permission
        return permission
    }
    func listWritableCalendars() async throws -> [WritableCalendar] { availableCalendars ?? [selected] }
    func selectCalendar(_ calendar: WritableCalendar) async throws {
        if let selectError { throw selectError }
        selected = calendar
    }
    func selectedCalendar() -> WritableCalendar? { selected }

    func createLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        if let createError { throw createError }
        onCreate?(event.occurrenceId)
        createdDrafts.append(event)
        return CalendarWriteResult(eventIdentifier: "event-\(event.occurrenceId)", calendarIdentifier: selected.id, externalIdentifier: "external-\(event.occurrenceId)", syncedAt: Date())
    }

    func recoverOrCreateLessonEvent(_ event: LessonCalendarEventDraft) async throws -> CalendarWriteResult {
        recoveredCreateDrafts.append(event)
        return try await createLessonEvent(event)
    }

    func updateLessonEvent(_ event: LessonCalendarEventDraft, existingIdentity: CalendarEventIdentity) async throws -> CalendarWriteResult {
        updatedDrafts.append(event)
        return CalendarWriteResult(eventIdentifier: existingIdentity.eventIdentifier ?? "event-\(event.occurrenceId)", calendarIdentifier: selected.id, externalIdentifier: existingIdentity.externalIdentifier ?? "external-\(event.occurrenceId)", syncedAt: Date())
    }

    func deleteLessonEvent(_ event: LessonCalendarEventDraft, existingIdentity: CalendarEventIdentity) async throws {
        if let deleteError { throw deleteError }
        deletedEventIdentifiers.append(existingIdentity.eventIdentifier ?? event.occurrenceId.uuidString)
    }
}
