import Accessibility
import SwiftUI

struct StudentDetailView: View {
    @State private var viewModel: StudentDetailViewModel
    @State private var isShowingStudentRecord = false
    private let presentedViewModel: StudentDetailViewModel

    init(viewModel: StudentDetailViewModel) {
        presentedViewModel = viewModel
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                detailContent(detail)
            } else if viewModel.isLoading {
                ContentUnavailableView("학생 정보를 불러오는 중", systemImage: "hourglass")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "학생 정보를 열 수 없습니다",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(viewModel.errorMessage ?? "대시보드에서 새로고침하세요.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.workspaceBackground)
        .task(id: presentedViewModelIdentity) {
            if ownedViewModelIdentity != presentedViewModelIdentity {
                viewModel = presentedViewModel
                isShowingStudentRecord = false
            }
            await viewModel.load()
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
        .onChange(of: viewModel.closeoutStatusMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
        .navigationTitle(viewModel.detail?.name ?? "학생")
    }

    @ViewBuilder
    private func detailContent(_ detail: StudentDetail) -> some View {
        if viewModel.lessonContext != nil {
            GeometryReader { proxy in
                LessonFlowWorkspace(
                    viewModel: viewModel,
                    detail: detail,
                    lessonContext: viewModel.lessonContext,
                    isShowingStudentRecord: $isShowingStudentRecord
                )
                .disabled(isShowingStudentRecord)
                .allowsHitTesting(!isShowingStudentRecord)
                .accessibilityHidden(isShowingStudentRecord)
                .overlay(alignment: .trailing) {
                    if isShowingStudentRecord {
                        StudentDetailTabs(
                            detail: detail,
                            presentation: .sessionDrawer,
                            onClose: { isShowingStudentRecord = false }
                        )
                        .frame(width: min(420, proxy.size.width))
                        .frame(maxHeight: .infinity)
                        .onExitCommand {
                            isShowingStudentRecord = false
                        }
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(Color(nsColor: .separatorColor))
                                .frame(width: 1)
                        }
                    }
                }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    StudentHeaderView(detail: detail)

                    LazyVGrid(
                        columns: [
                            GridItem(
                                .adaptive(minimum: 380, maximum: 580),
                                spacing: AppTheme.Spacing.xl,
                                alignment: .top
                            )
                        ],
                        alignment: .leading,
                        spacing: AppTheme.Spacing.xl
                    ) {
                        LessonFlowWorkspace(
                            viewModel: viewModel,
                            detail: detail,
                            lessonContext: nil
                        )
                        StudentDetailTabs(detail: detail)
                    }

                    StudentDetailEditorPanel(viewModel: viewModel, detail: detail)
                        .id(detail.id)
                }
                .frame(maxWidth: AppTheme.contentWidth)
                .padding(AppTheme.Spacing.xl)
            }
        }
    }

    private var presentedViewModelIdentity: ViewModelIdentity {
        ViewModelIdentity(
            studentId: presentedViewModel.studentId,
            lessonId: presentedViewModel.lessonContext?.id
        )
    }

    private var ownedViewModelIdentity: ViewModelIdentity {
        ViewModelIdentity(
            studentId: viewModel.studentId,
            lessonId: viewModel.lessonContext?.id
        )
    }

    private struct ViewModelIdentity: Hashable {
        var studentId: EntityID
        var lessonId: EntityID?
    }
}

private struct StudentDetailEditorPanel: View {
    @Bindable var viewModel: StudentDetailViewModel
    var detail: StudentDetail

    @State private var profileCue: String
    @State private var primaryWeakPoint: String
    @State private var traitSelection = Self.newSelection
    @State private var traitType: StudentTraitType = .strength
    @State private var traitLabel = ""
    @State private var traitDetail = ""
    @State private var progressSelection = Self.newSelection
    @State private var progressCategory: ProgressCategory = .song
    @State private var progressStatus: ProgressStatus = .inProgress
    @State private var progressTitle = ""
    @State private var progressDetail = ""
    @State private var progressTempo = ""
    @State private var progressObservedOn = Date()
    @State private var progressCurrentFocus = true
    @State private var assignmentTitle: String
    @State private var assignmentStatus: AssignmentStatus
    @State private var assignmentDueDate: Date?
    @State private var assignmentDetail: String
    @State private var noteLessonDate = Date()
    @State private var noteCovered = ""
    @State private var noteObservation = ""
    @State private var notePractice = ""
    @State private var noteNextHint = ""
    @State private var planFor: Date?
    @State private var planPriority: NextLessonPriority
    @State private var planAction: String
    @State private var planDetail: String
    @State private var isEditorExpanded = false

    private static let newSelection = "new"

    init(viewModel: StudentDetailViewModel, detail: StudentDetail) {
        self.viewModel = viewModel
        self.detail = detail
        _profileCue = State(initialValue: detail.profileCue)
        _primaryWeakPoint = State(initialValue: detail.primaryWeakPoint)
        _assignmentTitle = State(initialValue: detail.assignment?.title ?? "")
        _assignmentStatus = State(initialValue: detail.assignment?.status ?? .notStarted)
        _assignmentDueDate = State(initialValue: Self.date(from: detail.assignment?.dueDate))
        _assignmentDetail = State(initialValue: detail.assignment?.detail ?? "")
        _planFor = State(initialValue: Self.date(from: detail.nextPlan?.plannedFor))
        _planPriority = State(initialValue: detail.nextPlan?.priority ?? .normal)
        _planAction = State(initialValue: detail.nextPlan?.nextAction ?? "")
        _planDetail = State(initialValue: detail.nextPlan?.detail ?? "")
    }

    var body: some View {
        WorkbenchSurface(.quiet, padding: 0) {
            DisclosureGroup(isExpanded: $isEditorExpanded) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Divider()

                    VStack(spacing: AppTheme.Spacing.sm) {
                        profileEditor
                        traitEditor
                        progressEditor
                        assignmentEditor
                        noteEditor
                        nextPlanEditor
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
                }
                .padding(AppTheme.Spacing.lg)
            }
        }
    }

    private var profileEditor: some View {
        editorSection(title: "프로필", systemImage: "person.text.rectangle") {
            editorTextField(
                "프로필 단서",
                prompt: "학생을 빠르게 떠올릴 단서",
                text: $profileCue,
                axis: .vertical
            )
            editorTextField(
                "주요 약점",
                prompt: "수업에서 반복 확인할 약점",
                text: $primaryWeakPoint,
                axis: .vertical
            )
            saveButton("프로필 저장", systemImage: "person.crop.circle.badge.checkmark") {
                await viewModel.saveProfile(
                    name: detail.name,
                    profileCue: profileCue,
                    primaryWeakPoint: primaryWeakPoint,
                    active: detail.active
                )
            }
        }
    }

    private var traitEditor: some View {
        editorSection(title: "특성", systemImage: "sparkles") {
            Picker("특성", selection: $traitSelection) {
                Text("새 특성").tag(Self.newSelection)
                ForEach(detail.traits) { trait in
                    Text(trait.label).tag(trait.id.uuidString)
                }
            }
            .onChange(of: traitSelection) { _, selection in
                applySelectedTrait(selection)
            }
            Picker("유형", selection: $traitType) {
                ForEach(StudentTraitType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            editorTextField("라벨", prompt: "예: 짧게 자주", text: $traitLabel)
            editorTextField(
                "상세",
                prompt: "이 특성이 수업에 미치는 영향",
                text: $traitDetail,
                axis: .vertical
            )
            saveButton("특성 저장", systemImage: "plus.circle") {
                let traitId = selectedID(from: traitSelection)
                let didSave = await viewModel.saveTrait(
                    traitId: traitId,
                    type: traitType,
                    label: traitLabel,
                    detail: traitDetail
                )
                if didSave, traitId == nil {
                    traitSelection = Self.newSelection
                    applySelectedTrait(Self.newSelection)
                }
            }
        }
    }

    private var progressEditor: some View {
        editorSection(title: "진도", systemImage: "target") {
            Picker("항목", selection: $progressSelection) {
                Text("새 항목").tag(Self.newSelection)
                ForEach(detail.progressItems) { item in
                    Text(item.title).tag(item.id.uuidString)
                }
            }
            .onChange(of: progressSelection) { _, selection in
                applySelectedProgress(selection)
            }
            Picker("분류", selection: $progressCategory) {
                ForEach(ProgressCategory.allCases) { category in
                    Text(category.label).tag(category)
                }
            }
            Picker("상태", selection: $progressStatus) {
                ForEach(ProgressStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            editorTextField("제목", prompt: "진도 항목 제목", text: $progressTitle)
            editorTextField(
                "상세",
                prompt: "현재 상태와 확인할 내용",
                text: $progressDetail,
                axis: .vertical
            )
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    DatePicker("확인 날짜", selection: $progressObservedOn, displayedComponents: .date)
                    editorTextField("템포 메모", prompt: "예: 84 BPM", text: $progressTempo)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    DatePicker("확인 날짜", selection: $progressObservedOn, displayedComponents: .date)
                    editorTextField("템포 메모", prompt: "예: 84 BPM", text: $progressTempo)
                }
            }
            Toggle("현재 초점", isOn: $progressCurrentFocus)
            HStack {
                saveButton("항목 저장", systemImage: "checkmark.circle") {
                    let progressItemId = selectedID(from: progressSelection)
                    let didSave = await viewModel.saveProgressItem(
                        progressItemId: progressItemId,
                        category: progressCategory,
                        status: progressStatus,
                        title: progressTitle,
                        detail: progressDetail,
                        tempoNote: optional(progressTempo),
                        observedOn: Self.dateKey(from: progressObservedOn),
                        currentFocus: progressCurrentFocus
                    )
                    if didSave, progressItemId == nil {
                        progressSelection = Self.newSelection
                        applySelectedProgress(Self.newSelection)
                    }
                }
                saveButton("상태만 저장", systemImage: "arrow.triangle.2.circlepath") {
                    guard let id = selectedID(from: progressSelection) else { return }
                    await viewModel.saveProgressStatus(progressItemId: id, nextStatus: progressStatus)
                }
                .disabled(selectedID(from: progressSelection) == nil)
            }
        }
    }

    private var assignmentEditor: some View {
        editorSection(title: "과제", systemImage: "checklist") {
            editorTextField("제목", prompt: "과제 제목", text: $assignmentTitle)
            Picker("상태", selection: $assignmentStatus) {
                ForEach(AssignmentStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            OptionalDatePicker(title: "마감일", selection: $assignmentDueDate)
            editorTextField(
                "상세",
                prompt: "연습 방법과 완료 기준",
                text: $assignmentDetail,
                axis: .vertical
            )
            saveButton("과제 저장", systemImage: "tray.and.arrow.down") {
                await viewModel.saveAssignment(
                    assignmentId: detail.assignment?.id,
                    title: assignmentTitle,
                    status: assignmentStatus,
                    dueDate: assignmentDueDate.map { Self.dateKey(from: $0) },
                    detail: assignmentDetail
                )
            }
        }
    }

    private var noteEditor: some View {
        editorSection(title: "레슨 노트", systemImage: "note.text.badge.plus") {
            DatePicker("레슨 날짜", selection: $noteLessonDate, displayedComponents: .date)
            editorTextField(
                "진행한 내용",
                prompt: "이번 레슨에서 다룬 내용",
                text: $noteCovered,
                axis: .vertical
            )
            editorTextField(
                "관찰",
                prompt: "학생의 반응과 변화",
                text: $noteObservation,
                axis: .vertical
            )
            editorTextField(
                "연습 과제",
                prompt: "다음 레슨 전 연습할 내용",
                text: $notePractice,
                axis: .vertical
            )
            editorTextField(
                "다음 힌트",
                prompt: "다음 레슨에서 먼저 확인할 것",
                text: $noteNextHint,
                axis: .vertical
            )
            saveButton("노트 추가", systemImage: "square.and.pencil") {
                let didSave = await viewModel.saveLessonNote(
                    lessonDate: Self.dateKey(from: noteLessonDate),
                    coveredMaterial: noteCovered,
                    observations: noteObservation,
                    practiceAssigned: notePractice,
                    nextStepHint: noteNextHint
                )
                if didSave {
                    noteCovered = ""
                    noteObservation = ""
                    notePractice = ""
                    noteNextHint = ""
                }
            }
        }
    }

    private var nextPlanEditor: some View {
        editorSection(title: "다음 계획", systemImage: "calendar.badge.clock") {
            OptionalDatePicker(title: "예정일", selection: $planFor)
            Picker("우선순위", selection: $planPriority) {
                ForEach(NextLessonPriority.allCases) { priority in
                    Text(priority.label).tag(priority)
                }
            }
            editorTextField(
                "다음 행동",
                prompt: "다음 레슨에서 먼저 할 일",
                text: $planAction,
                axis: .vertical
            )
            editorTextField(
                "상세",
                prompt: "준비할 내용과 확인 기준",
                text: $planDetail,
                axis: .vertical
            )
            saveButton("계획 저장", systemImage: "calendar.badge.checkmark") {
                await viewModel.saveNextPlan(
                    planId: detail.nextPlan?.id,
                    plannedFor: planFor.map { Self.dateKey(from: $0) },
                    priority: planPriority,
                    nextAction: planAction,
                    detail: planDetail
                )
            }
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
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(.top, 8)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: AppTheme.softPanel)
        .overlay(AppTheme.softPanel.stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
        guard let trait = detail.traits.first(where: { $0.id.uuidString == selection }) else {
            traitType = .strength
            traitLabel = ""
            traitDetail = ""
            return
        }
        traitType = trait.type
        traitLabel = trait.label
        traitDetail = trait.detail
    }

    private func applySelectedProgress(_ selection: String) {
        guard let item = detail.progressItems.first(where: { $0.id.uuidString == selection }) else {
            progressCategory = .song
            progressStatus = .inProgress
            progressTitle = ""
            progressDetail = ""
            progressTempo = ""
            progressObservedOn = Date()
            progressCurrentFocus = true
            return
        }
        progressCategory = item.category
        progressStatus = item.status
        progressTitle = item.title
        progressDetail = item.detail
        progressTempo = item.tempoNote ?? ""
        progressObservedOn = Self.date(from: item.observedOn) ?? Date()
        progressCurrentFocus = item.currentFocus
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
