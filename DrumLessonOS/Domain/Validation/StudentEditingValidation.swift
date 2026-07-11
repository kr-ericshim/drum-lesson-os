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

    static func validate(_ input: ProgressCheckpointInput) throws {
        try requireDate(input.observedOn, field: "observedOn")
        try optional(input.note, field: "checkpointNote", max: 500)
        if let bpm = input.bpm, !(20...400).contains(bpm) {
            throw ValidationError(field: "bpm", message: "BPM은 20에서 400 사이로 입력하세요.")
        }
        if input.bpm == nil, input.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError(field: "checkpoint", message: "BPM이나 관찰 메모를 입력하세요.")
        }
    }

    static func validate(_ input: StudentTraitInput) throws {
        try require(input.label, field: "traitLabel", max: 160)
        try require(input.detail, field: "traitDetail", max: 1_000)
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
        guard input.occurrenceId != nil else {
            throw ValidationError(field: "occurrenceId", message: "예약된 레슨에서만 마무리 기록을 저장할 수 있습니다.")
        }
        try validate(LessonNoteInput(
            studentId: input.studentId,
            lessonDate: input.lessonDate,
            coveredMaterial: input.coveredMaterial,
            observations: input.observations,
            practiceAssigned: input.practiceAssigned,
            nextStepHint: input.nextStepHint
        ))
        try validate(NextPlanInput(
            studentId: input.studentId,
            planId: input.nextPlanId,
            plannedFor: input.plannedFor,
            priority: input.priority,
            nextAction: input.nextAction,
            detail: input.nextPlanDetail ?? input.nextStepHint
        ))

        let hasAssignment = input.assignmentId != nil ||
            !(input.assignmentTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            input.assignmentStatus != nil ||
            !(input.assignmentDetail ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            input.assignmentDueDate != nil

        if hasAssignment {
            guard let status = input.assignmentStatus else {
                throw ValidationError(field: "assignmentStatus", message: "과제 확인을 저장하려면 과제 상태를 선택하세요.")
            }
            try validate(AssignmentInput(
                studentId: input.studentId,
                assignmentId: input.assignmentId,
                title: input.assignmentTitle ?? "",
                status: status,
                dueDate: input.assignmentDueDate,
                detail: input.assignmentDetail ?? ""
            ))
        }

        if (input.progressItemId == nil) != (input.progressStatus == nil) {
            throw ValidationError(field: "progressItemId", message: "진도 항목과 상태를 함께 선택하세요.")
        }
        if input.progressCurrentFocus, input.progressItemId == nil {
            throw ValidationError(field: "progressCurrentFocus", message: "현재 초점으로 지정할 진도 항목을 선택하세요.")
        }
    }

    static func isProgressStatusTransitionAllowed(currentStatus: ProgressStatus, nextStatus: ProgressStatus) -> Bool {
        currentStatus == nextStatus || allowedTransitions[currentStatus, default: []].contains(nextStatus)
    }

    static func validateProgressStatusTransition(currentStatus: ProgressStatus, nextStatus: ProgressStatus) throws {
        guard isProgressStatusTransitionAllowed(currentStatus: currentStatus, nextStatus: nextStatus) else {
            throw ValidationError(field: "status", message: "현재 진도 상태에서 선택한 상태로 바로 변경할 수 없습니다.")
        }
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
            throw ValidationError(field: field, message: "\(fieldLabel(field))을(를) 입력하세요.")
        }
        if trimmed.count > max {
            throw ValidationError(field: field, message: "\(fieldLabel(field))은(는) \(max)자 이내로 입력하세요.")
        }
    }

    private static func optional(_ value: String?, field: String, max: Int) throws {
        guard let value else { return }
        if value.trimmingCharacters(in: .whitespacesAndNewlines).count > max {
            throw ValidationError(field: field, message: "\(fieldLabel(field))은(는) \(max)자 이내로 입력하세요.")
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
            throw ValidationError(field: field, message: "날짜는 YYYY-MM-DD 형식으로 입력하세요.")
        }
    }

    private static func fieldLabel(_ field: String) -> String {
        switch field {
        case "name": "이름"
        case "profileCue": "프로필 단서"
        case "primaryWeakPoint": "주요 약점"
        case "title": "제목"
        case "detail": "상세"
        case "observedOn": "확인 날짜"
        case "tempoNote": "템포 메모"
        case "checkpointNote": "체크포인트 메모"
        case "traitLabel": "특성 라벨"
        case "traitDetail": "특성 상세"
        case "dueDate": "마감일"
        case "lessonDate": "레슨 날짜"
        case "coveredMaterial": "진행한 내용"
        case "observations": "관찰"
        case "practiceAssigned": "연습 과제"
        case "nextStepHint": "다음 힌트"
        case "plannedFor": "예정일"
        case "nextAction": "다음 행동"
        case "nextPlanDetail": "다음 계획 상세"
        case "assignmentTitle": "과제 제목"
        case "assignmentDetail": "과제 상세"
        default: field
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

struct ProgressCheckpointInput: Equatable {
    var studentId: EntityID
    var progressItemId: EntityID
    var observedOn: String
    var bpm: Int?
    var status: ProgressStatus
    var note: String
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
    var occurrenceId: EntityID? = nil
}
