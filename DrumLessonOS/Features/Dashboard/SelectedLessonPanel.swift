import SwiftUI

struct SelectedLessonPanel: View {
    @Environment(AppEnvironment.self) private var environment
    var event: CalendarLessonEvent?
    @State private var showingEditSheet = false

    var body: some View {
        WorkbenchPanel {
            if let event {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: event.studentName, subtitle: "\(event.dateKey) · \(event.timeLabel) · \(event.durationMinutes) min")
                    Text(event.firstCheck)
                        .font(.title3.weight(.semibold))
                        .lineLimit(3)

                    if let error = event.syncError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    if event.syncStatus == .failed {
                        Button {
                            Task { await environment.dashboard.retrySelectedCalendarSync() }
                        } label: {
                            Label("Retry Calendar Sync", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Button {
                            environment.route = .lesson(event)
                        } label: {
                            Label("Start Lesson", systemImage: "play.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "calendar.badge.clock")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            Task { await environment.dashboard.cancelSelectedOccurrence() }
                        } label: {
                            Label("Cancel", systemImage: "trash")
                        }
                    }
                }
            } else {
                ContentUnavailableView("Select a lesson", systemImage: "calendar")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let event {
                EditOccurrenceSheet(event: event, repository: environment.schedules) {
                    await environment.dashboard.load()
                }
            }
        }
    }
}
