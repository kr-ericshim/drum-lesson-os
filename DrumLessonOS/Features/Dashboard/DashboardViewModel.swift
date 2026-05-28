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
    var weekAnchor = Date()

    private let repository: StudentRepository
    private let scheduleRepository: ScheduleRepository

    init(repository: StudentRepository, scheduleRepository: ScheduleRepository) {
        self.repository = repository
        self.scheduleRepository = scheduleRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await repository.loadCalendarWorkbench(weekContaining: weekAnchor)
            model = loaded
            selectedEvent = selectedEvent.flatMap { event in
                loaded.days.flatMap(\.events).first { $0.id == event.id }
            } ?? loaded.selectedEvent
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentScheduleSheet() {
        showingScheduleSheet = true
    }

    func moveWeek(by value: Int) {
        weekAnchor = Calendar.iso8601SeoulCompatible.date(byAdding: .day, value: value * 7, to: weekAnchor) ?? weekAnchor
        Task { await load() }
    }

    func cancelSelectedOccurrence() async {
        guard let selectedEvent else { return }
        do {
            _ = try await scheduleRepository.cancelOccurrence(id: selectedEvent.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retrySelectedCalendarSync() async {
        guard let selectedEvent else { return }
        do {
            try await scheduleRepository.retryNativeCalendarSync(occurrenceId: selectedEvent.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
