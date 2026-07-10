import SwiftUI

struct StudentRosterView: View {
    @Environment(AppEnvironment.self) private var environment
    var roster: [StudentRosterItem]
    @State private var showingAddStudentSheet = false

    var body: some View {
        WorkbenchSurface(.quiet, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    SectionHeader(title: "학생 준비", subtitle: "활성 학생 \(roster.count)명")
                    Spacer()
                    Button {
                        showingAddStudentSheet = true
                    } label: {
                        Label("추가", systemImage: "person.badge.plus")
                    }
                    .help("학생 추가")
                    .accessibilityLabel("학생 추가")
                    .controlSize(.regular)
                }

                ForEach(roster) { student in
                    StudentRosterRow(student: student)
                }
                if roster.isEmpty {
                    ContentUnavailableView("활성 학생이 없습니다", systemImage: "person.2")
                }
            }
        }
        .sheet(isPresented: $showingAddStudentSheet) {
            AddStudentSheet(writes: environment.writes) { studentId in
                await environment.refresh()
                environment.route = .student(studentId)
            }
        }
    }
}

private struct StudentRosterRow: View {
    @Environment(AppEnvironment.self) private var environment
    var student: StudentRosterItem

    var body: some View {
        Button {
            environment.route = .student(student.id)
        } label: {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(hasAttention ? AppTheme.Accent.teaching.opacity(0.16) : Color.secondary.opacity(0.10))
                    Text(String(student.name.prefix(1)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(hasAttention ? AppTheme.Accent.teachingForeground : .secondary)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(student.name)
                            .font(.headline)
                        if let flag = student.attentionFlags.first {
                            StatusBadge(label: flag.label, tint: AppTheme.Accent.teachingForeground)
                        }
                    }

                    Label(nextAction, systemImage: "target")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(lastLessonLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: AppTheme.Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, AppTheme.Spacing.md)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.sm)
            .background(hasAttention ? AppTheme.Accent.teaching.opacity(0.055) : Color.clear, in: AppTheme.softPanel)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(student.name)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("학생 상세와 수업 준비 정보를 엽니다.")
    }

    private var hasAttention: Bool {
        !student.attentionFlags.isEmpty
    }

    private var nextAction: String {
        student.nextPlan?.nextAction ?? student.currentFocus?.title ?? student.primaryWeakPoint
    }

    private var lastLessonLabel: String {
        if let lastLessonDate = student.lastLessonDate {
            return "마지막 레슨 \(LessonDateFormatters.displayDate(lastLessonDate))"
        }
        return "아직 레슨 기록 없음"
    }

    private var accessibilityValue: String {
        let attention = student.attentionFlags.isEmpty
            ? "주의 사항 없음"
            : "주의 \(student.attentionFlags.map(\.label).joined(separator: ", "))"
        return "첫 확인 \(nextAction). \(attention). \(lastLessonLabel)"
    }
}
