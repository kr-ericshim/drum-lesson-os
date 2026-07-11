import SwiftUI

enum LessonEventDragPayload {
    static func value(for event: CalendarLessonEvent) -> String {
        event.id.uuidString
    }

    static func event(from values: [String], in events: [CalendarLessonEvent]) -> CalendarLessonEvent? {
        guard let identifier = values.compactMap(UUID.init(uuidString:)).first else { return nil }
        return events.first { $0.id == identifier }
    }
}

enum LessonEventActionContext: Equatable {
    case prepare
    case start
    case record

    init(event: CalendarLessonEvent, now: Date = Date()) {
        let timeZone = TimeZone(identifier: event.timezone) ?? .current
        self = Self.resolve(
            eventDateKey: event.dateKey,
            todayDateKey: DateOnly.string(from: now, timeZone: timeZone)
        )
    }

    static func resolve(eventDateKey: String, todayDateKey: String) -> Self {
        if eventDateKey > todayDateKey { return .prepare }
        if eventDateKey < todayDateKey { return .record }
        return .start
    }

    var title: String {
        switch self {
        case .prepare: "레슨 준비 보기"
        case .start: "레슨 시작"
        case .record: "레슨 기록"
        }
    }

    var systemImage: String {
        switch self {
        case .prepare: "checklist"
        case .start: "play.circle.fill"
        case .record: "square.and.pencil"
        }
    }

    var opensLessonWorkspace: Bool {
        self != .prepare
    }
}

struct LessonEventDragPreview: View {
    var event: CalendarLessonEvent

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(AppTheme.Accent.teachingForeground)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.studentName)
                    .font(.subheadline.weight(.semibold))
                Text(event.timeLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(.regularMaterial, in: AppTheme.softPanel)
        .overlay(AppTheme.softPanel.stroke(AppTheme.Accent.teaching.opacity(0.32), lineWidth: 1))
    }
}

struct LessonEventActionMenuItems: View {
    var event: CalendarLessonEvent
    var onEdit: () -> Void
    var onCancel: () -> Void
    var onRetrySync: () -> Void
    var onPrimaryAction: () -> Void
    var onOpenStudent: () -> Void

    private var actionContext: LessonEventActionContext {
        LessonEventActionContext(event: event)
    }

    var body: some View {
        Button(action: onPrimaryAction) {
            Label(actionContext.title, systemImage: actionContext.systemImage)
        }

        Button(action: onOpenStudent) {
            Label("학생 보기", systemImage: "person.crop.circle")
        }

        Divider()

        Button(action: onEdit) {
            Label("시간 수정", systemImage: "calendar.badge.clock")
        }

        if event.syncStatus == .failed || event.syncStatus == .notConnected {
            Button(action: onRetrySync) {
                Label("캘린더 동기화 재시도", systemImage: "arrow.triangle.2.circlepath")
            }
        }

        Divider()

        Button(role: .destructive, action: onCancel) {
            Label("레슨 취소", systemImage: "trash")
        }
    }
}

private struct LessonEventContextActionsModifier: ViewModifier {
    @Environment(AppEnvironment.self) private var environment
    var event: CalendarLessonEvent
    @State private var editTarget: CalendarLessonEvent?
    @State private var cancelTarget: CalendarLessonEvent?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                LessonEventActionMenuItems(
                    event: event,
                    onEdit: { editTarget = event },
                    onCancel: { cancelTarget = event },
                    onRetrySync: {
                        Task { await environment.dashboard.retryCalendarSync(occurrenceId: event.id) }
                    },
                    onPrimaryAction: { openPrimaryAction(for: event) },
                    onOpenStudent: { environment.route = .student(event.studentId) }
                )
            }
            .sheet(item: $editTarget) { target in
                EditOccurrenceSheet(event: target, repository: environment.schedules) {
                    await environment.dashboard.load()
                }
            }
            .confirmationDialog("이 레슨 일정을 취소할까요?", isPresented: isShowingCancelConfirmation) {
                Button("레슨 취소", role: .destructive) {
                    guard let occurrenceId = cancelTarget?.id else { return }
                    cancelTarget = nil
                    Task { await environment.dashboard.cancelOccurrence(id: occurrenceId) }
                }
                Button("돌아가기", role: .cancel) {}
            } message: {
                Text("이번 회차만 취소하며 주간 보기와 Apple 캘린더에 반영됩니다.")
            }
    }

    private func openPrimaryAction(for event: CalendarLessonEvent) {
        let context = LessonEventActionContext(event: event)
        environment.route = context.opensLessonWorkspace ? .lesson(event) : .student(event.studentId)
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
}

extension View {
    func lessonEventContextActions(for event: CalendarLessonEvent) -> some View {
        modifier(LessonEventContextActionsModifier(event: event))
    }
}
