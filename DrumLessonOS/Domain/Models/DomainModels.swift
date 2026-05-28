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
        case .new: "New"
        case .inProgress: "In progress"
        case .needsReview: "Needs review"
        case .steady: "Steady"
        case .complete: "Complete"
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
}

enum AssignmentStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case needsReview = "needs_review"
    case complete
    case paused

    var id: String { rawValue }
}

enum NextLessonPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }
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
        case .notConnected: "Calendar not connected"
        case .pending: "Calendar pending"
        case .synced: "Calendar synced"
        case .failed: "Calendar failed"
        case .disabled: "Calendar disabled"
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
    }
}
