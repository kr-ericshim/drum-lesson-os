import SwiftUI

struct StudentDetailEditorPanel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: StudentDetailViewModel
    var detail: StudentDetail
    let onStudentDeleted: () async -> Void

    @State private var profile: ProfileEditorDraft
    @State private var trait = TraitEditorDraft()
    @State private var progress = ProgressEditorDraft()
    @State private var assignment: AssignmentEditorDraft
    @State private var note = LessonNoteEditorDraft()
    @State private var plan: NextPlanEditorDraft
    @State private var isEditorExpanded = false
    @State private var isShowingDeleteConfirmation = false

    private static let newSelection = "new"

    init(
        viewModel: StudentDetailViewModel,
        detail: StudentDetail,
        onStudentDeleted: @escaping () async -> Void
    ) {
        self.viewModel = viewModel
        self.detail = detail
        self.onStudentDeleted = onStudentDeleted
        _profile = State(initialValue: ProfileEditorDraft(
            cue: detail.profileCue,
            primaryWeakPoint: detail.primaryWeakPoint
        ))
        _assignment = State(initialValue: AssignmentEditorDraft(
            title: detail.assignment?.title ?? "",
            status: detail.assignment?.status ?? .notStarted,
            dueDate: Self.date(from: detail.assignment?.dueDate),
            detail: detail.assignment?.detail ?? ""
        ))
        _plan = State(initialValue: NextPlanEditorDraft(
            plannedFor: Self.date(from: detail.nextPlan?.plannedFor),
            priority: detail.nextPlan?.priority ?? .normal,
            action: detail.nextPlan?.nextAction ?? "",
            detail: detail.nextPlan?.detail ?? ""
        ))
    }

    var body: some View {
        WorkbenchSurface(.quiet, padding: 0) {
            VStack(spacing: 0) {
                Button {
                    toggleEditor()
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(AppTheme.Accent.teachingForeground)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("기록 관리 및 편집")
                                .font(.headline)
                            Text("프로필, 진도, 과제, 노트와 다음 계획을 필요할 때 수정하세요")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: AppTheme.Spacing.md)

                        if viewModel.isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityLabel("저장 중")
                        }

                        disclosureStatus(isExpanded: isEditorExpanded)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(AppTheme.Spacing.lg)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("기록 관리 및 편집")
                .accessibilityValue(isEditorExpanded ? "펼쳐짐" : "접힘")
                .accessibilityHint(isEditorExpanded ? "편집 항목을 접습니다" : "편집 항목을 펼칩니다")

                if isEditorExpanded {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Divider()

                        VStack(spacing: AppTheme.Spacing.sm) {
                            profileEditor
                            traitEditor
                            progressEditor
                            assignmentEditor
                            noteEditor
                            nextPlanEditor
                            studentDeletionSection
                        }

                        if let message = viewModel.errorMessage {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.Semantic.error)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)
                    .transition(.opacity)
                }
            }
        }
        .alert("학생을 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("학생 영구 삭제", role: .destructive) {
                Task {
                    if await viewModel.deleteStudent() {
                        await onStudentDeleted()
                    }
                }
            }
        } message: {
            Text("\(detail.name) 학생의 프로필과 모든 로컬 기록을 영구 삭제합니다. 이 작업은 되돌릴 수 없습니다. Apple 캘린더의 과거 일정은 삭제되지 않습니다.")
        }
    }

    private var profileEditor: some View {
        editorSection(title: "프로필", systemImage: "person.text.rectangle") {
            editorTextField(
                "프로필 단서",
                prompt: "학생을 빠르게 떠올릴 단서",
                text: $profile.cue,
                axis: .vertical
            )
            editorTextField(
                "주요 약점",
                prompt: "수업에서 반복 확인할 약점",
                text: $profile.primaryWeakPoint,
                axis: .vertical
            )
            saveButton("프로필 저장", systemImage: "person.crop.circle.badge.checkmark") {
                await viewModel.saveProfile(
                    name: detail.name,
                    profileCue: profile.cue,
                    primaryWeakPoint: profile.primaryWeakPoint,
                    active: detail.active
                )
            }
        }
    }

    private var traitEditor: some View {
        editorSection(title: "특성", systemImage: "sparkles") {
            Picker("특성", selection: $trait.selection) {
                Text("새 특성").tag(Self.newSelection)
                ForEach(detail.traits) { trait in
                    Text(trait.label).tag(trait.id.uuidString)
                }
            }
            .onChange(of: trait.selection) { _, selection in
                applySelectedTrait(selection)
            }
            Picker("유형", selection: $trait.type) {
                ForEach(StudentTraitType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            editorTextField("라벨", prompt: "예: 짧게 자주", text: $trait.label)
            editorTextField(
                "상세",
                prompt: "이 특성이 수업에 미치는 영향",
                text: $trait.detail,
                axis: .vertical
            )
            saveButton("특성 저장", systemImage: "plus.circle") {
                let traitId = selectedID(from: trait.selection)
                let didSave = await viewModel.saveTrait(
                    traitId: traitId,
                    type: trait.type,
                    label: trait.label,
                    detail: trait.detail
                )
                if didSave, traitId == nil {
                    trait.selection = Self.newSelection
                    applySelectedTrait(Self.newSelection)
                }
            }
        }
    }

    private var progressEditor: some View {
        editorSection(title: "진도", systemImage: "target") {
            Picker("항목", selection: $progress.selection) {
                Text("새 항목").tag(Self.newSelection)
                ForEach(detail.progressItems) { item in
                    Text(item.title).tag(item.id.uuidString)
                }
            }
            .onChange(of: progress.selection) { _, selection in
                applySelectedProgress(selection)
            }
            Picker("분류", selection: $progress.category) {
                ForEach(ProgressCategory.allCases) { category in
                    Text(category.label).tag(category)
                }
            }
            Picker("상태", selection: $progress.status) {
                ForEach(ProgressStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            editorTextField("제목", prompt: "진도 항목 제목", text: $progress.title)
            editorTextField(
                "상세",
                prompt: "현재 상태와 확인할 내용",
                text: $progress.detail,
                axis: .vertical
            )
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    DatePicker("확인 날짜", selection: $progress.observedOn, displayedComponents: .date)
                    editorTextField("템포 메모", prompt: "예: 84 BPM", text: $progress.tempo)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    DatePicker("확인 날짜", selection: $progress.observedOn, displayedComponents: .date)
                    editorTextField("템포 메모", prompt: "예: 84 BPM", text: $progress.tempo)
                }
            }
            Toggle("현재 초점", isOn: $progress.currentFocus)
            HStack {
                saveButton("항목 저장", systemImage: "checkmark.circle") {
                    let progressItemId = selectedID(from: progress.selection)
                    let didSave = await viewModel.saveProgressItem(
                        progressItemId: progressItemId,
                        category: progress.category,
                        status: progress.status,
                        title: progress.title,
                        detail: progress.detail,
                        tempoNote: optional(progress.tempo),
                        observedOn: Self.dateKey(from: progress.observedOn),
                        currentFocus: progress.currentFocus
                    )
                    if didSave, progressItemId == nil {
                        progress.selection = Self.newSelection
                        applySelectedProgress(Self.newSelection)
                    }
                }
                saveButton("상태만 저장", systemImage: "arrow.triangle.2.circlepath") {
                    guard let id = selectedID(from: progress.selection) else { return }
                    await viewModel.saveProgressStatus(progressItemId: id, nextStatus: progress.status)
                }
                .disabled(selectedID(from: progress.selection) == nil)
            }
        }
    }

    private var assignmentEditor: some View {
        editorSection(title: "과제", systemImage: "checklist") {
            editorTextField("제목", prompt: "과제 제목", text: $assignment.title)
            Picker("상태", selection: $assignment.status) {
                ForEach(AssignmentStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            AssignmentDueDatePicker(
                selection: $assignment.dueDate,
                upcomingLessons: viewModel.upcomingLessons
            )
            editorTextField(
                "상세",
                prompt: "연습 방법과 완료 기준",
                text: $assignment.detail,
                axis: .vertical
            )
            saveButton("과제 저장", systemImage: "tray.and.arrow.down") {
                await viewModel.saveAssignment(
                    assignmentId: detail.assignment?.id,
                    title: assignment.title,
                    status: assignment.status,
                    dueDate: assignment.dueDate.map { Self.dateKey(from: $0) },
                    detail: assignment.detail
                )
            }
        }
    }

    private var noteEditor: some View {
        editorSection(title: "레슨 노트", systemImage: "note.text.badge.plus") {
            DatePicker("레슨 날짜", selection: $note.lessonDate, displayedComponents: .date)
            editorTextField(
                "진행한 내용",
                prompt: "이번 레슨에서 다룬 내용",
                text: $note.covered,
                axis: .vertical
            )
            editorTextField(
                "관찰",
                prompt: "학생의 반응과 변화",
                text: $note.observation,
                axis: .vertical
            )
            editorTextField(
                "연습 과제",
                prompt: "다음 레슨 전 연습할 내용",
                text: $note.practice,
                axis: .vertical
            )
            editorTextField(
                "다음 힌트",
                prompt: "다음 레슨에서 먼저 확인할 것",
                text: $note.nextHint,
                axis: .vertical
            )
            saveButton("노트 추가", systemImage: "square.and.pencil") {
                let didSave = await viewModel.saveLessonNote(
                    lessonDate: Self.dateKey(from: note.lessonDate),
                    coveredMaterial: note.covered,
                    observations: note.observation,
                    practiceAssigned: note.practice,
                    nextStepHint: note.nextHint
                )
                if didSave {
                    note.covered = ""
                    note.observation = ""
                    note.practice = ""
                    note.nextHint = ""
                }
            }
        }
    }

    private var nextPlanEditor: some View {
        editorSection(title: "다음 계획", systemImage: "calendar.badge.clock") {
            OptionalDatePicker(title: "예정일", selection: $plan.plannedFor)
            Picker("우선순위", selection: $plan.priority) {
                ForEach(NextLessonPriority.allCases) { priority in
                    Text(priority.label).tag(priority)
                }
            }
            editorTextField(
                "다음 행동",
                prompt: "다음 레슨에서 먼저 할 일",
                text: $plan.action,
                axis: .vertical
            )
            editorTextField(
                "상세",
                prompt: "준비할 내용과 확인 기준",
                text: $plan.detail,
                axis: .vertical
            )
            saveButton("계획 저장", systemImage: "calendar.badge.checkmark") {
                await viewModel.saveNextPlan(
                    planId: detail.nextPlan?.id,
                    plannedFor: plan.plannedFor.map { Self.dateKey(from: $0) },
                    priority: plan.priority,
                    nextAction: plan.action,
                    detail: plan.detail
                )
            }
        }
    }

    private var studentDeletionSection: some View {
        editorSection(title: "학생 삭제", systemImage: "trash") {
            Text("더 이상 보관할 필요가 없는 학생과 연결된 모든 로컬 기록을 삭제합니다.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("학생 영구 삭제", role: .destructive) {
                isShowingDeleteConfirmation = true
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isSaving)
        }
    }

    private func editorTextField(
        _ title: String,
        prompt: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(prompt, text: text, axis: axis)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func editorSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        EditorSection(title: title, systemImage: systemImage, content: content)
    }

    private func toggleEditor() {
        if reduceMotion {
            isEditorExpanded.toggle()
        } else {
            withAnimation(.easeOut(duration: 0.18)) {
                isEditorExpanded.toggle()
            }
        }
    }

    private func disclosureStatus(isExpanded: Bool) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text(isExpanded ? "접기" : "열기")
                .font(.caption.weight(.medium))
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .foregroundStyle(isExpanded ? AppTheme.Accent.teachingForeground : Color.secondary)
        .accessibilityHidden(true)
    }

    private func saveButton(_ title: String, systemImage: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isSaving)
    }

    private func applySelectedTrait(_ selection: String) {
        guard let selectedTrait = detail.traits.first(where: { $0.id.uuidString == selection }) else {
            trait.type = .strength
            trait.label = ""
            trait.detail = ""
            return
        }
        trait.type = selectedTrait.type
        trait.label = selectedTrait.label
        trait.detail = selectedTrait.detail
    }

    private func applySelectedProgress(_ selection: String) {
        guard let item = detail.progressItems.first(where: { $0.id.uuidString == selection }) else {
            progress.category = .song
            progress.status = .inProgress
            progress.title = ""
            progress.detail = ""
            progress.tempo = ""
            progress.observedOn = Date()
            progress.currentFocus = true
            return
        }
        progress.category = item.category
        progress.status = item.status
        progress.title = item.title
        progress.detail = item.detail
        progress.tempo = item.tempoNote ?? ""
        progress.observedOn = Self.date(from: item.observedOn) ?? Date()
        progress.currentFocus = item.currentFocus
    }

    private func selectedID(from selection: String) -> EntityID? {
        guard selection != Self.newSelection else { return nil }
        return UUID(uuidString: selection)
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func date(from dateKey: String?) -> Date? {
        guard let dateKey, !dateKey.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = .iso8601SeoulCompatible
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: dateKey)
    }

    private static func dateKey(from date: Date) -> String {
        DateOnly.string(from: date, timeZone: .current)
    }
}

private struct EditorSection<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    @State private var isHovering = false

    var title: String
    var systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                toggle()
            } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isExpanded ? AppTheme.Accent.teachingForeground : Color.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            isExpanded ? AppTheme.Accent.teaching.opacity(0.14) : Color.secondary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: AppTheme.Spacing.md)

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(isExpanded ? "접기" : "열기")
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .foregroundStyle(isExpanded ? AppTheme.Accent.teachingForeground : Color.secondary)
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
            .accessibilityLabel("\(title) 편집")
            .accessibilityValue(isExpanded ? "펼쳐짐" : "접힘")
            .accessibilityHint(isExpanded ? "편집 내용을 접습니다" : "편집 내용을 펼칩니다")

            if isExpanded {
                Divider()
                    .opacity(0.65)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    content
                }
                .padding(AppTheme.Spacing.md)
                .transition(.opacity)
            }
        }
        .background(backgroundColor, in: AppTheme.softPanel)
        .overlay(
            AppTheme.softPanel.stroke(
                isExpanded ? AppTheme.Accent.teaching.opacity(0.28) : Color.secondary.opacity(0.10),
                lineWidth: 1
            )
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var backgroundColor: Color {
        if isExpanded {
            return AppTheme.surfaceColor(.editor)
        }
        return Color.secondary.opacity(isHovering ? 0.09 : 0.045)
    }

    private func toggle() {
        if reduceMotion {
            isExpanded.toggle()
        } else {
            withAnimation(.easeOut(duration: 0.18)) {
                isExpanded.toggle()
            }
        }
    }
}

private struct OptionalDatePicker: View {
    var title: String
    @Binding var selection: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("설정", isOn: hasSelection)
                    .toggleStyle(.switch)
            }

            if selection != nil {
                DatePicker(title, selection: dateSelection, displayedComponents: .date)
                    .labelsHidden()
            }
        }
    }

    private var hasSelection: Binding<Bool> {
        Binding(
            get: { selection != nil },
            set: { isEnabled in
                selection = isEnabled ? (selection ?? Date()) : nil
            }
        )
    }

    private var dateSelection: Binding<Date> {
        Binding(
            get: { selection ?? Date() },
            set: { selection = $0 }
        )
    }
}

private struct AssignmentDueDatePicker: View {
    @Binding var selection: Date?
    var upcomingLessons: [StudentUpcomingLesson]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            OptionalDatePicker(title: "마감일", selection: $selection)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("수업 기준 빠른 설정")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        lessonButton(at: 0, title: "다음 수업")
                        lessonButton(at: 1, title: "다다음 수업")
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        lessonButton(at: 0, title: "다음 수업")
                        lessonButton(at: 1, title: "다다음 수업")
                    }
                }
            }
        }
    }

    private func lessonButton(at index: Int, title: String) -> some View {
        let lesson = upcomingLessons.indices.contains(index) ? upcomingLessons[index] : nil
        return Button {
            guard let lesson, let date = date(from: lesson.dateKey) else { return }
            selection = date
        } label: {
            Label(
                lesson.map { "\(title) · \(LessonDateFormatters.displayDate($0.dateKey)) \($0.timeLabel)" }
                    ?? "\(title) 없음",
                systemImage: "\(index + 1).circle"
            )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .disabled(lesson == nil)
    }

    private func date(from dateKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = .iso8601SeoulCompatible
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: dateKey)
    }
}

private struct ProfileEditorDraft {
    var cue: String
    var primaryWeakPoint: String
}

private struct TraitEditorDraft {
    var selection = "new"
    var type: StudentTraitType = .strength
    var label = ""
    var detail = ""
}

private struct ProgressEditorDraft {
    var selection = "new"
    var category: ProgressCategory = .song
    var status: ProgressStatus = .inProgress
    var title = ""
    var detail = ""
    var tempo = ""
    var observedOn = Date()
    var currentFocus = true
}

private struct AssignmentEditorDraft {
    var title: String
    var status: AssignmentStatus
    var dueDate: Date?
    var detail: String
}

private struct LessonNoteEditorDraft {
    var lessonDate = Date()
    var covered = ""
    var observation = ""
    var practice = ""
    var nextHint = ""
}

private struct NextPlanEditorDraft {
    var plannedFor: Date?
    var priority: NextLessonPriority
    var action: String
    var detail: String
}
