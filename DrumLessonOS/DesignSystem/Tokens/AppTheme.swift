import SwiftUI

enum AppTheme {
    static let contentWidth: CGFloat = 1_180
    static let compactBreakpoint: CGFloat = 560

    static let panel = RoundedRectangle(cornerRadius: 8, style: .continuous)
    static let softPanel = RoundedRectangle(cornerRadius: 6, style: .continuous)
}

struct WorkbenchPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: AppTheme.panel)
            .overlay(AppTheme.panel.stroke(.separator.opacity(0.45), lineWidth: 1))
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
