import SwiftUI

enum StudentDetailTabsPresentation: Equatable {
    case workspace
    case sessionDrawer
}

struct StudentDetailTabs: View {
    var detail: StudentDetail
    var presentation: StudentDetailTabsPresentation = .workspace
    var onClose: (() -> Void)? = nil
    @State private var selection: Selection = .summary
    @FocusState private var isCloseButtonFocused: Bool

    var body: some View {
        switch presentation {
        case .workspace:
            WorkbenchSurface(.panel, padding: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    WorkbenchHeader(
                        title: "학생 기록",
                        subtitle: "수업 기억, 진도와 최근 노트를 빠르게 확인하세요"
                    )
                    tabPicker
                        .frame(maxWidth: 320)
                    Divider()
                    selectedContent
                }
            }
        case .sessionDrawer:
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    WorkbenchHeader(
                        title: detail.name,
                        subtitle: "레슨 중 참고할 학생 기록"
                    ) {
                        if let onClose {
                            Button {
                                onClose()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.borderless)
                            .focused($isCloseButtonFocused)
                            .help("학생 기록 닫기")
                            .accessibilityLabel("학생 기록 닫기")
                        }
                    }
                    tabPicker
                }
                .padding(AppTheme.Spacing.lg)

                Divider()

                ScrollView {
                    selectedContent
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(AppTheme.Spacing.lg)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .onAppear {
                isCloseButtonFocused = true
            }
        }
    }

    private var tabPicker: some View {
        Picker("학생 기록", selection: $selection) {
            ForEach(Selection.allCases) { item in
                Text(item.label).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selection {
        case .summary:
            SummaryTabView(detail: detail)
        case .progress:
            ProgressTabView(items: detail.progressItems, isCompact: presentation == .sessionDrawer)
        case .notes:
            NotesTabView(notes: detail.recentNotes)
        }
    }

    private enum Selection: String, CaseIterable, Identifiable {
        case summary
        case progress
        case notes

        var id: String { rawValue }

        var label: String {
            switch self {
            case .summary: "요약"
            case .progress: "진도"
            case .notes: "노트"
            }
        }
    }
}

struct SummaryTabView: View {
    var detail: StudentDetail

    var body: some View {
        if detail.nextPlan == nil, detail.assignment == nil, detail.traits.isEmpty {
            ContentUnavailableView(
                "아직 수업 기억이 없습니다",
                systemImage: "person.text.rectangle",
                description: Text("기록 관리 및 편집에서 다음 계획이나 지도 단서를 추가하세요.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xxl)
        } else {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                if let nextPlan = detail.nextPlan {
                    memoryValue(
                        "다음 행동",
                        value: nextPlan.nextAction,
                        systemImage: "arrow.forward.circle.fill",
                        tint: AppTheme.Accent.teachingForeground
                    )
                }
                if let assignment = detail.assignment {
                    memoryValue(
                        "과제",
                        value: "\(assignment.title) · \(assignment.status.label)",
                        systemImage: "checklist",
                        tint: .secondary
                    )
                }

                if !detail.traits.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("지도 단서")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(detail.traits) { trait in
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Text(trait.label)
                                        .font(.subheadline.weight(.semibold))
                                    StatusBadge(label: trait.type.label, tint: .secondary)
                                }
                                Text(trait.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func memoryValue(_ title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.10), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct ProgressTabView: View {
    var items: [StudentProgressItem]
    var isCompact = false

    var body: some View {
        switch StudentDetailTabContentState.progress(items: items) {
        case let .empty(title, systemImage, description):
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(isCompact ? "학생 상세 화면에서 첫 진도 항목을 추가할 수 있습니다." : description)
            )
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xxl)
        case .populated:
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        progressHeader(item)

                        HStack(spacing: AppTheme.Spacing.md) {
                            Label(item.category.label, systemImage: "tag")
                            Label(LessonDateFormatters.displayDate(item.observedOn), systemImage: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let tempo = item.tempoNote, !tempo.isEmpty {
                            Label(tempo, systemImage: "metronome")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        if !item.checkpoints.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("체크포인트")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                ForEach(item.checkpoints) { checkpoint in
                                    checkpointRow(checkpoint)
                                }
                            }
                            .padding(.top, AppTheme.Spacing.xs)
                        }
                    }
                    Divider()
                }
            }
        }
    }

    private func checkpointRow(_ checkpoint: ProgressCheckpointSummary) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(AppTheme.Accent.teaching)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(LessonDateFormatters.displayDate(checkpoint.observedOn))
                        .font(.caption.monospacedDigit().weight(.medium))
                    if let bpm = checkpoint.bpm {
                        Text("\(bpm) BPM")
                            .font(.caption.monospacedDigit().weight(.semibold))
                    }
                    StatusBadge(label: checkpoint.status.label, tint: .secondary)
                }
                if !checkpoint.note.isEmpty {
                    Text(checkpoint.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func progressHeader(_ item: StudentProgressItem) -> some View {
        if isCompact {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(item.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                progressBadges(item)
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text(item.title)
                    .font(.headline)
                Spacer()
                progressBadges(item)
            }
        }
    }

    private func progressBadges(_ item: StudentProgressItem) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            if item.currentFocus {
                StatusBadge(
                    label: "현재 초점",
                    systemImage: "target",
                    tint: AppTheme.Accent.teachingForeground
                )
            }
            StatusBadge(label: item.status.label, tint: .secondary)
        }
    }
}

struct NotesTabView: View {
    var notes: [StudentLessonNote]

    var body: some View {
        switch StudentDetailTabContentState.notes(notes) {
        case let .empty(title, systemImage, description):
            ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xxl)
        case .populated:
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(notes) { note in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Label(LessonDateFormatters.displayDate(note.lessonDate), systemImage: "calendar")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(note.coveredMaterial)
                            .font(.headline)
                        noteDetail("관찰", value: note.observations)
                        noteDetail("연습 과제", value: note.practiceAssigned)
                        noteDetail("다음 확인", value: note.nextStepHint)
                    }
                    Divider()
                }
            }
        }
    }

    private func noteDetail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum StudentDetailTabContentState: Equatable {
    case empty(title: String, systemImage: String, description: String)
    case populated

    static func progress(items: [StudentProgressItem]) -> Self {
        guard items.isEmpty else { return .populated }
        return .empty(
            title: "아직 진도 기록이 없습니다",
            systemImage: "target",
            description: "기록 관리 및 편집을 열어 첫 진도 항목을 추가하세요."
        )
    }

    static func notes(_ notes: [StudentLessonNote]) -> Self {
        guard notes.isEmpty else { return .populated }
        return .empty(
            title: "아직 레슨 노트가 없습니다",
            systemImage: "note.text",
            description: "레슨 노트를 추가하면 이곳에서 최근 기록을 확인할 수 있습니다."
        )
    }
}
