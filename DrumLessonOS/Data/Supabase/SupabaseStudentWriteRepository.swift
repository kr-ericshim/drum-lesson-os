import Foundation

@MainActor
final class SupabaseStudentWriteRepository: StudentWriteRepository {
    private let rpc: SupabaseRPCClient

    init(rpc: SupabaseRPCClient) {
        self.rpc = rpc
    }

    func createStudent(_ input: StudentProfileInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let result = try await rpc.executeMutation(
            name: "native_create_student",
            payload: [
                "p_name": .string(input.name),
                "p_profile_cue": .string(input.profileCue),
                "p_primary_weak_point": .string(input.primaryWeakPoint),
                "p_active": .bool(input.active)
            ]
        )
        return result.id
    }

    func updateStudentProfile(_ input: StudentProfileInput) async throws {
        try StudentEditingValidation.validate(input)
        guard let studentId = input.studentId else {
            throw RepositoryError.notFound
        }
        _ = try await rpc.executeMutation(
            name: "native_update_student_profile",
            payload: [
                "p_student_id": .uuid(studentId),
                "p_name": .string(input.name),
                "p_profile_cue": .string(input.profileCue),
                "p_primary_weak_point": .string(input.primaryWeakPoint),
                "p_active": .bool(input.active)
            ]
        )
    }

    func upsertTrait(_ input: StudentTraitInput) async throws -> EntityID {
        let result = try await rpc.executeMutation(
            name: "native_upsert_student_trait",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_trait_type": .string(input.type.rawValue),
                "p_label": .string(input.label),
                "p_detail": .string(input.detail),
                "p_trait_id": .optionalUUID(input.traitId)
            ]
        )
        return result.id
    }

    func upsertProgressItem(_ input: ProgressItemInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let result = try await rpc.executeMutation(
            name: "native_upsert_progress_item",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_category": .string(input.category.rawValue),
                "p_status": .string(input.status.rawValue),
                "p_title": .string(input.title),
                "p_detail": .string(input.detail),
                "p_observed_on": .string(input.observedOn),
                "p_current_focus": .bool(input.currentFocus),
                "p_tempo_note": .optionalString(input.tempoNote),
                "p_progress_item_id": .optionalUUID(input.progressItemId)
            ]
        )
        return result.id
    }

    func updateProgressStatus(_ input: ProgressStatusTransitionInput) async throws {
        _ = try await rpc.executeMutation(
            name: "native_update_progress_status",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_progress_item_id": .uuid(input.progressItemId),
                "p_status": .string(input.nextStatus.rawValue)
            ]
        )
    }

    func upsertAssignment(_ input: AssignmentInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let result = try await rpc.executeMutation(
            name: "native_upsert_assignment",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_title": .string(input.title),
                "p_status": .string(input.status.rawValue),
                "p_due_date": .optionalString(input.dueDate),
                "p_detail": .string(input.detail),
                "p_assignment_id": .optionalUUID(input.assignmentId)
            ]
        )
        return result.id
    }

    func createLessonNote(_ input: LessonNoteInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let result = try await rpc.executeMutation(
            name: "native_create_lesson_note",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_lesson_date": .string(input.lessonDate),
                "p_covered_material": .string(input.coveredMaterial),
                "p_observations": .string(input.observations),
                "p_practice_assigned": .string(input.practiceAssigned),
                "p_next_step_hint": .string(input.nextStepHint)
            ]
        )
        return result.id
    }

    func upsertNextPlan(_ input: NextPlanInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let result = try await rpc.executeMutation(
            name: "native_upsert_next_lesson_plan",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_planned_for": .optionalString(input.plannedFor),
                "p_priority": .string(input.priority.rawValue),
                "p_next_action": .string(input.nextAction),
                "p_detail": .string(input.detail),
                "p_next_lesson_plan_id": .optionalUUID(input.planId)
            ]
        )
        return result.id
    }

    func closeoutLesson(_ input: LessonCloseoutInput) async throws {
        try StudentEditingValidation.validate(input)
        try await rpc.executeVoid(
            name: "closeout_lesson",
            payload: [
                "target_student_id": .uuid(input.studentId),
                "closeout_lesson_date": .string(input.lessonDate),
                "closeout_covered_material": .string(input.coveredMaterial),
                "closeout_observations": .string(input.observations),
                "closeout_practice_assigned": .string(input.practiceAssigned),
                "closeout_next_step_hint": .string(input.nextStepHint),
                "target_next_plan_id": .optionalUUID(input.nextPlanId),
                "closeout_next_action": .string(input.nextAction),
                "closeout_next_plan_detail": .optionalString(input.nextPlanDetail),
                "closeout_planned_for": .optionalString(input.plannedFor),
                "closeout_priority": .string(input.priority.rawValue),
                "target_assignment_id": .optionalUUID(input.assignmentId),
                "closeout_assignment_title": .optionalString(input.assignmentTitle),
                "closeout_assignment_status": .optionalString(input.assignmentStatus?.rawValue),
                "closeout_assignment_due_date": .optionalString(input.assignmentDueDate),
                "closeout_assignment_detail": .optionalString(input.assignmentDetail),
                "target_progress_item_id": .optionalUUID(input.progressItemId),
                "closeout_progress_status": .optionalString(input.progressStatus?.rawValue),
                "closeout_progress_current_focus": .bool(input.progressCurrentFocus)
            ]
        )
    }
}
