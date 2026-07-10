import SwiftUI

struct CalendarView: View {
    @Environment(AppEnvironment.self) private var environment
    @Bindable var viewModel: DashboardViewModel
    @State private var isInspectorPresented = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.Accent.teaching.opacity(0.14))
                    Image(systemName: "calendar")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Accent.teachingForeground)
                }
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("레슨 캘린더")
                        .font(.title2.weight(.semibold))
                    Text(viewModel.model?.weekTitle ?? "주간 레슨 시간표")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let model = viewModel.model {
                    Label("이번 주 \(model.days.flatMap(\.events).count)", systemImage: "music.note.list")
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage = viewModel.errorMessage, viewModel.model != nil {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.Semantic.error)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.isLoading && viewModel.model == nil {
                ProgressView("캘린더를 불러오는 중…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let model = viewModel.model {
                WeekTimeGridView(
                    days: model.days,
                    selected: $viewModel.selectedEvent,
                    onMove: moveOccurrence
                )
            } else {
                ContentUnavailableView {
                    Label("캘린더를 불러올 수 없습니다", systemImage: "calendar.badge.exclamationmark")
                } description: {
                    Text(viewModel.errorMessage ?? "이 Mac의 레슨 데이터를 다시 불러와 주세요.")
                } actions: {
                    Button("다시 불러오기") {
                        Task { await viewModel.load() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.xxl)
        .background(AppTheme.workspaceBackground)
        .inspector(isPresented: $isInspectorPresented) {
            ScrollView {
                SelectedLessonPanel(event: viewModel.selectedEvent)
                    .padding(AppTheme.Spacing.lg)
            }
            .inspectorColumnWidth(min: 300, ideal: 336, max: 420)
        }
        .onChange(of: viewModel.selectedEvent) { _, event in
            if event != nil {
                isInspectorPresented = true
            }
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
        }
        .task {
            await environment.refresh()
        }
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
                    isInspectorPresented.toggle()
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .help(isInspectorPresented ? "레슨 정보 닫기" : "레슨 정보 열기")
                .accessibilityLabel(isInspectorPresented ? "레슨 정보 닫기" : "레슨 정보 열기")

                Button {
                    viewModel.presentScheduleSheet()
                } label: {
                    Label("레슨 추가", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .help("레슨 추가")
            }
        }
        .navigationTitle("캘린더")
    }

    private func moveOccurrence(_ event: CalendarLessonEvent, to dateKey: String, minuteOfDay: Int) {
        Task {
            await viewModel.moveOccurrence(event, toDateKey: dateKey, minuteOfDay: minuteOfDay)
        }
    }
}

private struct WeekTimeGridView: View {
    var days: [CalendarDay]
    @Binding var selected: CalendarLessonEvent?
    var onMove: (CalendarLessonEvent, String, Int) -> Void
    @State private var draggedEventID: UUID?

    private let axisWidth: CGFloat = 56
    private let minimumDayWidth: CGFloat = 112
    private let hourHeight: CGFloat = 72

    var body: some View {
        WorkbenchSurface(.canvas, padding: 0) {
            GeometryReader { proxy in
                let scale = TimelineScale(events: days.flatMap(\.events))
                let contentWidth = max(
                    proxy.size.width,
                    axisWidth + minimumDayWidth * CGFloat(max(days.count, 1))
                )

                ScrollView(.horizontal) {
                    VStack(spacing: 0) {
                        timelineHeader
                            .frame(width: contentWidth)

                        Divider()

                        ScrollView(.vertical) {
                            HStack(alignment: .top, spacing: 0) {
                                TimelineTimeAxis(scale: scale, hourHeight: hourHeight)
                                    .frame(width: axisWidth)

                                ForEach(days) { day in
                                    TimelineDayColumn(
                                        day: day,
                                        allEvents: days.flatMap(\.events),
                                        selected: $selected,
                                        draggedEventID: $draggedEventID,
                                        scale: scale,
                                        hourHeight: hourHeight,
                                        onMove: onMove
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(width: contentWidth)
                        }
                    }
                    .frame(width: contentWidth)
                }
            }
        }
        .frame(minHeight: 520)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("주간 레슨 시간표")
    }

    private var timelineHeader: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("시간")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("15분")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .frame(
                minWidth: axisWidth,
                maxWidth: axisWidth,
                minHeight: 58,
                alignment: .leading
            )

            ForEach(days) { day in
                VStack(spacing: 3) {
                    Text(day.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(day.isToday ? .primary : .secondary)
                    if day.isToday {
                        Text("오늘")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.Accent.teachingForeground)
                    } else {
                        Text(" ")
                            .font(.caption2)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(day.isToday ? AppTheme.Accent.teaching.opacity(0.08) : Color.clear)
            }
        }
    }
}

private struct TimelineScale {
    var startMinute: Int
    var endMinute: Int

    init(events: [CalendarLessonEvent]) {
        let eventStarts = events.compactMap(TimelinePlacement.startMinute)
        let eventEnds = events.compactMap { event in
            TimelinePlacement.startMinute(event).map { start in
                start + max(event.durationMinutes, 15)
            }
        }
        let earliest = eventStarts.min() ?? 8 * 60
        let latest = eventEnds.max() ?? 23 * 60
        startMinute = max(0, min(8 * 60, (earliest / 60) * 60))
        endMinute = min(24 * 60, max(23 * 60, ((latest + 59) / 60) * 60))
    }

    var hourCount: Int {
        max(1, (endMinute - startMinute) / 60)
    }

    func yOffset(for minuteOfDay: Int, hourHeight: CGFloat) -> CGFloat {
        CGFloat(minuteOfDay - startMinute) / 60 * hourHeight
    }
}

private enum TimelinePlacement {
    static func startMinute(_ event: CalendarLessonEvent) -> Int? {
        guard let date = ISO8601DateFormatter.withFractions.date(from: event.startsAt)
            ?? ISO8601DateFormatter.plain.date(from: event.startsAt),
              let timeZone = TimeZone(identifier: event.timezone) else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        return hour * 60 + minute
    }
}

private struct TimelineTimeAxis: View {
    var scale: TimelineScale
    var hourHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            ForEach(0...scale.hourCount, id: \.self) { hourOffset in
                Text(timeLabel(for: scale.startMinute + hourOffset * 60))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.trailing, AppTheme.Spacing.sm)
                    .offset(y: hourOffset == 0 ? 3 : CGFloat(hourOffset) * hourHeight - 7)
            }
        }
        .frame(height: CGFloat(scale.hourCount) * hourHeight)
    }

    private func timeLabel(for minute: Int) -> String {
        String(format: "%02d:00", min(minute / 60, 24))
    }
}

private struct TimelineDayColumn: View {
    var day: CalendarDay
    var allEvents: [CalendarLessonEvent]
    @Binding var selected: CalendarLessonEvent?
    @Binding var draggedEventID: UUID?
    var scale: TimelineScale
    var hourHeight: CGFloat
    var onMove: (CalendarLessonEvent, String, Int) -> Void
    @State private var isDropTargeted = false

    var body: some View {
        ZStack(alignment: .top) {
            timelineGrid

            ForEach(day.events) { event in
                if let minute = TimelinePlacement.startMinute(event) {
                    let rawHeight = CGFloat(max(event.durationMinutes, 15)) / 60 * hourHeight
                    Button {
                        selected = event
                    } label: {
                        TimelineLessonCard(event: event, height: rawHeight)
                    }
                    .buttonStyle(.plain)
                    .lessonEventContextActions(for: event)
                    .onDrag {
                        draggedEventID = event.id
                        return LessonEventDragPayload.itemProvider(for: event)
                    } preview: {
                        LessonEventDragPreview(event: event)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 3)
                    .offset(y: scale.yOffset(for: minute, hourHeight: hourHeight) + 2)
                    .accessibilityLabel("\(day.label) \(event.timeLabel) \(event.studentName) 레슨")
                    .accessibilityValue("\(event.durationMinutes)분. 첫 확인 \(event.firstCheck). \(event.syncStatus.label)")
                    .accessibilityHint("선택하거나 다른 시간으로 드래그할 수 있습니다. 우클릭하면 일정 동작을 엽니다.")
                    .accessibilityAddTraits(event.id == selected?.id ? .isSelected : [])
                }
            }
        }
        .frame(height: CGFloat(scale.hourCount) * hourHeight)
        .background(isDropTargeted ? AppTheme.Accent.teaching.opacity(0.07) : Color.clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.52))
                .frame(width: 1)
        }
        .contentShape(Rectangle())
        .onDrop(
            of: [LessonEventDragPayload.contentType],
            delegate: TimelineDayDropDelegate(
                day: day,
                allEvents: allEvents,
                draggedEventID: $draggedEventID,
                isTargeted: $isDropTargeted,
                scale: scale,
                hourHeight: hourHeight,
                onMove: onMove
            )
        )
    }

    private var timelineGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<scale.hourCount, id: \.self) { _ in
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(Color.clear)
                    Divider()
                    Divider()
                        .opacity(0.34)
                        .offset(y: hourHeight / 2)
                }
                .frame(height: hourHeight)
            }
        }
    }
}

private struct TimelineDayDropDelegate: DropDelegate {
    var day: CalendarDay
    var allEvents: [CalendarLessonEvent]
    @Binding var draggedEventID: UUID?
    @Binding var isTargeted: Bool
    var scale: TimelineScale
    var hourHeight: CGFloat
    var onMove: (CalendarLessonEvent, String, Int) -> Void

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
        let rawMinute = scale.startMinute + Int((info.location.y / hourHeight) * 60)
        let snappedMinute = ((rawMinute + 7) / 15) * 15
        let latestStart = max(scale.startMinute, scale.endMinute - max(event.durationMinutes, 15))
        let resolvedMinute = min(max(snappedMinute, scale.startMinute), latestStart)
        onMove(event, day.dateKey, resolvedMinute)
        return true
    }
}

private struct TimelineLessonCard: View {
    var event: CalendarLessonEvent
    var height: CGFloat
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Text(event.studentName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 2)
                if event.syncStatus.needsAttention {
                    Image(systemName: event.syncStatus.statusIcon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(event.syncStatus.statusTint)
                        .help(event.syncStatus.label)
                }
            }

            Text("\(event.timeLabel) · \(event.durationMinutes)분")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if height >= 54 {
                Text(event.firstCheck)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(height >= 72 ? 2 : 1)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: max(20, height - 4), maxHeight: max(20, height - 4), alignment: .topLeading)
        .background(
            AppTheme.Accent.teaching.opacity(isHovering ? 0.18 : 0.11),
            in: AppTheme.softPanel
        )
        .overlay(AppTheme.softPanel.stroke(AppTheme.Accent.teaching.opacity(0.32), lineWidth: 1))
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}
