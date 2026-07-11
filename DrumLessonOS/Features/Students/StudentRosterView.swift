import SwiftUI

struct StudentRosterView: View {
    @Environment(AppEnvironment.self) private var environment
    var roster: [StudentRosterItem]
    @State private var showingAddStudentSheet = false
    @State private var searchText = ""
    @State private var selectedFilter = StudentRosterFilter.all

    var body: some View {
        WorkbenchSurface(.quiet, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .top) {
                    SectionHeader(
                        title: "학생 준비",
                        subtitle: resultSubtitle
                    )
                    Spacer()
                    Button {
                        showingAddStudentSheet = true
                    } label: {
                        Label("학생 추가", systemImage: "person.badge.plus")
                            .font(.subheadline.weight(.medium))
                            .frame(minHeight: 32)
                    }
                    .buttonStyle(.borderless)
                    .help("학생 추가")
                    .accessibilityLabel("학생 추가")
                    .controlSize(.small)
                }

                if !roster.isEmpty {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("학생 이름과 수업 단서 검색", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("검색어 지우기")
                            .accessibilityLabel("검색어 지우기")
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .frame(minHeight: 30)
                    .background(Color(nsColor: .textBackgroundColor), in: AppTheme.softPanel)
                    .overlay(AppTheme.softPanel.stroke(Color(nsColor: .separatorColor).opacity(0.72), lineWidth: 1))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            ForEach(StudentRosterFilter.allCases) { filter in
                                Button {
                                    selectedFilter = filter
                                } label: {
                                    Text("\(filter.label) \(StudentRosterQuery.count(filter: filter, in: roster))")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(selectedFilter == filter ? AppTheme.Accent.teaching : .secondary)
                                .accessibilityValue(selectedFilter == filter ? "선택됨" : "")
                            }
                        }
                    }
                }

                if roster.isEmpty {
                    ContentUnavailableView("활성 학생이 없습니다", systemImage: "person.2")
                } else if filteredRoster.isEmpty {
                    ContentUnavailableView(
                        "조건에 맞는 학생이 없습니다",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("검색어를 지우거나 다른 필터를 선택하세요.")
                    )
                } else {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(filteredRoster) { student in
                            StudentRosterRow(student: student)
                        }
                    }
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

    private var filteredRoster: [StudentRosterItem] {
        StudentRosterQuery.filter(roster, searchText: searchText, filter: selectedFilter)
    }

    private var resultSubtitle: String {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, selectedFilter == .all {
            return "활성 학생 \(roster.count)명"
        }
        return "검색 결과 \(filteredRoster.count)명 · 전체 \(roster.count)명"
    }
}

enum StudentRosterFilter: String, CaseIterable, Identifiable {
    case all
    case needsReview
    case highPriority
    case staleNote
    case noCurrentFocus

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "전체"
        case .needsReview: "확인 필요"
        case .highPriority: "높은 우선순위"
        case .staleNote: "최근 노트 없음"
        case .noCurrentFocus: "현재 초점 없음"
        }
    }
}

enum StudentRosterQuery {
    static func filter(
        _ roster: [StudentRosterItem],
        searchText: String,
        filter: StudentRosterFilter
    ) -> [StudentRosterItem] {
        roster.filter { student in
            matches(student, filter: filter) && matches(student, searchText: searchText)
        }
    }

    static func count(filter: StudentRosterFilter, in roster: [StudentRosterItem]) -> Int {
        roster.lazy.filter { matches($0, filter: filter) }.count
    }

    private static func matches(_ student: StudentRosterItem, filter: StudentRosterFilter) -> Bool {
        switch filter {
        case .all:
            true
        case .needsReview:
            student.attentionFlags.contains { $0.kind == .needsAssignmentReview || $0.kind == .upcomingPlan }
        case .highPriority:
            student.nextPlan?.priority == .high
        case .staleNote:
            student.lastLessonDate == nil || student.attentionFlags.contains { $0.kind == .staleLesson }
        case .noCurrentFocus:
            student.currentFocus == nil
        }
    }

    private static func matches(_ student: StudentRosterItem, searchText: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let searchableValues = [
            student.name,
            student.profileCue,
            student.primaryWeakPoint,
            student.currentFocus?.title,
            student.currentFocus?.detail,
            student.nextPlan?.nextAction,
            student.nextPlan?.detail
        ].compactMap { $0 }
        return searchableValues.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

private struct StudentRosterRow: View {
    @Environment(AppEnvironment.self) private var environment
    var student: StudentRosterItem
    @State private var isHovering = false

    var body: some View {
        Button {
            environment.route = .student(student.id)
        } label: {
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
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
                            .lineLimit(1)
                            .layoutPriority(1)
                        if let flag = student.attentionFlags.first {
                            StatusBadge(label: flag.label, tint: AppTheme.Accent.teachingForeground)
                        }
                    }

                    Label(nextAction, systemImage: "target")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.78))
                        .lineLimit(2)

                    Text(lastLessonLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: AppTheme.Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.primary.opacity(isHovering ? 0.055 : 0.025), in: AppTheme.softPanel)
            .overlay(AppTheme.softPanel.stroke(Color.primary.opacity(isHovering ? 0.09 : 0.05), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
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
