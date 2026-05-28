import Foundation

struct ValidationError: LocalizedError, Equatable {
    var field: String
    var message: String

    var errorDescription: String? { message }
}

enum StudentEditingValidation {
    static func validate(_ input: StudentProfileInput) throws {
        try require(input.name, field: "name", max: 120)
        try require(input.profileCue, field: "profileCue", max: 240)
        try require(input.primaryWeakPoint, field: "primaryWeakPoint", max: 240)
    }

    static func validate(_ input: ProgressItemInput) throws {
        try require(input.title, field: "title", max: 240)
        try require(input.detail, field: "detail", max: 2_000)
        try requireDate(input.observedOn, field: "observedOn")
        try optional(input.tempoNote, field: "tempoNote", max: 240)
    }

    static func validate(_ input: AssignmentInput) throws {
        try require(input.title, field: "title", max: 160)
        try require(input.detail, field: "detail", max: 1_000)
        try optionalDate(input.dueDate, field: "dueDate")
    }

    static func validate(_ input: LessonNoteInput) throws {
        try requireDate(input.lessonDate, field: "lessonDate")
        try require(input.coveredMaterial, field: "coveredMaterial", max: 2_000)
        try require(input.observations, field: "observations", max: 2_000)
        try require(input.practiceAssigned, field: "practiceAssigned", max: 2_000)
        try require(input.nextStepHint, field: "nextStepHint", max: 1_000)
    }

    static func validate(_ input: NextPlanInput) throws {
        try optionalDate(input.plannedFor, field: "plannedFor")
        try require(input.nextAction, field: "nextAction", max: 240)
        try require(input.detail, field: "detail", max: 2_000)
    }

    static func validate(_ input: LessonCloseoutInput) throws {
        try validate(LessonNoteInput(
            studentId: input.studentId,
            lessonDate: input.lessonDate,
            coveredMaterial: input.coveredMaterial,
            observations: input.observations,
            practiceAssigned: input.practiceAssigned,
            nextStepHint: input.nextStepHint
        ))
        try require(input.nextAction, field: "nextAction", max: 240)
        try optional(input.nextPlanDetail, field: "nextPlanDetail", max: 2_000)
        try optionalDate(input.plannedFor, field: "plannedFor")

        let hasAssignment = !(input.assignmentTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            input.assignmentStatus != nil ||
            !(input.assignmentDetail ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            input.assignmentDueDate != nil

        if hasAssignment {
            try require(input.assignmentTitle ?? "", field: "assignmentTitle", max: 160)
            guard input.assignmentStatus != nil else {
                throw ValidationError(field: "assignmentStatus", message: "Assignment status is required when saving assignment review.")
            }
            try require(input.assignmentDetail ?? "", field: "assignmentDetail", max: 1_000)
        }
    }

    static func isProgressStatusTransitionAllowed(currentStatus: ProgressStatus, nextStatus: ProgressStatus) -> Bool {
        allowedTransitions[currentStatus, default: []].contains(nextStatus)
    }

    private static let allowedTransitions: [ProgressStatus: Set<ProgressStatus>] = [
        .complete: [.needsReview],
        .inProgress: [.needsReview, .steady],
        .needsReview: [.inProgress, .steady],
        .new: [.inProgress],
        .steady: [.complete]
    ]

    private static func require(_ value: String, field: String, max: Int) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw ValidationError(field: field, message: "\(field) is required.")
        }
        if trimmed.count > max {
            throw ValidationError(field: field, message: "\(field) must be \(max) characters or less.")
        }
    }

    private static func optional(_ value: String?, field: String, max: Int) throws {
        guard let value else { return }
        if value.trimmingCharacters(in: .whitespacesAndNewlines).count > max {
            throw ValidationError(field: field, message: "\(field) must be \(max) characters or less.")
        }
    }

    private static func optionalDate(_ value: String?, field: String) throws {
        guard let value, !value.isEmpty else { return }
        try requireDate(value, field: field)
    }

    private static func requireDate(_ value: String, field: String) throws {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false

        guard value.count == 10, formatter.date(from: value) != nil else {
            throw ValidationError(field: field, message: "Use a valid YYYY-MM-DD date.")
        }
    }
}

struct StudentProfileInput: Equatable {
    var studentId: EntityID?
    var name: String
    var profileCue: String
    var primaryWeakPoint: String
    var active: Bool
}

struct StudentTraitInput: Equatable {
    var studentId: EntityID
    var traitId: EntityID?
    var type: StudentTraitType
    var label: String
    var detail: String
}

struct ProgressItemInput: Equatable {
    var studentId: EntityID
    var progressItemId: EntityID?
    var category: ProgressCategory
    var status: ProgressStatus
    var title: String
    var detail: String
    var tempoNote: String?
    var observedOn: String
    var currentFocus: Bool
}

struct ProgressStatusTransitionInput: Equatable {
    var studentId: EntityID
    var progressItemId: EntityID
    var nextStatus: ProgressStatus
}

struct AssignmentInput: Equatable {
    var studentId: EntityID
    var assignmentId: EntityID?
    var title: String
    var status: AssignmentStatus
    var dueDate: String?
    var detail: String
}

struct LessonNoteInput: Equatable {
    var studentId: EntityID
    var lessonDate: String
    var coveredMaterial: String
    var observations: String
    var practiceAssigned: String
    var nextStepHint: String
}

struct NextPlanInput: Equatable {
    var studentId: EntityID
    var planId: EntityID?
    var plannedFor: String?
    var priority: NextLessonPriority
    var nextAction: String
    var detail: String
}

struct LessonCloseoutInput: Equatable {
    var studentId: EntityID
    var lessonDate: String
    var coveredMaterial: String
    var observations: String
    var practiceAssigned: String
    var nextStepHint: String
    var nextPlanId: EntityID?
    var nextAction: String
    var nextPlanDetail: String?
    var plannedFor: String?
    var priority: NextLessonPriority
    var assignmentId: EntityID?
    var assignmentTitle: String?
    var assignmentStatus: AssignmentStatus?
    var assignmentDueDate: String?
    var assignmentDetail: String?
    var progressItemId: EntityID?
    var progressStatus: ProgressStatus?
    var progressCurrentFocus: Bool
}
