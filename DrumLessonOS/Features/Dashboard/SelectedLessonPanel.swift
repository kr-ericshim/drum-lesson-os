import SwiftUI

struct SelectedLessonPanel: View {
    @Environment(AppEnvironment.self) private var environment
    var event: CalendarLessonEvent?
    @State private var editTarget: CalendarLessonEvent?
    @State private var cancelTarget: CalendarLessonEvent?

    var body: some View {
        WorkbenchSurface(event == nil ? .quiet : .inspector, padding: AppTheme.Spacing.lg) {
            if let event {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(event.studentName)
                                .font(.title2.weight(.semibold))
                                .lineLimit(1)
                            Text("\(LessonDateFormatters.displayDate(event.dateKey)) · \(event.timeLabel) · \(event.durationMinutes)분")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: AppTheme.Spacing.sm) {
                            if shouldShowSyncStatus {
                                StatusBadge(
                                    label: event.syncStatus.label,
                                    systemImage: event.syncStatus.statusIcon,
                                    tint: event.syncStatus.statusTint
                                )
                            }

                            Menu {
                                LessonEventActionMenuItems(
                                    event: event,
                                    onEdit: { editTarget = event },
                                    onCancel: { cancelTarget = event },
                                    onRetrySync: {
                                        Task { await environment.dashboard.retryCalendarSync(occurrenceId: event.id) }
                                    },
                                    onOpenLesson: { environment.route = .lesson(event) },
                                    onOpenStudent: { environment.route = .student(event.studentId) }
                                )
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .frame(width: 28, height: 28)
                            }
                            .menuStyle(.borderlessButton)
                            .help("레슨 동작")
                            .accessibilityLabel("레슨 동작")
                        }
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("첫 확인")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.Accent.teachingForeground)

                        Text(event.firstCheck)
                            .font(.title2.weight(.semibold))
                            .lineLimit(4)

                        if !event.watchFlags.isEmpty {
                            flagBadges(event.watchFlags)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Accent.teaching.opacity(0.07), in: AppTheme.softPanel)
                    .overlay(AppTheme.softPanel.stroke(AppTheme.Accent.teaching.opacity(0.16), lineWidth: 1))

                    if let error = event.syncError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.Semantic.error)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("캘린더 동기화 오류")
                            .accessibilityValue(error)
                    }
                    Button {
                        environment.route = .lesson(event)
                    } label: {
                        Label("레슨 시작", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Label("다음 레슨 준비", systemImage: "play.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Accent.teachingForeground)
                    Text("아직 선택한 레슨이 없어요")
                        .font(.headline)
                        .padding(.top, AppTheme.Spacing.xs)
                    Text("첫 레슨을 잡거나 주간 보기에서 카드를 선택하세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            }
        }
        .sheet(item: $editTarget) { target in
            EditOccurrenceSheet(event: target, repository: environment.schedules) {
                await environment.dashboard.load()
            }
        }
        .confirmationDialog("이 레슨 일정을 취소할까요?", isPresented: isShowingCancelConfirmation) {
            Button("일정 취소", role: .destructive) {
                guard let occurrenceId = cancelTarget?.id else { return }
                cancelTarget = nil
                Task { await environment.dashboard.cancelOccurrence(id: occurrenceId) }
            }
            Button("돌아가기", role: .cancel) {}
        } message: {
            Text("이번 회차만 취소하며 주간 보기에서 사라집니다.")
        }
    }

    private var shouldShowSyncStatus: Bool {
        event?.syncStatus.needsAttention == true
    }

    private var isShowingCancelConfirmation: Binding<Bool> {
        Binding(
            get: { cancelTarget != nil },
            set: { isPresented in
                if !isPresented {
                    cancelTarget = nil
                }
            }
        )
    }

    @ViewBuilder
    private func flagBadges(_ flags: [LessonAttentionFlag]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.Spacing.sm) {
                flagBadgeContent(flags)
            }
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                flagBadgeContent(flags)
            }
        }
    }

    @ViewBuilder
    private func flagBadgeContent(_ flags: [LessonAttentionFlag]) -> some View {
        ForEach(flags.prefix(2)) { flag in
            StatusBadge(label: flag.label, tint: AppTheme.Accent.teachingForeground)
        }
        if flags.count > 2 {
            Text("외 \(flags.count - 2)개")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityLabel("추가 주의 항목 \(flags.count - 2)개")
        }
    }
}
