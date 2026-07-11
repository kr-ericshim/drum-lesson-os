import Foundation
import Observation

@MainActor
@Observable
final class StudentDetailViewModel {
    var detail: StudentDetail?
    var upcomingLessons: [StudentUpcomingLesson] = []
    var isLoading = false
    var errorMessage: String?
    var runCovered = ""
    var runObservation = ""
    var runPractice = ""
    var runNextHint = ""
    var closeoutDraft: LessonCloseoutDraft?
    var closeoutStatusMessage: String?
    var checkpointStatusMessage: String?
    var isSaving = false
    var recoveredLessonDraft: LessonDraft?
    var draftStatusMessage: String?
    var draftStatusIsError = false

    let studentId: EntityID
    let lessonContext: CalendarLessonEvent?
    private let repository: StudentRepository
    private let writes: StudentWriteRepository
    private let lessonDrafts: LessonDraftRepository
    private let draftAutosaveDelayNanoseconds: UInt64
    @ObservationIgnored private var draftSaveTask: Task<Void, Never>?
    @ObservationIgnored private var hasLoadedLessonDraft = false

    init(
        studentId: EntityID,
        lessonContext: CalendarLessonEvent? = nil,
        repository: StudentRepository,
        writes: StudentWriteRepository,
        lessonDrafts: LessonDraftRepository,
        draftAutosaveDelayNanoseconds: UInt64 = 750_000_000
    ) {
        self.studentId = studentId
        self.lessonContext = lessonContext
        self.repository = repository
        self.writes = writes
        self.lessonDrafts = lessonDrafts
        self.draftAutosaveDelayNanoseconds = draftAutosaveDelayNanoseconds
    }

    func load(now: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await repository.loadStudentDetail(studentId: studentId)
            upcomingLessons = try await repository.loadUpcomingLessons(studentId: studentId, after: now, limit: 2)
            errorMessage = nil
            await loadLessonDraftIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleLessonDraftAutosave() {
        guard lessonContext != nil,
              recoveredLessonDraft == nil,
              closeoutStatusMessage == nil else { return }
        draftSaveTask?.cancel()
        draftStatusMessage = "자동 저장 대기 중…"
        draftStatusIsError = false
        draftSaveTask = Task { [self] in
            do {
                try await Task<Never, Never>.sleep(nanoseconds: draftAutosaveDelayNanoseconds)
            } catch {
                return
            }
            await persistLessonDraft()
        }
    }

    func flushLessonDraftAutosave() async {
        guard lessonContext != nil,
              recoveredLessonDraft == nil,
              closeoutStatusMessage == nil else { return }
        draftSaveTask?.cancel()
        draftSaveTask = nil
        await persistLessonDraft()
    }

    func continueRecoveredLessonDraft() {
        guard let draft = recoveredLessonDraft else { return }
        runCovered = draft.coveredMaterial
        runObservation = draft.observations
        runPractice = draft.practiceAssigned
        runNextHint = draft.nextStepHint
        recoveredLessonDraft = nil
        draftStatusMessage = "\(Self.autosaveTimeLabel(draft.updatedAt)) 자동 저장됨"
        draftStatusIsError = false
    }

    func deleteRecoveredLessonDraft() async {
        guard let occurrenceId = lessonContext?.id else { return }
        draftSaveTask?.cancel()
        do {
            try await lessonDrafts.deleteLessonDraft(occurrenceId: occurrenceId)
            recoveredLessonDraft = nil
            draftStatusMessage = "작성 중인 초안을 삭제했습니다."
            draftStatusIsError = false
        } catch {
            draftStatusMessage = "초안 삭제 실패: \(error.localizedDescription)"
            draftStatusIsError = true
        }
    }

    func persistLessonDraft() async {
        guard let lessonContext else { return }
        draftSaveTask = nil
        let input = LessonDraftInput(
            occurrenceId: lessonContext.id,
            studentId: studentId,
            coveredMaterial: runCovered,
            observations: runObservation,
            practiceAssigned: runPractice,
            nextStepHint: runNextHint
        )
        draftStatusMessage = "자동 저장 중…"
        draftStatusIsError = false
        do {
            if input.isEmpty {
                try await lessonDrafts.deleteLessonDraft(occurrenceId: lessonContext.id)
                draftStatusMessage = nil
            } else {
                let draft = try await lessonDrafts.upsertLessonDraft(input)
                draftStatusMessage = "\(Self.autosaveTimeLabel(draft.updatedAt)) 자동 저장됨"
            }
        } catch {
            draftStatusMessage = "자동 저장 실패: \(error.localizedDescription)"
            draftStatusIsError = true
        }
    }

    func saveProfile(name: String, profileCue: String, primaryWeakPoint: String, active: Bool) async {
        let input = StudentProfileInput(
            studentId: studentId,
            name: name,
            profileCue: profileCue,
            primaryWeakPoint: primaryWeakPoint,
            active: active
        )
        _ = await saveAndReload {
            try StudentEditingValidation.validate(input)
            try await writes.updateStudentProfile(input)
        }
    }

    func deleteStudent() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await writes.deleteStudent(studentId: studentId)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func saveTrait(traitId: EntityID?, type: StudentTraitType, label: String, detail: String) async -> Bool {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty, !trimmedDetail.isEmpty else {
            errorMessage = "특성 라벨과 상세 내용을 입력하세요."
            return false
        }
        let input = StudentTraitInput(
            studentId: studentId,
            traitId: traitId,
            type: type,
            label: trimmedLabel,
            detail: trimmedDetail
        )
        return await saveAndReload {
            _ = try await writes.upsertTrait(input)
        }
    }

    func saveProgressItem(
        progressItemId: EntityID?,
        category: ProgressCategory,
        status: ProgressStatus,
        title: String,
        detail: String,
        tempoNote: String?,
        observedOn: String,
        currentFocus: Bool
    ) async -> Bool {
        let input = ProgressItemInput(
            studentId: studentId,
            progressItemId: progressItemId,
            category: category,
            status: status,
            title: title,
            detail: detail,
            tempoNote: tempoNote,
            observedOn: observedOn,
            currentFocus: currentFocus
        )
        return await saveAndReload {
            try StudentEditingValidation.validate(input)
            _ = try await writes.upsertProgressItem(input)
        }
    }

    func saveProgressStatus(progressItemId: EntityID, nextStatus: ProgressStatus) async {
        let input = ProgressStatusTransitionInput(
            studentId: studentId,
            progressItemId: progressItemId,
            nextStatus: nextStatus
        )
        _ = await saveAndReload {
            try await writes.updateProgressStatus(input)
        }
    }

    @discardableResult
    func saveProgressCheckpoint(
        progressItemId: EntityID,
        observedOn: String,
        bpmText: String,
        status: ProgressStatus,
        note: String
    ) async -> Bool {
        let trimmedBPM = bpmText.trimmingCharacters(in: .whitespacesAndNewlines)
        let bpm: Int?
        if trimmedBPM.isEmpty {
            bpm = nil
        } else if let value = Int(trimmedBPM) {
            bpm = value
        } else {
            checkpointStatusMessage = nil
            errorMessage = "BPM은 숫자로 입력하세요."
            return false
        }
        let input = ProgressCheckpointInput(
            studentId: studentId,
            progressItemId: progressItemId,
            observedOn: observedOn,
            bpm: bpm,
            status: status,
            note: note
        )
        checkpointStatusMessage = nil
        let didSave = await saveAndReload {
            try StudentEditingValidation.validate(input)
            _ = try await writes.createProgressCheckpoint(input)
        }
        if didSave {
            checkpointStatusMessage = "진도 체크포인트를 저장했습니다."
        }
        return didSave
    }

    func saveAssignment(assignmentId: EntityID?, title: String, status: AssignmentStatus, dueDate: String?, detail: String) async {
        let input = AssignmentInput(
            studentId: studentId,
            assignmentId: assignmentId,
            title: title,
            status: status,
            dueDate: dueDate,
            detail: detail
        )
        _ = await saveAndReload {
            try StudentEditingValidation.validate(input)
            _ = try await writes.upsertAssignment(input)
        }
    }

    func saveLessonNote(
        lessonDate: String,
        coveredMaterial: String,
        observations: String,
        practiceAssigned: String,
        nextStepHint: String
    ) async -> Bool {
        let input = LessonNoteInput(
            studentId: studentId,
            lessonDate: lessonDate,
            coveredMaterial: coveredMaterial,
            observations: observations,
            practiceAssigned: practiceAssigned,
            nextStepHint: nextStepHint
        )
        return await saveAndReload {
            try StudentEditingValidation.validate(input)
            _ = try await writes.createLessonNote(input)
        }
    }

    func saveNextPlan(planId: EntityID?, plannedFor: String?, priority: NextLessonPriority, nextAction: String, detail: String) async {
        let input = NextPlanInput(
            studentId: studentId,
            planId: planId,
            plannedFor: plannedFor,
            priority: priority,
            nextAction: nextAction,
            detail: detail
        )
        _ = await saveAndReload {
            try StudentEditingValidation.validate(input)
            _ = try await writes.upsertNextPlan(input)
        }
    }

    func useRunNotesInCloseout(selectedChecklistLabels: [String] = []) {
        let firstCheck = detail?.lessonBrief.firstCheck ?? ""
        closeoutStatusMessage = nil
        closeoutDraft = LessonCloseoutDraftBuilder.build(
            coveredMaterial: runCovered,
            observations: runObservation,
            practiceAssigned: runPractice,
            selectedChecklistLabels: selectedChecklistLabels,
            nextStepHint: runNextHint,
            fallbackFirstCheck: firstCheck
        )
    }

    func saveCloseout(now: Date = Date()) async {
        guard !isSaving else { return }
        guard let lessonContext else {
            closeoutStatusMessage = nil
            errorMessage = "예약된 레슨에서만 마무리 기록을 저장할 수 있습니다."
            return
        }
        guard LessonEventActionContext(event: lessonContext, now: now) != .prepare else {
            closeoutStatusMessage = nil
            errorMessage = "미래 레슨은 당일이 된 뒤 마무리할 수 있습니다."
            return
        }
        guard let detail, let draft = closeoutDraft else { return }
        draftSaveTask?.cancel()
        draftSaveTask = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await writes.closeoutLesson(LessonCloseoutInput(
                studentId: detail.id,
                lessonDate: lessonContext.dateKey,
                coveredMaterial: draft.coveredMaterial,
                observations: draft.observations,
                practiceAssigned: draft.practiceAssigned,
                nextStepHint: draft.nextStepHint,
                nextPlanId: detail.nextPlan?.id,
                nextAction: draft.nextAction,
                nextPlanDetail: detail.nextPlan?.detail,
                plannedFor: detail.nextPlan?.plannedFor,
                priority: detail.nextPlan?.priority ?? .normal,
                assignmentId: detail.assignment?.id,
                assignmentTitle: detail.assignment?.title,
                assignmentStatus: detail.assignment?.status,
                assignmentDueDate: detail.assignment?.dueDate,
                assignmentDetail: detail.assignment?.detail,
                progressItemId: detail.currentFocus?.id,
                progressStatus: detail.currentFocus?.status,
                progressCurrentFocus: detail.currentFocus != nil,
                occurrenceId: lessonContext.id
            ))
            await load()
            runCovered = ""
            runObservation = ""
            runPractice = ""
            runNextHint = ""
            closeoutDraft = nil
            closeoutStatusMessage = "마무리 기록을 저장했습니다."
            recoveredLessonDraft = nil
            draftStatusMessage = nil
            draftStatusIsError = false
        } catch {
            closeoutStatusMessage = nil
            errorMessage = error.localizedDescription
            scheduleLessonDraftAutosave()
        }
    }

    private func loadLessonDraftIfNeeded() async {
        guard !hasLoadedLessonDraft, let lessonContext else { return }
        hasLoadedLessonDraft = true
        do {
            guard let draft = try await lessonDrafts.loadLessonDraft(occurrenceId: lessonContext.id) else { return }
            recoveredLessonDraft = draft
            draftStatusMessage = "\(Self.autosaveTimeLabel(draft.updatedAt)) 저장된 초안"
            draftStatusIsError = false
        } catch {
            draftStatusMessage = "초안 불러오기 실패: \(error.localizedDescription)"
            draftStatusIsError = true
        }
    }

    private static func autosaveTimeLabel(_ timestamp: String) -> String {
        guard let date = ISO8601DateFormatter.withFractions.date(from: timestamp)
            ?? ISO8601DateFormatter.plain.date(from: timestamp) else {
            return "방금"
        }
        return date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened)
                .locale(Locale(identifier: "ko_KR"))
        )
    }

    @discardableResult
    private func saveAndReload(_ operation: () async throws -> Void) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await operation()
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
