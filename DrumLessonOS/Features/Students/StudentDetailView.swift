import SwiftUI

struct StudentDetailView: View {
    @Bindable var viewModel: StudentDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let detail = viewModel.detail {
                    StudentHeaderView(detail: detail)
                    LessonFlowWorkspace(viewModel: viewModel, detail: detail, lessonContext: viewModel.lessonContext)
                    StudentDetailEditorPanel(viewModel: viewModel, detail: detail)
                        .id(detail)
                    StudentDetailTabs(detail: detail)
                } else if viewModel.isLoading {
                    ContentUnavailableView("Loading student", systemImage: "hourglass")
                } else {
                    ContentUnavailableView(
                        "Student unavailable",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(viewModel.errorMessage ?? "Refresh from the dashboard.")
                    )
                }
            }
            .frame(maxWidth: AppTheme.contentWidth)
            .padding(20)
        }
        .task { await viewModel.load() }
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
    @State private var progressObservedOn = DateOnly.today(in: .current)
    @State private var progressCurrentFocus = true
    @State private var assignmentTitle: String
    @State private var assignmentStatus: AssignmentStatus
    @State private var assignmentDueDate: String
    @State private var assignmentDetail: String
    @State private var noteLessonDate = DateOnly.today(in: .current)
    @State private var noteCovered = ""
    @State private var noteObservation = ""
    @State private var notePractice = ""
    @State private var noteNextHint = ""
    @State private var planFor: String
    @State private var planPriority: NextLessonPriority
    @State private var planAction: String
    @State private var planDetail: String

    private static let newSelection = "new"

    init(viewModel: StudentDetailViewModel, detail: StudentDetail) {
        self.viewModel = viewModel
        self.detail = detail
        _profileCue = State(initialValue: detail.profileCue)
        _primaryWeakPoint = State(initialValue: detail.primaryWeakPoint)
        _assignmentTitle = State(initialValue: detail.assignment?.title ?? "")
        _assignmentStatus = State(initialValue: detail.assignment?.status ?? .notStarted)
        _assignmentDueDate = State(initialValue: detail.assignment?.dueDate ?? "")
        _assignmentDetail = State(initialValue: detail.assignment?.detail ?? "")
        _planFor = State(initialValue: detail.nextPlan?.plannedFor ?? "")
        _planPriority = State(initialValue: detail.nextPlan?.priority ?? .normal)
        _planAction = State(initialValue: detail.nextPlan?.nextAction ?? "")
        _planDetail = State(initialValue: detail.nextPlan?.detail ?? "")
    }

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    SectionHeader(title: "Teaching Workbench", subtitle: "Fast edits for the next lesson loop")
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), alignment: .top)], alignment: .leading, spacing: 16) {
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
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var profileEditor: some View {
        editorSection(title: "Profile", systemImage: "person.text.rectangle") {
            TextField("Profile cue", text: $profileCue, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Weak point", text: $primaryWeakPoint, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            saveButton("Save Profile", systemImage: "person.crop.circle.badge.checkmark") {
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
        editorSection(title: "Trait", systemImage: "sparkles") {
            Picker("Trait", selection: $traitSelection) {
                Text("New trait").tag(Self.newSelection)
                ForEach(detail.traits) { trait in
                    Text(trait.label).tag(trait.id.uuidString)
                }
            }
            .onChange(of: traitSelection) { _, selection in
                applySelectedTrait(selection)
            }
            Picker("Type", selection: $traitType) {
                ForEach(StudentTraitType.allCases) { type in
                    Text(type.rawValue.replacingOccurrences(of: "_", with: " ")).tag(type)
                }
            }
            TextField("Label", text: $traitLabel)
                .textFieldStyle(.roundedBorder)
            TextField("Detail", text: $traitDetail, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            saveButton("Save Trait", systemImage: "plus.circle") {
                await viewModel.saveTrait(
                    traitId: selectedID(from: traitSelection),
                    type: traitType,
                    label: traitLabel,
                    detail: traitDetail
                )
            }
        }
    }

    private var progressEditor: some View {
        editorSection(title: "Progress", systemImage: "target") {
            Picker("Item", selection: $progressSelection) {
                Text("New item").tag(Self.newSelection)
                ForEach(detail.progressItems) { item in
                    Text(item.title).tag(item.id.uuidString)
                }
            }
            .onChange(of: progressSelection) { _, selection in
                applySelectedProgress(selection)
            }
            Picker("Category", selection: $progressCategory) {
                ForEach(ProgressCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            Picker("Status", selection: $progressStatus) {
                ForEach(ProgressStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            TextField("Title", text: $progressTitle)
                .textFieldStyle(.roundedBorder)
            TextField("Detail", text: $progressDetail, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("YYYY-MM-DD", text: $progressObservedOn)
                    .textFieldStyle(.roundedBorder)
                TextField("Tempo", text: $progressTempo)
                    .textFieldStyle(.roundedBorder)
            }
            Toggle("Current focus", isOn: $progressCurrentFocus)
            HStack {
                saveButton("Save Item", systemImage: "checkmark.circle") {
                    await viewModel.saveProgressItem(
                        progressItemId: selectedID(from: progressSelection),
                        category: progressCategory,
                        status: progressStatus,
                        title: progressTitle,
                        detail: progressDetail,
                        tempoNote: optional(progressTempo),
                        observedOn: progressObservedOn,
                        currentFocus: progressCurrentFocus
                    )
                }
                saveButton("Status Only", systemImage: "arrow.triangle.2.circlepath") {
                    guard let id = selectedID(from: progressSelection) else { return }
                    await viewModel.saveProgressStatus(progressItemId: id, nextStatus: progressStatus)
                }
                .disabled(selectedID(from: progressSelection) == nil)
            }
        }
    }

    private var assignmentEditor: some View {
        editorSection(title: "Assignment", systemImage: "checklist") {
            TextField("Title", text: $assignmentTitle)
                .textFieldStyle(.roundedBorder)
            Picker("Status", selection: $assignmentStatus) {
                ForEach(AssignmentStatus.allCases) { status in
                    Text(status.rawValue.replacingOccurrences(of: "_", with: " ")).tag(status)
                }
            }
            TextField("Due date", text: $assignmentDueDate)
                .textFieldStyle(.roundedBorder)
            TextField("Detail", text: $assignmentDetail, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            saveButton("Save Assignment", systemImage: "tray.and.arrow.down") {
                await viewModel.saveAssignment(
                    assignmentId: detail.assignment?.id,
                    title: assignmentTitle,
                    status: assignmentStatus,
                    dueDate: optional(assignmentDueDate),
                    detail: assignmentDetail
                )
            }
        }
    }

    private var noteEditor: some View {
        editorSection(title: "Lesson Note", systemImage: "note.text.badge.plus") {
            TextField("Lesson date", text: $noteLessonDate)
                .textFieldStyle(.roundedBorder)
            TextField("Covered", text: $noteCovered, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Observation", text: $noteObservation, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Practice", text: $notePractice, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Next hint", text: $noteNextHint, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            saveButton("Add Note", systemImage: "square.and.pencil") {
                await viewModel.saveLessonNote(
                    lessonDate: noteLessonDate,
                    coveredMaterial: noteCovered,
                    observations: noteObservation,
                    practiceAssigned: notePractice,
                    nextStepHint: noteNextHint
                )
            }
        }
    }

    private var nextPlanEditor: some View {
        editorSection(title: "Next Plan", systemImage: "calendar.badge.clock") {
            TextField("Planned for", text: $planFor)
                .textFieldStyle(.roundedBorder)
            Picker("Priority", selection: $planPriority) {
                ForEach(NextLessonPriority.allCases) { priority in
                    Text(priority.rawValue).tag(priority)
                }
            }
            TextField("Next action", text: $planAction, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Detail", text: $planDetail, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            saveButton("Save Plan", systemImage: "calendar.badge.checkmark") {
                await viewModel.saveNextPlan(
                    planId: detail.nextPlan?.id,
                    plannedFor: optional(planFor),
                    priority: planPriority,
                    nextAction: planAction,
                    detail: planDetail
                )
            }
        }
    }

    private func editorSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
            content()
        }
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
            progressObservedOn = DateOnly.today(in: .current)
            progressCurrentFocus = true
            return
        }
        progressCategory = item.category
        progressStatus = item.status
        progressTitle = item.title
        progressDetail = item.detail
        progressTempo = item.tempoNote ?? ""
        progressObservedOn = item.observedOn
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
}
