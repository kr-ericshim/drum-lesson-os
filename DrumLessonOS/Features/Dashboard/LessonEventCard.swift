import SwiftUI

struct LessonEventCard: View {
    enum Density {
        case regular
        case compact
    }

    var event: CalendarLessonEvent
    var isSelected: Bool
    var density: Density = .regular
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: density == .compact ? 5 : 7) {
            HStack {
                Text(event.timeLabel)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if shouldShowSyncStatus {
                    if density == .compact {
                        Image(systemName: event.syncStatus.statusIcon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(event.syncStatus.statusTint)
                            .help(event.syncStatus.label)
                            .accessibilityLabel(event.syncStatus.label)
                    } else {
                        StatusBadge(label: event.syncStatus.label, systemImage: event.syncStatus.statusIcon, tint: event.syncStatus.statusTint)
                    }
                }
            }

            Text(event.studentName)
                .font(density == .compact ? .subheadline.weight(.semibold) : .headline)
                .lineLimit(1)

            Text(event.firstCheck)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(density == .compact ? 1 : 2)

            if let flag = event.watchFlags.first {
                Label(flag.label, systemImage: "exclamationmark.circle.fill")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.Accent.teachingForeground)
                    .lineLimit(1)
            }
        }
        .padding(density == .compact ? AppTheme.Spacing.sm : AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: density == .compact ? 84 : 104, alignment: .topLeading)
        .background(cardBackground, in: AppTheme.softPanel)
        .overlay(AppTheme.softPanel.stroke(isSelected ? AppTheme.Accent.teaching.opacity(0.48) : Color.clear, lineWidth: 1))
        .overlay(alignment: .topLeading) {
            if isSelected {
                CountInMark()
                    .padding(.leading, density == .compact ? AppTheme.Spacing.sm : AppTheme.Spacing.md)
                    .offset(y: -1)
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    private var cardBackground: Color {
        if isSelected {
            return AppTheme.Accent.teaching.opacity(0.12)
        }
        return Color.secondary.opacity(isHovering ? 0.10 : 0.055)
    }

    private var shouldShowSyncStatus: Bool {
        density == .regular || event.syncStatus.needsAttention
    }
}
