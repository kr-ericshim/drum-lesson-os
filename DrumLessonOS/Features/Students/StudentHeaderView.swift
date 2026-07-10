import SwiftUI

struct StudentHeaderView: View {
    var detail: StudentDetail

    var body: some View {
        WorkbenchSurface(.canvas, padding: AppTheme.Spacing.xl) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AppTheme.Spacing.xxl) {
                    identity
                    Spacer(minLength: AppTheme.Spacing.xl)
                    recordSummary
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    identity
                    recordSummary
                }
            }
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                CountInMark()
                Text("학생 브리핑")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Accent.teachingForeground)
            }

            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
                Text(detail.name)
                    .font(.title.weight(.bold))
                StatusBadge(
                    label: detail.active ? "활성" : "비활성",
                    systemImage: detail.active ? "checkmark.circle.fill" : "pause.circle",
                    tint: detail.active ? AppTheme.Semantic.success : .secondary
                )
            }

            Text(detail.profileCue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var recordSummary: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            summaryValue(
                title: "최근 레슨",
                value: detail.recentNotes.first.map { LessonDateFormatters.displayDate($0.lessonDate) } ?? "기록 없음",
                systemImage: "calendar"
            )
            summaryValue(
                title: "진도",
                value: "\(detail.progressItems.count)개",
                systemImage: "target"
            )
            summaryValue(
                title: "수업 단서",
                value: "\(detail.traits.count)개",
                systemImage: "sparkles"
            )
        }
    }

    private func summaryValue(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
