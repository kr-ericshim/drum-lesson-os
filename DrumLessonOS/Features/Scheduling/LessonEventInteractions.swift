import SwiftUI
import UniformTypeIdentifiers

enum LessonEventDragPayload {
    static let contentType = UTType.utf8PlainText

    static func itemProvider(for event: CalendarLessonEvent) -> NSItemProvider {
        NSItemProvider(object: event.id.uuidString as NSString)
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
    var onOpenLesson: () -> Void
    var onOpenStudent: () -> Void

    var body: some View {
        Button(action: onOpenLesson) {
            Label("레슨 시작", systemImage: "play.circle.fill")
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
                    onOpenLesson: { environment.route = .lesson(event) },
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
