import SwiftUI

struct TodayLessonListView: View {
    var events: [CalendarLessonEvent]
    @Binding var selected: CalendarLessonEvent?

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Today", subtitle: "\(events.count) scheduled lessons")
                ForEach(events) { event in
                    LessonEventCard(event: event, isSelected: event.id == selected?.id)
                        .onTapGesture { selected = event }
                }
                if events.isEmpty {
                    ContentUnavailableView("No lessons today", systemImage: "calendar")
                }
            }
        }
    }
}
