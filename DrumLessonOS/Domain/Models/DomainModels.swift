import Foundation

typealias EntityID = UUID

enum ProgressCategory: String, Codable, CaseIterable, Identifiable {
    case book
    case song
    case rudiment
    case genre
    case technique
    case session
    case assignment

    var id: String { rawValue }
}

enum ProgressStatus: String, Codable, CaseIterable, Identifiable {
    case new
    case inProgress = "in_progress"
    case needsReview = "needs_review"
    case steady
    case complete

    var id: String { rawValue }

    var label: String {
        switch self {
        case .new: "새 항목"
        case .inProgress: "진행 중"
        case .needsReview: "확인 필요"
        case .steady: "안정화"
        case .complete: "완료"
        }
    }
}

enum StudentTraitType: String, Codable, CaseIterable, Identifiable {
    case strength
    case weakPoint = "weak_point"
    case practiceHabit = "practice_habit"
    case learningStyle = "learning_style"
    case musicalPreference = "musical_preference"
    case caution

    var id: String { rawValue }

    var label: String {
        switch self {
        case .strength: "강점"
        case .weakPoint: "약점"
        case .practiceHabit: "연습 습관"
        case .learningStyle: "학습 스타일"
        case .musicalPreference: "음악 취향"
        case .caution: "주의점"
        }
    }
}

enum AssignmentStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case needsReview = "needs_review"
    case complete
    case paused

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notStarted: "시작 전"
        case .inProgress: "진행 중"
        case .needsReview: "확인 필요"
        case .complete: "완료"
        case .paused: "보류"
        }
    }
}

enum NextLessonPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: "낮음"
        case .normal: "보통"
        case .high: "높음"
        }
    }
}

enum LessonOccurrenceStatus: String, Codable, CaseIterable, Identifiable {
    case scheduled
    case completed
    case canceled

    var id: String { rawValue }
}

enum NativeCalendarSyncStatus: String, Codable, CaseIterable, Identifiable {
    case notConnected = "not_connected"
    case pending
    case synced
    case failed
    case disabled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notConnected: "캘린더 미연결"
        case .pending: "캘린더 대기 중"
        case .synced: "캘린더 동기화됨"
        case .failed: "캘린더 실패"
        case .disabled: "캘린더 꺼짐"
        }
    }
}

extension ProgressCategory {
    var label: String {
        switch self {
        case .book: "교재"
        case .song: "곡"
        case .rudiment: "루디먼트"
        case .genre: "장르"
        case .technique: "테크닉"
        case .session: "레슨"
        case .assignment: "과제"
        }
    }
}

struct Instructor: Codable, Identifiable, Hashable {
    var id: EntityID
    var displayName: String
    var studioName: String?
    var authUserId: EntityID?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case studioName = "studio_name"
        case authUserId = "auth_user_id"
    }
}

struct Student: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var name: String
    var profileCue: String
    var primaryWeakPoint: String
    var active: Bool
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case name
        case profileCue = "profile_cue"
        case primaryWeakPoint = "primary_weak_point"
        case active
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProgressItem: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var category: ProgressCategory
    var status: ProgressStatus
    var title: String
    var currentFocus: Bool
    var observedOn: String
    var detail: String
    var tempoNote: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case category
        case status
        case title
        case currentFocus = "current_focus"
        case observedOn = "observed_on"
        case detail
        case tempoNote = "tempo_note"
        case updatedAt = "updated_at"
    }
}

struct StudentTrait: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var type: StudentTraitType
    var label: String
    var detail: String

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case type = "trait_type"
        case label
        case detail
    }
}

struct LessonNote: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var lessonDate: String
    var coveredMaterial: String
    var observations: String
    var practiceAssigned: String
    var nextStepHint: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case lessonDate = "lesson_date"
        case coveredMaterial = "covered_material"
        case observations
        case practiceAssigned = "practice_assigned"
        case nextStepHint = "next_step_hint"
        case createdAt = "created_at"
    }
}

struct Assignment: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var title: String
    var status: AssignmentStatus
    var dueDate: String?
    var detail: String
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case title
        case status
        case dueDate = "due_date"
        case detail
        case updatedAt = "updated_at"
    }
}

struct NextLessonPlan: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var plannedFor: String?
    var priority: NextLessonPriority
    var nextAction: String
    var detail: String
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case plannedFor = "planned_for"
        case priority
        case nextAction = "next_action"
        case detail
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LessonScheduleTemplate: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var title: String
    var defaultDurationMinutes: Int
    var timezone: String
    var recurrenceKind: String
    var recurrenceInterval: Int
    var recurrenceWeekday: Int
    var startsOn: String
    var endsOn: String?
    var startTime: String
    var active: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case title
        case defaultDurationMinutes = "default_duration_minutes"
        case timezone
        case recurrenceKind = "recurrence_kind"
        case recurrenceInterval = "recurrence_interval"
        case recurrenceWeekday = "recurrence_weekday"
        case startsOn = "starts_on"
        case endsOn = "ends_on"
        case startTime = "start_time"
        case active
    }
}

struct LessonOccurrence: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var scheduleTemplateId: EntityID?
    var recurrenceSlotDate: String?
    var startsAt: String
    var endsAt: String
    var timezone: String
    var status: LessonOccurrenceStatus
    var title: String
    var nativeCalendarEventIdentifier: String?
    var nativeCalendarIdentifier: String?
    var nativeCalendarExternalIdentifier: String?
    var nativeCalendarSyncStatus: NativeCalendarSyncStatus
    var nativeCalendarSyncError: String?
    var nativeCalendarSyncedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case scheduleTemplateId = "schedule_template_id"
        case recurrenceSlotDate = "recurrence_slot_date"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case timezone
        case status
        case title
        case nativeCalendarEventIdentifier = "native_calendar_event_identifier"
        case nativeCalendarIdentifier = "native_calendar_identifier"
        case nativeCalendarExternalIdentifier = "native_calendar_external_identifier"
        case nativeCalendarSyncStatus = "native_calendar_sync_status"
        case nativeCalendarSyncError = "native_calendar_sync_error"
        case nativeCalendarSyncedAt = "native_calendar_synced_at"
        case legacyAppleSyncStatus = "apple_sync_status"
        case legacyAppleSyncError = "apple_sync_error"
        case legacyAppleSyncedAt = "apple_synced_at"
    }

    init(
        id: EntityID,
        instructorId: EntityID,
        studentId: EntityID,
        scheduleTemplateId: EntityID?,
        startsAt: String,
        endsAt: String,
        timezone: String,
        status: LessonOccurrenceStatus,
        title: String,
        nativeCalendarEventIdentifier: String?,
        nativeCalendarIdentifier: String?,
        nativeCalendarExternalIdentifier: String?,
        nativeCalendarSyncStatus: NativeCalendarSyncStatus,
        nativeCalendarSyncError: String?,
        nativeCalendarSyncedAt: String?,
        recurrenceSlotDate: String? = nil
    ) {
        self.id = id
        self.instructorId = instructorId
        self.studentId = studentId
        self.scheduleTemplateId = scheduleTemplateId
        self.recurrenceSlotDate = recurrenceSlotDate
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.timezone = timezone
        self.status = status
        self.title = title
        self.nativeCalendarEventIdentifier = nativeCalendarEventIdentifier
        self.nativeCalendarIdentifier = nativeCalendarIdentifier
        self.nativeCalendarExternalIdentifier = nativeCalendarExternalIdentifier
        self.nativeCalendarSyncStatus = nativeCalendarSyncStatus
        self.nativeCalendarSyncError = nativeCalendarSyncError
        self.nativeCalendarSyncedAt = nativeCalendarSyncedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(EntityID.self, forKey: .id)
        instructorId = try container.decode(EntityID.self, forKey: .instructorId)
        studentId = try container.decode(EntityID.self, forKey: .studentId)
        scheduleTemplateId = try container.decodeIfPresent(EntityID.self, forKey: .scheduleTemplateId)
        recurrenceSlotDate = try container.decodeIfPresent(String.self, forKey: .recurrenceSlotDate)
        startsAt = try container.decode(String.self, forKey: .startsAt)
        endsAt = try container.decode(String.self, forKey: .endsAt)
        timezone = try container.decode(String.self, forKey: .timezone)
        status = try container.decode(LessonOccurrenceStatus.self, forKey: .status)
        title = try container.decode(String.self, forKey: .title)
        nativeCalendarEventIdentifier = try container.decodeIfPresent(String.self, forKey: .nativeCalendarEventIdentifier)
        nativeCalendarIdentifier = try container.decodeIfPresent(String.self, forKey: .nativeCalendarIdentifier)
        nativeCalendarExternalIdentifier = try container.decodeIfPresent(String.self, forKey: .nativeCalendarExternalIdentifier)
        nativeCalendarSyncStatus = try container.decodeIfPresent(NativeCalendarSyncStatus.self, forKey: .nativeCalendarSyncStatus)
            ?? container.decodeIfPresent(NativeCalendarSyncStatus.self, forKey: .legacyAppleSyncStatus)
            ?? .notConnected
        nativeCalendarSyncError = try container.decodeIfPresent(String.self, forKey: .nativeCalendarSyncError)
            ?? container.decodeIfPresent(String.self, forKey: .legacyAppleSyncError)
        nativeCalendarSyncedAt = try container.decodeIfPresent(String.self, forKey: .nativeCalendarSyncedAt)
            ?? container.decodeIfPresent(String.self, forKey: .legacyAppleSyncedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(instructorId, forKey: .instructorId)
        try container.encode(studentId, forKey: .studentId)
        try container.encodeIfPresent(scheduleTemplateId, forKey: .scheduleTemplateId)
        try container.encodeIfPresent(recurrenceSlotDate, forKey: .recurrenceSlotDate)
        try container.encode(startsAt, forKey: .startsAt)
        try container.encode(endsAt, forKey: .endsAt)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(status, forKey: .status)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(nativeCalendarEventIdentifier, forKey: .nativeCalendarEventIdentifier)
        try container.encodeIfPresent(nativeCalendarIdentifier, forKey: .nativeCalendarIdentifier)
        try container.encodeIfPresent(nativeCalendarExternalIdentifier, forKey: .nativeCalendarExternalIdentifier)
        try container.encode(nativeCalendarSyncStatus, forKey: .nativeCalendarSyncStatus)
        try container.encodeIfPresent(nativeCalendarSyncError, forKey: .nativeCalendarSyncError)
        try container.encodeIfPresent(nativeCalendarSyncedAt, forKey: .nativeCalendarSyncedAt)
    }
}
