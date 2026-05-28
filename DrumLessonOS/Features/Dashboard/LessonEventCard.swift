import SwiftUI

struct LessonEventCard: View {
    var event: CalendarLessonEvent
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(event.timeLabel)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(label: event.syncStatus.label, systemImage: syncIcon, tint: syncColor)
            }

            Text(event.studentName)
                .font(.headline)
                .lineLimit(1)

            Text(event.firstCheck)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if !event.watchFlags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(event.watchFlags.prefix(2)) { flag in
                        StatusBadge(label: flag.label, tint: .orange)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08), in: AppTheme.softPanel)
        .overlay(AppTheme.softPanel.stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5))
        .contentShape(Rectangle())
    }

    private var syncIcon: String {
        switch event.syncStatus {
        case .synced: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        case .pending: "arrow.triangle.2.circlepath"
        case .disabled: "slash.circle"
        case .notConnected: "calendar.badge.exclamationmark"
        }
    }

    private var syncColor: Color {
        switch event.syncStatus {
        case .synced: .green
        case .failed: .red
        case .pending: .orange
        case .disabled, .notConnected: .secondary
        }
    }
}
