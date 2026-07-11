import SwiftUI

struct LessonFlowWorkspace: View {
    @Bindable var viewModel: StudentDetailViewModel
    var detail: StudentDetail
    var lessonContext: CalendarLessonEvent?
    var isShowingStudentRecord: Binding<Bool> = .constant(false)

    var body: some View {
        if let lessonContext {
            ActiveLessonWorkspace(
                viewModel: viewModel,
                detail: detail,
                event: lessonContext,
                isShowingStudentRecord: isShowingStudentRecord
            )
        } else {
            LessonBriefView(brief: detail.lessonBrief)
        }
    }
}

private struct ActiveLessonWorkspace: View {
    @Bindable var viewModel: StudentDetailViewModel
    var detail: StudentDetail
    var event: CalendarLessonEvent
    @Binding var isShowingStudentRecord: Bool

    private let contentMaxWidth: CGFloat = 1_120
    private let columns = [
        GridItem(
            .adaptive(minimum: 380, maximum: 550),
            spacing: AppTheme.Spacing.xl,
            alignment: .top
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            LessonSessionHeader(
                detail: detail,
                event: event,
                didFinish: viewModel.closeoutStatusMessage != nil,
                isShowingStudentRecord: $isShowingStudentRecord
            )

            Divider()

            ScrollView {
                LazyVGrid(
                    columns: columns,
                    alignment: .leading,
                    spacing: AppTheme.Spacing.xl
                ) {
                    LessonFocusPanel(
                        viewModel: viewModel,
                        detail: detail,
                        observedOn: event.dateKey
                    )
                    LessonRunPanelView(viewModel: viewModel)
                }
                .frame(maxWidth: contentMaxWidth, alignment: .top)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.xxl)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .background(AppTheme.workspaceBackground)
    }
}

private struct LessonSessionHeader: View {
    var detail: StudentDetail
    var event: CalendarLessonEvent
    var didFinish: Bool
    @Binding var isShowingStudentRecord: Bool
    @FocusState private var isRecordButtonFocused: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.xl) {
                identity
                Spacer(minLength: AppTheme.Spacing.xl)
                sessionActions
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                identity
                sessionActions
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Label(
                didFinish ? "레슨 기록 완료" : "레슨 진행 중",
                systemImage: didFinish ? "checkmark.circle.fill" : "play.circle.fill"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(didFinish ? AppTheme.Semantic.success : AppTheme.Accent.teachingForeground)

            Text(detail.name)
                .font(.title2.weight(.semibold))

            Text(detail.profileCue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sessionActions: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            metadata

            Button {
                isShowingStudentRecord.toggle()
            } label: {
                Label("학생 기록", systemImage: "sidebar.right")
            }
            .buttonStyle(.bordered)
            .focused($isRecordButtonFocused)
            .help(isShowingStudentRecord ? "학생 기록 닫기" : "학생 기록 열기")
            .accessibilityValue(isShowingStudentRecord ? "열림" : "닫힘")
            .onChange(of: isShowingStudentRecord) { _, isPresented in
                if !isPresented {
                    isRecordButtonFocused = true
                }
            }
        }
    }

    private var metadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.Spacing.md) {
                lessonTime
                duration
                syncStatus
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.md) {
                    lessonTime
                    duration
                }
                syncStatus
            }
        }
    }

    private var lessonTime: some View {
        Label(
            "\(LessonDateFormatters.displayDate(event.dateKey)) · \(event.timeLabel)",
            systemImage: "calendar.badge.clock"
        )
        .font(.subheadline.monospacedDigit().weight(.medium))
    }

    private var duration: some View {
        Text("\(event.durationMinutes)분")
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var syncStatus: some View {
        if event.syncStatus.needsAttention {
            StatusBadge(
                label: event.syncStatus.label,
                systemImage: event.syncStatus.statusIcon,
                tint: event.syncStatus.statusTint
            )
        }
    }
}

private struct LessonFocusPanel: View {
    @Bindable var viewModel: StudentDetailViewModel
    var detail: StudentDetail
    var observedOn: String

    private var brief: LessonBrief { detail.lessonBrief }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .center) {
                    Text("첫 확인")
                        .font(.headline)
                        .foregroundStyle(AppTheme.Accent.teachingForeground)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    CountInMark()
                }

                Text(brief.firstCheck)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(AppTheme.Accent.teaching.opacity(0.22))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                if let assignment = brief.assignmentCue {
                    contextRow(
                        title: "확인할 과제",
                        value: assignment,
                        systemImage: "checklist"
                    )
                }

                if let focus = detail.currentFocus, focus.title != brief.firstCheck {
                    contextRow(
                        title: "현재 진도",
                        value: "\(focus.title) · \(focus.status.label)",
                        systemImage: "target"
                    )
                }

                if brief.weakPointBrief != brief.firstCheck {
                    contextRow(
                        title: "반복 약점",
                        value: brief.weakPointBrief,
                        systemImage: "scope"
                    )
                }

                if let observation = brief.recentObservation {
                    contextRow(
                        title: "최근 관찰",
                        value: observation,
                        systemImage: "quote.bubble"
                    )
                }
            }

            if let focus = detail.currentFocus {
                Divider()
                    .overlay(AppTheme.Accent.teaching.opacity(0.22))

                ProgressCheckpointCapture(
                    viewModel: viewModel,
                    focus: focus,
                    observedOn: observedOn
                )
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(AppTheme.Accent.teaching.opacity(0.075), in: AppTheme.panel)
        .overlay(AppTheme.panel.stroke(AppTheme.Accent.teaching.opacity(0.24), lineWidth: 1))
    }

    private func contextRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: systemImage)
                .frame(width: 18)
                .foregroundStyle(AppTheme.Accent.teachingForeground)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProgressCheckpointCapture: View {
    @Bindable var viewModel: StudentDetailViewModel
    var focus: ProgressFocusSummary
    var observedOn: String

    @State private var bpm = ""
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Label("오늘 체크포인트", systemImage: "metronome")
                    .font(.subheadline.weight(.semibold))
                Text("\(focus.title)의 변화만 짧게 누적합니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
                    checkpointFields
                    saveButton
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    checkpointFields
                    saveButton
                }
            }

            if let message = viewModel.checkpointStatusMessage {
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Semantic.success)
            }
        }
    }

    private var checkpointFields: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            TextField("BPM", text: $bpm)
                .textFieldStyle(.roundedBorder)
                .frame(width: 76)
                .accessibilityLabel("체크포인트 BPM")
            TextField("관찰 메모", text: $note)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 150)
                .accessibilityLabel("체크포인트 관찰 메모")
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                let didSave = await viewModel.saveProgressCheckpoint(
                    progressItemId: focus.id,
                    observedOn: observedOn,
                    bpmText: bpm,
                    status: focus.status,
                    note: note
                )
                if didSave {
                    bpm = ""
                    note = ""
                }
            }
        } label: {
            Label("추가", systemImage: "plus.circle")
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isSaving || (bpm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
        .help("현재 진도에 체크포인트 추가")
    }
}

struct LessonBriefView: View {
    var brief: LessonBrief

    var body: some View {
        WorkbenchSurface(.inspector, padding: AppTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                SectionHeader(
                    title: "수업 전 확인",
                    subtitle: brief.weakPointBrief
                )

                Text(brief.firstCheck)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let assignment = brief.assignmentCue {
                    Label(assignment, systemImage: "checklist")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let observation = brief.recentObservation {
                    Text(observation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct LessonRunPanelView: View {
    @Bindable var viewModel: StudentDetailViewModel
    @FocusState private var focusedField: Field?

    private let fieldColumns = [
        GridItem(
            .adaptive(minimum: 250),
            spacing: AppTheme.Spacing.md,
            alignment: .top
        )
    ]

    var body: some View {
        WorkbenchSurface(.panel, padding: AppTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                WorkbenchHeader(
                    title: "이번 레슨 기록",
                    subtitle: "수업 중 떠오른 내용을 짧게 남겨두세요"
                ) {
                    StatusBadge(
                        label: "필수 \(filledRequiredCount)/3",
                        systemImage: canPrepareCloseout ? "checkmark.circle.fill" : "circle.dashed",
                        tint: canPrepareCloseout ? AppTheme.Semantic.success : .secondary
                    )
                }

                if let message = viewModel.draftStatusMessage {
                    Label(
                        message,
                        systemImage: viewModel.draftStatusIsError
                            ? "exclamationmark.triangle.fill"
                            : "checkmark.arrow.trianglehead.counterclockwise"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(viewModel.draftStatusIsError ? AppTheme.Semantic.error : .secondary)
                    .accessibilityLabel("레슨 초안 상태")
                    .accessibilityValue(message)
                }

                if let draft = viewModel.recoveredLessonDraft {
                    recoveredDraftBanner(draft)
                }

                LazyVGrid(
                    columns: fieldColumns,
                    alignment: .leading,
                    spacing: AppTheme.Spacing.md
                ) {
                    runField(
                        "진행한 내용",
                        prompt: "무엇을 연습했나요?",
                        text: $viewModel.runCovered,
                        field: .covered,
                        isRequired: true
                    )
                    runField(
                        "학생 반응",
                        prompt: "어떤 반응과 변화가 있었나요?",
                        text: $viewModel.runObservation,
                        field: .observation,
                        isRequired: true
                    )
                    runField(
                        "연습 과제",
                        prompt: "다음 레슨 전 연습할 내용",
                        text: $viewModel.runPractice,
                        field: .practice,
                        isRequired: true
                    )
                    runField(
                        "다음 첫 확인",
                        prompt: "비워두면 현재 첫 확인을 이어갑니다",
                        text: $viewModel.runNextHint,
                        field: .nextHint,
                        isRequired: false
                    )
                }
                .disabled(viewModel.recoveredLessonDraft != nil)

                Divider()

                closeoutArea
                    .disabled(viewModel.recoveredLessonDraft != nil)

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.Semantic.error)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("저장 오류")
                        .accessibilityValue(errorMessage)
                }
            }
        }
        .onChange(of: runNotesSnapshot) { _, _ in
            viewModel.scheduleLessonDraftAutosave()
        }
        .onDisappear {
            Task { await viewModel.flushLessonDraftAutosave() }
        }
    }

    private func recoveredDraftBanner(_ draft: LessonDraft) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Label("작성 중인 초안이 있습니다", systemImage: "doc.badge.clock")
                .font(.headline)
                .foregroundStyle(AppTheme.Accent.teachingForeground)

            Text("이 레슨에서 저장되지 않은 기록을 이어서 작성하거나 삭제하세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: AppTheme.Spacing.sm) {
                Button("초안 삭제", role: .destructive) {
                    Task { await viewModel.deleteRecoveredLessonDraft() }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("이어서 작성") {
                    viewModel.continueRecoveredLessonDraft()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Accent.teaching.opacity(0.10), in: AppTheme.softPanel)
        .overlay(AppTheme.softPanel.stroke(AppTheme.Accent.teaching.opacity(0.24), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityValue("마지막 저장 \(draft.updatedAt)")
    }

    private var closeoutArea: some View {
        Group {
            if let draft = viewModel.closeoutDraft {
                LessonCloseoutReview(viewModel: viewModel, draft: draft)
            } else if let message = viewModel.closeoutStatusMessage {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.Semantic.success)
                    Text("학생 기록에서 방금 저장한 노트를 확인할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack(alignment: .firstTextBaseline) {
                        Label(readinessLabel, systemImage: canPrepareCloseout ? "checkmark.circle" : "pencil.line")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(canPrepareCloseout ? AppTheme.Semantic.success : .primary)
                        Spacer()
                        Text("진행 · 반응 · 과제")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        viewModel.useRunNotesInCloseout()
                    } label: {
                        Label("기록 검토", systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canPrepareCloseout)
                    .keyboardShortcut(.return, modifiers: [.command])
                    .help(canPrepareCloseout ? "저장할 기록을 검토합니다 (⌘↩)" : "필수 기록 3개를 먼저 입력하세요")
                }
            }
        }
    }

    private var filledRequiredCount: Int {
        [viewModel.runCovered, viewModel.runObservation, viewModel.runPractice]
            .filter(hasText)
            .count
    }

    private var runNotesSnapshot: RunNotesSnapshot {
        RunNotesSnapshot(
            coveredMaterial: viewModel.runCovered,
            observations: viewModel.runObservation,
            practiceAssigned: viewModel.runPractice,
            nextStepHint: viewModel.runNextHint
        )
    }

    private var canPrepareCloseout: Bool {
        filledRequiredCount == 3
    }

    private var readinessLabel: String {
        canPrepareCloseout
            ? "기록을 검토할 준비가 됐어요"
            : "필수 기록 \(3 - filledRequiredCount)개 남음"
    }

    private func hasText(_ value: String) -> Bool {
        value.contains { !$0.isWhitespace }
    }

    private func runField(
        _ title: String,
        prompt: String,
        text: Binding<String>,
        field: Field,
        isRequired: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(isRequired ? "필수" : "선택")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            TextField(prompt, text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3, reservesSpace: true)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, 7)
                .frame(minHeight: 64, alignment: .topLeading)
                .background(Color(nsColor: .textBackgroundColor), in: AppTheme.softPanel)
                .overlay(
                    AppTheme.softPanel.stroke(
                        focusedField == field
                            ? AppTheme.Accent.teaching
                            : Color(nsColor: .separatorColor).opacity(0.72),
                        lineWidth: focusedField == field ? 2 : 1
                    )
                )
                .focused($focusedField, equals: field)
                .accessibilityLabel(title)
                .accessibilityHint(isRequired ? "마무리 전에 입력해야 하는 필수 기록입니다." : "비워두면 현재 첫 확인을 사용합니다.")
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private enum Field: Hashable {
        case covered
        case observation
        case practice
        case nextHint
    }

    private struct RunNotesSnapshot: Equatable {
        var coveredMaterial: String
        var observations: String
        var practiceAssigned: String
        var nextStepHint: String
    }
}

private struct LessonCloseoutReview: View {
    @Bindable var viewModel: StudentDetailViewModel
    var draft: LessonCloseoutDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            SectionHeader(
                title: "저장 전 확인",
                subtitle: "이 내용으로 수업 기록과 다음 행동을 함께 갱신합니다"
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                reviewRow("진행", value: draft.coveredMaterial)
                reviewRow("관찰", value: draft.observations)
                reviewRow("과제", value: draft.practiceAssigned)
                reviewRow("다음 확인", value: draft.nextStepHint)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Button("계속 수정") {
                    viewModel.closeoutDraft = nil
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSaving)

                Spacer()

                Button {
                    Task { await viewModel.saveCloseout() }
                } label: {
                    if viewModel.isSaving {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ProgressView()
                                .controlSize(.small)
                            Text("저장 중")
                        }
                    } else {
                        Label("마무리 저장", systemImage: "checkmark.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isSaving)
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
    }

    private func reviewRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
