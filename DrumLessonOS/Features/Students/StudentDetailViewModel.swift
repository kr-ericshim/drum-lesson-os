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
        await saveAndReload {
            try StudentEditingValidation.validate(input)
            try await writes.updateStudentProfile(input)
        }
    }

    func saveTrait(traitId: EntityID?, type: StudentTraitType, label: String, detail: String) async {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty, !trimmedDetail.isEmpty else {
            errorMessage = "Trait label and detail are required."
            return
        }
        let input = StudentTraitInput(
            studentId: studentId,
            traitId: traitId,
            type: type,
            label: trimmedLabel,
            detail: trimmedDetail
        )
        await saveAndReload {
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
    ) async {
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
        await saveAndReload {
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
        await saveAndReload {
            try await writes.updateProgressStatus(input)
        }
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
        await saveAndReload {
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
    ) async {
        let input = LessonNoteInput(
            studentId: studentId,
            lessonDate: lessonDate,
            coveredMaterial: coveredMaterial,
            observations: observations,
            practiceAssigned: practiceAssigned,
            nextStepHint: nextStepHint
        )
        await saveAndReload {
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
        await saveAndReload {
            try StudentEditingValidation.validate(input)
            _ = try await writes.upsertNextPlan(input)
        }
    }

    func useRunNotesInCloseout(selectedChecklistLabels: [String] = []) {
        let firstCheck = detail?.lessonBrief.firstCheck ?? ""
        closeoutDraft = LessonCloseoutDraftBuilder.build(
            coveredMaterial: runCovered,
            observations: runObservation,
            practiceAssigned: runPractice,
            selectedChecklistLabels: selectedChecklistLabels,
            nextStepHint: runNextHint,
            fallbackFirstCheck: firstCheck
        )
    }

    func saveCloseout() async {
        guard let detail, let draft = closeoutDraft else { return }
        do {
            try await writes.closeoutLesson(LessonCloseoutInput(
                studentId: detail.id,
                lessonDate: DateOnly.today(in: .current),
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
                progressCurrentFocus: true
            ))
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveAndReload(_ operation: () async throws -> Void) async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await operation()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
