import SwiftUI

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var environment
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < AppTheme.compactBreakpoint

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DashboardHeader(viewModel: viewModel, isCompact: isCompact)

                    if viewModel.isLoading && viewModel.model == nil {
                        ContentUnavailableView("Loading lessons", systemImage: "hourglass")
                    } else if let model = viewModel.model {
                        if isCompact {
                            TodayLessonListView(events: model.todayEvents, selected: $viewModel.selectedEvent)
                            StudentRosterView(roster: model.roster)
                        } else {
                            HStack(alignment: .top, spacing: 16) {
                                WeekCalendarView(days: model.days, selected: $viewModel.selectedEvent)
                                    .frame(minWidth: 520)
                                VStack(spacing: 16) {
                                    SelectedLessonPanel(event: viewModel.selectedEvent)
                                    StudentRosterView(roster: model.roster)
                                }
                                .frame(width: min(380, max(300, proxy.size.width * 0.34)))
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No lesson data",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text(viewModel.errorMessage ?? "Refresh after signing in.")
                        )
                    }
                }
                .frame(maxWidth: AppTheme.contentWidth)
                .padding(20)
            }
            .onKeyPress(.leftArrow) {
                viewModel.moveWeek(by: -1)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                viewModel.moveWeek(by: 1)
                return .handled
            }
            .sheet(isPresented: $viewModel.showingScheduleSheet) {
                ScheduleLessonSheet(repository: environment.schedules, roster: viewModel.model?.roster ?? []) {
                    await viewModel.load()
                }
                    .frame(minWidth: 520, minHeight: 420)
            }
            .task { await viewModel.load() }
        }
        .navigationTitle("Today")
    }
}

private struct DashboardHeader: View {
    @Bindable var viewModel: DashboardViewModel
    var isCompact: Bool

    var body: some View {
        HStack(alignment: .center) {
            SectionHeader(
                title: "Calendar Workbench",
                subtitle: viewModel.model?.weekTitle ?? "Lesson schedule and student context"
            )

            Spacer()

            Button {
                viewModel.moveWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .help("Previous week")
            .accessibilityLabel("Previous week")

            Button("Today") {
                viewModel.weekAnchor = Date()
                Task { await viewModel.load() }
            }

            Button {
                viewModel.moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .help("Next week")
            .accessibilityLabel("Next week")

            Button {
                viewModel.presentScheduleSheet()
            } label: {
                if isCompact {
                    Image(systemName: "plus")
                } else {
                    Label("Add Lesson", systemImage: "plus")
                }
            }
            .buttonStyle(.borderedProminent)
            .help("Add lesson")
            .accessibilityLabel("Add lesson")
        }
    }
}
