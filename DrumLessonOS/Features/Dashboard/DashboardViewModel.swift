import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var model: CalendarWorkbench?
    var selectedEvent: CalendarLessonEvent?
    var isLoading = false
    var errorMessage: String?
    var showingScheduleSheet = false
    private(set) var movingOccurrenceIDs: Set<EntityID> = []
    private(set) var weekAnchor: Date

    private let repository: StudentRepository
    private let scheduleRepository: ScheduleRepository
    private var requestedWeekAnchor: Date?
    private var loadGeneration = 0

    init(repository: StudentRepository, scheduleRepository: ScheduleRepository, weekAnchor: Date = Date()) {
        self.repository = repository
        self.scheduleRepository = scheduleRepository
        self.weekAnchor = weekAnchor
    }

    func load() async {
        await load(weekContaining: requestedWeekAnchor ?? weekAnchor)
    }

    func load(weekContaining requestedAnchor: Date) async {
        loadGeneration += 1
        let generation = loadGeneration
        requestedWeekAnchor = requestedAnchor
        isLoading = true
        errorMessage = nil

        do {
            var loaded = try await repository.loadCalendarWorkbench(weekContaining: requestedAnchor)
            guard generation == loadGeneration else { return }

            do {
                let reconciledCount = try await scheduleRepository.reconcilePendingNativeCalendarSync()
                guard generation == loadGeneration else { return }
                if reconciledCount > 0 {
                    loaded = try await repository.loadCalendarWorkbench(weekContaining: requestedAnchor)
                    guard generation == loadGeneration else { return }
                }
            } catch {
                guard generation == loadGeneration else { return }
                applyLoadedModel(loaded, weekAnchor: requestedAnchor, errorMessage: error.localizedDescription)
                return
            }

            applyLoadedModel(loaded, weekAnchor: requestedAnchor, errorMessage: nil)
        } catch {
            guard generation == loadGeneration else { return }
            requestedWeekAnchor = nil
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func presentScheduleSheet() {
        showingScheduleSheet = true
    }

    func moveWeek(by value: Int) {
        let baseAnchor = requestedWeekAnchor ?? weekAnchor
        let target = Calendar.iso8601SeoulCompatible.date(byAdding: .day, value: value * 7, to: baseAnchor) ?? baseAnchor
        requestedWeekAnchor = target
        Task { await load(weekContaining: target) }
    }

    func moveToCurrentWeek(now: Date = Date()) {
        requestedWeekAnchor = now
        Task { await load(weekContaining: now) }
    }

    func cancelOccurrence(id: EntityID) async {
        do {
            _ = try await scheduleRepository.cancelOccurrence(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveOccurrence(
        _ event: CalendarLessonEvent,
        toDateKey dateKey: String,
        minuteOfDay: Int? = nil
    ) async {
        guard !movingOccurrenceIDs.contains(event.id) else { return }

        let input: EditOccurrenceInput
        do {
            input = try ScheduleMoveInputFactory.makeInput(
                event: event,
                targetDateKey: dateKey,
                targetMinuteOfDay: minuteOfDay
            )
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let currentStart = ISO8601DateFormatter.withFractions.date(from: event.startsAt)
            ?? ISO8601DateFormatter.plain.date(from: event.startsAt)
        let movedStart = ISO8601DateFormatter.plain.date(from: input.startsAt)
        guard currentStart != movedStart else { return }

        let reloadAnchor = weekAnchor
        movingOccurrenceIDs.insert(event.id)
        defer { movingOccurrenceIDs.remove(event.id) }
        applyOptimisticMove(event: event, input: input)

        do {
            let occurrence = try await scheduleRepository.editOccurrence(input)
            await load(weekContaining: reloadAnchor)
            if occurrence.nativeCalendarSyncStatus == .failed {
                let reason = occurrence.nativeCalendarSyncError ?? "설정에서 다시 시도해 주세요."
                errorMessage = "레슨 시간은 변경됐지만 Apple 캘린더 동기화에 실패했습니다: \(reason)"
            }
        } catch {
            let message = error.localizedDescription
            await load(weekContaining: reloadAnchor)
            errorMessage = message
        }
    }

    func retryCalendarSync(occurrenceId: EntityID) async {
        do {
            try await scheduleRepository.retryNativeCalendarSync(occurrenceId: occurrenceId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyLoadedModel(_ loaded: CalendarWorkbench, weekAnchor: Date, errorMessage: String?) {
        model = loaded
        selectedEvent = selectedEvent.flatMap { event in
            loaded.days.flatMap(\.events).first { $0.id == event.id }
        } ?? loaded.selectedEvent
        self.weekAnchor = weekAnchor
        requestedWeekAnchor = nil
        isLoading = false
        self.errorMessage = errorMessage
    }

    private func applyOptimisticMove(event: CalendarLessonEvent, input: EditOccurrenceInput) {
        guard var model else { return }

        var movedEvent = event
        movedEvent.startsAt = input.startsAt
        movedEvent.endsAt = input.endsAt
        movedEvent.dateKey = DateOnly.string(
            fromISOInstant: input.startsAt,
            timeZoneIdentifier: input.timezone
        )
        movedEvent.timeLabel = DateOnly.timeLabel(
            fromISOInstant: input.startsAt,
            timeZoneIdentifier: input.timezone
        )
        movedEvent.syncStatus = .pending
        movedEvent.syncError = nil

        for index in model.days.indices {
            model.days[index].events.removeAll { $0.id == event.id }
        }
        if let targetIndex = model.days.firstIndex(where: { $0.dateKey == movedEvent.dateKey }) {
            model.days[targetIndex].events.append(movedEvent)
            model.days[targetIndex].events.sort { $0.startsAt < $1.startsAt }
        }
        model.todayEvents = model.days
            .first(where: { $0.dateKey == model.todayDateKey })?
            .events ?? []
        model.selectedEvent = movedEvent

        self.model = model
        selectedEvent = movedEvent
    }
}

enum ScheduleMoveInputFactory {
    static func makeInput(
        event: CalendarLessonEvent,
        targetDateKey: String,
        targetMinuteOfDay: Int?
    ) throws -> EditOccurrenceInput {
        guard let timeZone = TimeZone(identifier: event.timezone) else {
            throw ValidationError(field: "timezone", message: "레슨 시간대를 확인할 수 없습니다.")
        }
        guard let originalStart = ISO8601DateFormatter.withFractions.date(from: event.startsAt)
            ?? ISO8601DateFormatter.plain.date(from: event.startsAt) else {
            throw ValidationError(field: "startsAt", message: "기존 레슨 시작 시간을 확인할 수 없습니다.")
        }

        let dateParts = targetDateKey.split(separator: "-").compactMap { Int($0) }
        guard dateParts.count == 3 else {
            throw ValidationError(field: "startsAt", message: "이동할 날짜를 확인할 수 없습니다.")
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let originalTime = calendar.dateComponents([.hour, .minute], from: originalStart)
        let resolvedMinute = min(max(targetMinuteOfDay ?? ((originalTime.hour ?? 0) * 60 + (originalTime.minute ?? 0)), 0), 1_439)

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = dateParts[0]
        components.month = dateParts[1]
        components.day = dateParts[2]
        components.hour = resolvedMinute / 60
        components.minute = resolvedMinute % 60

        guard let movedStart = calendar.date(from: components),
              let movedEnd = calendar.date(byAdding: .minute, value: event.durationMinutes, to: movedStart) else {
            throw ValidationError(field: "startsAt", message: "선택한 날짜와 시간으로 레슨을 이동할 수 없습니다.")
        }

        return EditOccurrenceInput(
            occurrenceId: event.id,
            startsAt: ISO8601DateFormatter.plain.string(from: movedStart),
            endsAt: ISO8601DateFormatter.plain.string(from: movedEnd),
            timezone: event.timezone
        )
    }
}
