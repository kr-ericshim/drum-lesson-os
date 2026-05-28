import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Bindable var syncStatus: SyncStatusViewModel
    let calendar: CalendarRepository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CalendarSettingsView(calendar: calendar)
                SyncStatusView(viewModel: syncStatus)
                Button(role: .destructive) {
                    Task { await environment.auth.signOut() }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            .frame(maxWidth: 760)
            .padding(20)
        }
        .navigationTitle("Settings")
    }
}

struct CalendarSettingsView: View {
    let calendar: CalendarRepository
    @State private var permission: EventKitPermissionState = .notDetermined
    @State private var calendars: [WritableCalendar] = []
    @State private var message: String?

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Apple Calendar", subtitle: "Native EventKit access, no Apple password stored.")
                StatusBadge(label: permission.rawValue, systemImage: "calendar")

                HStack {
                    Button("Request Access") {
                        Task { await request() }
                    }
                    Button("Load Calendars") {
                        Task { await loadCalendars() }
                    }
                }

                ForEach(calendars) { item in
                    Button {
                        Task { try? await calendar.selectCalendar(item) }
                    } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            Text(item.sourceTitle)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { permission = calendar.permissionStatus() }
    }

    private func request() async {
        do {
            permission = try await calendar.requestPermission()
            message = "Calendar permission: \(permission.rawValue)"
        } catch {
            message = error.localizedDescription
        }
    }

    private func loadCalendars() async {
        do {
            calendars = try await calendar.listWritableCalendars()
        } catch {
            message = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class SyncStatusViewModel {
    var queue: LocalWriteQueue
    var retry: RetryScheduler
    var schedules: ScheduleRepository?
    var lastMessage: String?

    init(queue: LocalWriteQueue, retry: RetryScheduler, schedules: ScheduleRepository? = nil) {
        self.queue = queue
        self.retry = retry
        self.schedules = schedules
    }

    func refresh() {
        lastMessage = queue.hasPendingWrites ? "\(queue.writes.count) pending writes" : "All local writes are clear."
    }

    func retryNow() async {
        await retry.retryNow { [schedules] write in
            guard write.kind == .calendar, let occurrenceId = write.recordId, let schedules else {
                return
            }
            try await schedules.retryNativeCalendarSync(occurrenceId: occurrenceId)
        }
        refresh()
    }
}

struct SyncStatusView: View {
    @Bindable var viewModel: SyncStatusViewModel

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Sync Queue", subtitle: viewModel.lastMessage)
                ForEach(viewModel.queue.writes) { write in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(write.kind.rawValue) · \(write.operation)")
                            .font(.subheadline.weight(.semibold))
                        Text(write.payloadSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let error = write.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                Button {
                    Task { await viewModel.retryNow() }
                } label: {
                    Label("Retry Now", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        .onAppear { viewModel.refresh() }
    }
}
