import SwiftUI

struct WeekCalendarView: View {
    var days: [CalendarDay]
    @Binding var selected: CalendarLessonEvent?

    var body: some View {
        WorkbenchPanel {
            Grid(alignment: .topLeading, horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    ForEach(days) { day in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(day.label)
                                    .font(.subheadline.weight(.semibold))
                                if day.isToday {
                                    StatusBadge(label: "Today", systemImage: nil, tint: .green)
                                }
                            }
                            .frame(height: 28, alignment: .leading)

                            VStack(spacing: 8) {
                                ForEach(day.events) { event in
                                    LessonEventCard(event: event, isSelected: event.id == selected?.id)
                                        .onTapGesture { selected = event }
                                        .accessibilityAddTraits(.isButton)
                                }

                                if day.events.isEmpty {
                                    Text("No lessons")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .frame(maxWidth: .infinity, minHeight: 72)
                                }
                            }
                        }
                        .frame(minWidth: 92, maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
    }
}
