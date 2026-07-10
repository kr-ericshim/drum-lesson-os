import SwiftUI

struct StatusBadge: View {
    var label: String
    var systemImage: String?
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
                    .foregroundStyle(tint)
            } else {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }
            Text(label)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.16), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

extension NativeCalendarSyncStatus {
    var statusIcon: String {
        switch self {
        case .synced: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        case .pending: "arrow.triangle.2.circlepath"
        case .disabled: "slash.circle"
        case .notConnected: "calendar.badge.exclamationmark"
        }
    }

    var statusTint: Color {
        switch self {
        case .synced: AppTheme.Semantic.success
        case .failed: AppTheme.Semantic.error
        case .pending: AppTheme.Semantic.warning
        case .disabled, .notConnected: .secondary
        }
    }

    var needsAttention: Bool {
        switch self {
        case .failed, .pending, .notConnected: true
        case .synced, .disabled: false
        }
    }
}
