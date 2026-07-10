import SwiftUI

struct WeekCalendarView: View {
    var days: [CalendarDay]
    @Binding var selected: CalendarLessonEvent?
    var onAddLesson: () -> Void
    var onMove: (CalendarLessonEvent, String) -> Void
    @State private var draggedEventID: UUID?

    var body: some View {
        WorkbenchSurface(.canvas, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(
                    title: "주간 보기",
                    subtitle: eventCount == 0
                        ? "첫 레슨을 잡으면 이번 주 흐름이 여기에 정리됩니다."
                        : "레슨 카드를 선택하면 첫 확인 항목이 오른쪽에 열립니다."
                )

                if eventCount == 0 {
                    emptyWeek
                } else {
                    populatedWeek
                }
            }
        }
    }

    private var eventCount: Int {
        days.reduce(0) { $0 + $1.events.count }
    }

    private var emptyWeek: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(days) { day in
                    Text(day.label)
                        .font(.caption.weight(day.isToday ? .semibold : .medium))
                        .foregroundStyle(day.isToday ? .primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            day.isToday ? AppTheme.Accent.teaching.opacity(0.14) : Color.clear,
                            in: AppTheme.softPanel
                        )
                }
            }

            Divider()

            EmptyWeekPrompt(onAddLesson: onAddLesson)
        }
    }

    private var populatedWeek: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                ForEach(days) { day in
                    DashboardDayColumn(
                        day: day,
                        allEvents: days.flatMap(\.events),
                        selected: $selected,
                        draggedEventID: $draggedEventID,
                        onMove: onMove
                    )
                }
            }
        }
    }
}

private struct DashboardDayColumn: View {
    var day: CalendarDay
    var allEvents: [CalendarLessonEvent]
    @Binding var selected: CalendarLessonEvent?
    @Binding var draggedEventID: UUID?
    var onMove: (CalendarLessonEvent, String) -> Void
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(day.isToday ? .primary : .secondary)
                if day.isToday {
                    Text("오늘")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.Accent.teachingForeground)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(day.isToday ? AppTheme.Accent.teaching.opacity(0.10) : Color.clear, in: AppTheme.softPanel)

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(day.events) { event in
                    Button {
                        selected = event
                    } label: {
                        LessonEventCard(event: event, isSelected: event.id == selected?.id, density: .compact)
                    }
                    .buttonStyle(.plain)
                    .lessonEventContextActions(for: event)
                    .onDrag {
                        draggedEventID = event.id
                        return LessonEventDragPayload.itemProvider(for: event)
                    } preview: {
                        LessonEventDragPreview(event: event)
                    }
                    .accessibilityLabel("\(day.label) \(event.timeLabel) \(event.studentName) 레슨")
                    .accessibilityValue(lessonAccessibilityValue(for: event))
                    .accessibilityHint("선택하거나 다른 요일로 드래그할 수 있습니다. 우클릭하면 일정 동작을 엽니다.")
                    .accessibilityAddTraits(event.id == selected?.id ? .isSelected : [])
                }

                if day.events.isEmpty {
                    Text("여기로 이동")
                        .font(.caption2)
                        .foregroundStyle(isDropTargeted ? AppTheme.Accent.teachingForeground : Color.clear)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(AppTheme.Spacing.xs)
        .frame(minWidth: 86, maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(isDropTargeted ? AppTheme.Accent.teaching.opacity(0.09) : Color.clear, in: AppTheme.softPanel)
        .overlay(AppTheme.softPanel.stroke(isDropTargeted ? AppTheme.Accent.teaching.opacity(0.42) : Color.clear, lineWidth: 1))
        .contentShape(Rectangle())
        .onDrop(
            of: [LessonEventDragPayload.contentType],
            delegate: DashboardDayDropDelegate(
                dateKey: day.dateKey,
                allEvents: allEvents,
                draggedEventID: $draggedEventID,
                isTargeted: $isDropTargeted,
                onMove: onMove
            )
        )
    }
}

struct WeekAgendaView: View {
    var days: [CalendarDay]
    @Binding var selected: CalendarLessonEvent?
    var onAddLesson: () -> Void
    var onMove: (CalendarLessonEvent, String) -> Void
    @State private var draggedEventID: UUID?

    var body: some View {
        WorkbenchSurface(.canvas, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: "이번 주 레슨", subtitle: "예정된 레슨 \(eventCount)개")

                if scheduledDays.isEmpty {
                    EmptyWeekPrompt(onAddLesson: onAddLesson)
                } else {
                    ForEach(days) { day in
                        DashboardAgendaDay(
                            day: day,
                            allEvents: days.flatMap(\.events),
                            selected: $selected,
                            draggedEventID: $draggedEventID,
                            onMove: onMove
                        )
                    }
                }
            }
        }
    }

    private var scheduledDays: [CalendarDay] {
        days.filter { !$0.events.isEmpty }
    }

    private var eventCount: Int {
        scheduledDays.reduce(0) { $0 + $1.events.count }
    }
}

private struct DashboardAgendaDay: View {
    var day: CalendarDay
    var allEvents: [CalendarLessonEvent]
    @Binding var selected: CalendarLessonEvent?
    @Binding var draggedEventID: UUID?
    var onMove: (CalendarLessonEvent, String) -> Void
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(day.label)
                    .font(.subheadline.weight(.semibold))
                if day.isToday {
                    Text("오늘")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.Accent.teachingForeground)
                }
                if isDropTargeted {
                    Spacer()
                    Text("여기로 이동")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Accent.teachingForeground)
                }
            }

            ForEach(day.events) { event in
                Button {
                    selected = event
                } label: {
                    LessonEventCard(event: event, isSelected: event.id == selected?.id)
                }
                .buttonStyle(.plain)
                .lessonEventContextActions(for: event)
                .onDrag {
                    draggedEventID = event.id
                    return LessonEventDragPayload.itemProvider(for: event)
                } preview: {
                    LessonEventDragPreview(event: event)
                }
                .accessibilityLabel("\(day.label) \(event.timeLabel) \(event.studentName) 레슨")
                .accessibilityValue(lessonAccessibilityValue(for: event))
                .accessibilityHint("선택하거나 다른 날짜로 드래그할 수 있습니다. 우클릭하면 일정 동작을 엽니다.")
                .accessibilityAddTraits(event.id == selected?.id ? .isSelected : [])
            }

            if day.events.isEmpty {
                Text(isDropTargeted ? "여기로 이동" : "일정 없음")
                    .font(.caption)
                    .foregroundStyle(isDropTargeted ? AppTheme.Accent.teachingForeground : Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(isDropTargeted ? AppTheme.Accent.teaching.opacity(0.09) : Color.clear, in: AppTheme.softPanel)
        .overlay(AppTheme.softPanel.stroke(isDropTargeted ? AppTheme.Accent.teaching.opacity(0.42) : Color.clear, lineWidth: 1))
        .contentShape(Rectangle())
        .onDrop(
            of: [LessonEventDragPayload.contentType],
            delegate: DashboardDayDropDelegate(
                dateKey: day.dateKey,
                allEvents: allEvents,
                draggedEventID: $draggedEventID,
                isTargeted: $isDropTargeted,
                onMove: onMove
            )
        )
    }
}

private struct DashboardDayDropDelegate: DropDelegate {
    var dateKey: String
    var allEvents: [CalendarLessonEvent]
    @Binding var draggedEventID: UUID?
    @Binding var isTargeted: Bool
    var onMove: (CalendarLessonEvent, String) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        draggedEventID != nil && info.hasItemsConforming(to: [LessonEventDragPayload.contentType])
    }

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            isTargeted = false
            draggedEventID = nil
        }
        guard let draggedEventID,
              let event = allEvents.first(where: { $0.id == draggedEventID }) else {
            return false
        }
        onMove(event, dateKey)
        return true
    }
}

private func lessonAccessibilityValue(for event: CalendarLessonEvent) -> String {
    let attention = event.watchFlags.isEmpty
        ? "주의 사항 없음"
        : "주의 \(event.watchFlags.map(\.label).joined(separator: ", "))"
    return "첫 확인 \(event.firstCheck). \(attention). \(event.syncStatus.label)"
}

private struct EmptyWeekPrompt: View {
    var onAddLesson: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.Accent.teaching.opacity(0.14))
                Image(systemName: "calendar.badge.plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.Accent.teachingForeground)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("이번 주 첫 레슨을 잡아보세요")
                    .font(.headline)
                Text("학생과 시간을 고르면 캘린더와 준비 흐름에 바로 반영됩니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppTheme.Spacing.md)

            Button(action: onAddLesson) {
                Label("첫 레슨 잡기", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}
