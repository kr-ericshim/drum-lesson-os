import Accessibility
import SwiftUI

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var environment
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < AppTheme.compactBreakpoint

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppTheme.Accent.teaching.opacity(0.14))
                            Image(systemName: "metronome.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.Accent.teachingForeground)
                        }
                        .frame(width: 42, height: 42)
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("레슨 데스크")
                                .font(.title2.weight(.semibold))
                            Text(headerSubtitle(isCompact: isCompact))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: AppTheme.Spacing.lg)

                        if let model = viewModel.model, !isCompact {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                Label("오늘 \(model.todayEvents.count)", systemImage: "sun.max")
                                Label("이번 주 \(model.days.flatMap(\.events).count)", systemImage: "calendar")
                            }
                            .font(.subheadline.monospacedDigit().weight(.medium))
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)

                    if let errorMessage = viewModel.errorMessage, viewModel.model != nil {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.Semantic.error)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("일정 오류")
                            .accessibilityValue(errorMessage)
                    }

                    if viewModel.isLoading && viewModel.model == nil {
                        ProgressView("레슨을 불러오는 중…")
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else if let model = viewModel.model {
                        if isCompact {
                            if !model.todayEvents.isEmpty {
                                TodayLessonListView(events: model.todayEvents, selected: $viewModel.selectedEvent)
                            }
                            SelectedLessonPanel(event: viewModel.selectedEvent)
                            WeekAgendaView(
                                days: model.days,
                                selected: $viewModel.selectedEvent,
                                onAddLesson: { viewModel.presentScheduleSheet() },
                                onMove: moveOccurrence
                            )
                            StudentRosterView(roster: model.roster)
                        } else {
                            HStack(alignment: .top, spacing: AppTheme.Spacing.lg) {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                                    if !model.todayEvents.isEmpty {
                                        TodayLessonListView(events: model.todayEvents, selected: $viewModel.selectedEvent)
                                    }
                                    WeekCalendarView(
                                        days: model.days,
                                        selected: $viewModel.selectedEvent,
                                        onAddLesson: { viewModel.presentScheduleSheet() },
                                        onMove: moveOccurrence
                                    )
                                }
                                .frame(minWidth: 600, maxWidth: .infinity)

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                                    SelectedLessonPanel(event: viewModel.selectedEvent)
                                    StudentRosterView(roster: model.roster)
                                }
                                .frame(width: 336)
                            }
                        }
                    } else {
                        ContentUnavailableView {
                            Label("레슨 데이터를 불러올 수 없습니다", systemImage: "calendar.badge.exclamationmark")
                        } description: {
                            Text(viewModel.errorMessage ?? "이 Mac의 레슨 데이터를 다시 불러와 주세요.")
                        } actions: {
                            Button("다시 불러오기") {
                                Task { await viewModel.load() }
                            }
                        }
                    }
                }
                .frame(maxWidth: AppTheme.contentWidth, alignment: .topLeading)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.xxl)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(AppTheme.workspaceBackground)
            .onKeyPress(.leftArrow) {
                viewModel.moveWeek(by: -1)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                viewModel.moveWeek(by: 1)
                return .handled
            }
            .sheet(isPresented: $viewModel.showingScheduleSheet) {
                ScheduleLessonSheet(
                    repository: environment.schedules,
                    roster: viewModel.model?.roster ?? [],
                    defaultDurationMinutes: environment.preferences.defaultLessonDurationMinutes
                ) {
                    await viewModel.load()
                }
            }
            .alert(
                "일정이 겹칩니다",
                isPresented: Binding(
                    get: { !viewModel.pendingMoveConflicts.isEmpty },
                    set: { if !$0 { viewModel.cancelPendingConflictMove() } }
                )
            ) {
                Button("시간 다시 선택", role: .cancel) {
                    viewModel.cancelPendingConflictMove()
                }
                Button("그래도 이동") {
                    Task { await viewModel.confirmPendingConflictMove() }
                }
            } message: {
                Text(viewModel.pendingMoveConflictMessage)
            }
            .onChange(of: viewModel.errorMessage) { _, message in
                guard let message else { return }
                AccessibilityNotification.Announcement(message).post()
            }
            .task { await environment.refresh() }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        viewModel.moveWeek(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .help("이전 주")
                    .accessibilityLabel("이전 주")

                    Button("오늘") {
                        viewModel.moveToCurrentWeek()
                    }

                    Button {
                        viewModel.moveWeek(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .help("다음 주")
                    .accessibilityLabel("다음 주")

                    Button {
                        viewModel.presentScheduleSheet()
                    } label: {
                        Label("레슨 추가", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .help("레슨 추가")
                    .accessibilityLabel("레슨 추가")
                }
            }
        }
        .navigationTitle("대시보드")
    }

    private func moveOccurrence(_ event: CalendarLessonEvent, to dateKey: String) {
        Task {
            await viewModel.moveOccurrence(event, toDateKey: dateKey)
        }
    }

    private func headerSubtitle(isCompact: Bool) -> String {
        guard let model = viewModel.model else {
            return "레슨 일정과 학생 맥락"
        }
        guard isCompact else { return model.weekTitle }
        return "\(model.weekTitle) · 오늘 \(model.todayEvents.count)개"
    }
}
