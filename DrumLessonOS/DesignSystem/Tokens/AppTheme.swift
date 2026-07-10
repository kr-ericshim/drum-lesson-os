import SwiftUI

enum AppTheme {
    static let contentWidth: CGFloat = 1_180
    static let compactBreakpoint: CGFloat = 1_120

    static let workspaceBackground = Color(nsColor: .windowBackgroundColor)

    static let panel = RoundedRectangle(cornerRadius: 8, style: .continuous)
    static let softPanel = RoundedRectangle(cornerRadius: 6, style: .continuous)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum SurfaceRole {
        case canvas
        case panel
        case inspector
        case quiet
        case editor
    }

    enum Accent {
        static let teaching = Color(nsColor: .systemOrange)
        static let teachingForeground = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedRed: 1.00, green: 0.68, blue: 0.28, alpha: 1)
                : NSColor(calibratedRed: 0.37, green: 0.18, blue: 0.03, alpha: 1)
        })
    }

    enum Semantic {
        static let error = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedRed: 1.00, green: 0.48, blue: 0.45, alpha: 1)
                : NSColor(calibratedRed: 0.64, green: 0.05, blue: 0.04, alpha: 1)
        })
        static let success = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedRed: 0.38, green: 0.86, blue: 0.47, alpha: 1)
                : NSColor(calibratedRed: 0.05, green: 0.42, blue: 0.12, alpha: 1)
        })
        static let warning = Accent.teachingForeground
    }

    static func surfaceColor(_ role: SurfaceRole) -> Color {
        switch role {
        case .canvas:
            Color(nsColor: .controlBackgroundColor).opacity(0.72)
        case .panel:
            Color(nsColor: .controlBackgroundColor)
        case .inspector:
            Color(nsColor: .controlBackgroundColor)
        case .quiet:
            Color(nsColor: .controlBackgroundColor).opacity(0.38)
        case .editor:
            Color(nsColor: .controlBackgroundColor).opacity(0.74)
        }
    }

    static func borderColor(_ role: SurfaceRole) -> Color {
        switch role {
        case .canvas:
            Color(nsColor: .separatorColor).opacity(0.52)
        case .inspector:
            Accent.teaching.opacity(0.38)
        case .editor:
            Color.secondary.opacity(0.18)
        case .panel:
            Color(nsColor: .separatorColor).opacity(0.58)
        case .quiet:
            Color.clear
        }
    }
}

struct WorkbenchSurface<Content: View>: View {
    var role: AppTheme.SurfaceRole
    var padding: CGFloat
    let content: Content

    init(_ role: AppTheme.SurfaceRole = .panel, padding: CGFloat = AppTheme.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.role = role
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(AppTheme.surfaceColor(role), in: AppTheme.panel)
            .overlay(AppTheme.panel.stroke(AppTheme.borderColor(role), lineWidth: 1))
            .overlay(alignment: .topLeading) {
                if role == .inspector {
                    CountInMark()
                        .padding(.leading, padding)
                        .offset(y: -1)
                }
            }
    }
}

struct CountInMark: View {
    var tint: Color = AppTheme.Accent.teaching

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { beat in
                Capsule()
                    .fill(tint.opacity(beat == 3 ? 1 : 0.34))
                    .frame(width: beat == 3 ? 16 : 5, height: 3)
            }
        }
        .accessibilityHidden(true)
    }
}

struct WorkbenchPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        WorkbenchSurface(.panel) {
            content
        }
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var titleFont: Font = .headline

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(titleFont)
                .accessibilityAddTraits(.isHeader)
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

struct WorkbenchHeader<Trailing: View>: View {
    var title: String
    var subtitle: String?
    var titleFont: Font = .title3.weight(.semibold)
    let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        titleFont: Font = .title3.weight(.semibold),
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleFont = titleFont
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: title, subtitle: subtitle, titleFont: titleFont)
            trailing
        }
    }
}
