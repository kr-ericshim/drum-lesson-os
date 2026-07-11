import Foundation
import Observation

@MainActor
@Observable
final class StudentDetailViewModel {
    var detail: StudentDetail?
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

    let studentId: EntityID
    let lessonContext: CalendarLessonEvent?
    private let repository: StudentRepository
    private let writes: StudentWriteRepository

    init(studentId: EntityID, lessonContext: CalendarLessonEvent? = nil, repository: StudentRepository, writes: StudentWriteRepository) {
        self.studentId = studentId
        self.lessonContext = lessonContext
        self.repository = repository
        self.writes = writes
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await repository.loadStudentDetail(studentId: studentId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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
        } catch {
            closeoutStatusMessage = nil
            errorMessage = error.localizedDescription
        }
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
