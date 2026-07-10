import SwiftUI

struct TodayLessonListView: View {
    var events: [CalendarLessonEvent]
    @Binding var selected: CalendarLessonEvent?

    var body: some View {
        WorkbenchSurface(.panel, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                    Label("오늘의 레슨", systemImage: "sun.max.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Accent.teachingForeground)
                    Spacer()
                    Text("예정 \(events.count)개")
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ForEach(events) { event in
                    Button {
                        selected = event
                    } label: {
                        LessonEventCard(event: event, isSelected: event.id == selected?.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(event.timeLabel) \(event.studentName) 레슨")
                    .accessibilityValue(accessibilityValue(for: event))
                    .accessibilityHint("레슨을 선택하고 준비 정보와 실행 동작을 엽니다.")
                    .accessibilityAddTraits(event.id == selected?.id ? .isSelected : [])
                }
                if events.isEmpty {
                    ContentUnavailableView {
                        Label("오늘은 레슨이 없습니다", systemImage: "cup.and.saucer")
                    } description: {
                        Text("다른 주를 보거나 새 레슨을 추가할 수 있습니다.")
                    }
                    .frame(maxWidth: .infinity, minHeight: 112)
                }
            }
        }
    }

    private func accessibilityValue(for event: CalendarLessonEvent) -> String {
        let attention = event.watchFlags.isEmpty
            ? "주의 사항 없음"
            : "주의 \(event.watchFlags.map(\.label).joined(separator: ", "))"
        return "첫 확인 \(event.firstCheck). \(attention). \(event.syncStatus.label)"
    }
}
