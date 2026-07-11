import Foundation

struct ProgressFocusSummary: Identifiable, Hashable {
    var id: EntityID
    var title: String
    var category: ProgressCategory
    var status: ProgressStatus
    var observedOn: String
    var detail: String
    var tempoNote: String?
}

struct StudentNextPlan: Identifiable, Hashable {
    var id: EntityID
    var plannedFor: String?
    var priority: NextLessonPriority
    var nextAction: String
    var detail: String
}

struct StudentRosterItem: Identifiable, Hashable {
    var id: EntityID
    var name: String
    var profileCue: String
    var primaryWeakPoint: String
    var active: Bool
    var currentFocus: ProgressFocusSummary?
    var assignmentStatus: AssignmentStatus?
    var nextPlan: StudentNextPlan?
    var lastLessonDate: String?
    var attentionFlags: [LessonAttentionFlag]
}

struct StudentProgressItem: Identifiable, Hashable {
    var id: EntityID
    var category: ProgressCategory
    var status: ProgressStatus
    var title: String
    var currentFocus: Bool
    var observedOn: String
    var detail: String
    var tempoNote: String?
    var checkpoints: [ProgressCheckpointSummary]
}

struct ProgressCheckpointSummary: Identifiable, Hashable {
    var id: EntityID
    var observedOn: String
    var bpm: Int?
    var status: ProgressStatus
    var note: String
}

struct StudentAssignment: Identifiable, Hashable {
    var id: EntityID
    var title: String
    var status: AssignmentStatus
    var dueDate: String?
    var detail: String
}

struct StudentUpcomingLesson: Identifiable, Hashable {
    var id: EntityID
    var dateKey: String
    var timeLabel: String
}

struct StudentLessonNote: Identifiable, Hashable {
    var id: EntityID
    var lessonDate: String
    var coveredMaterial: String
    var observations: String
    var practiceAssigned: String
    var nextStepHint: String
}

struct LessonBrief: Hashable {
    var firstCheck: String
    var weakPointBrief: String
    var assignmentCue: String?
    var recentObservation: String?
}

struct StudentDetail: Identifiable, Hashable {
    var id: EntityID
    var name: String
    var profileCue: String
    var primaryWeakPoint: String
    var active: Bool
    var currentFocus: ProgressFocusSummary?
    var progressItems: [StudentProgressItem]
    var traits: [StudentTrait]
    var assignment: StudentAssignment?
    var recentNotes: [StudentLessonNote]
    var nextPlan: StudentNextPlan?
    var lessonBrief: LessonBrief
}

struct LessonAttentionFlag: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case needsAssignmentReview
        case noCurrentFocus
        case staleLesson
        case upcomingPlan
    }

    var id: Kind { kind }
    var kind: Kind
    var label: String
}

struct LessonQueueItem: Identifiable, Hashable {
    enum DateState: String {
        case overdue
        case today
        case upcoming
    }

    var id: EntityID
    var studentId: EntityID
    var studentName: String
    var plannedFor: String?
    var firstCheck: String
    var dateState: DateState
    var flags: [LessonAttentionFlag]
}

struct CalendarLessonEvent: Identifiable, Hashable {
    var id: EntityID
    var studentId: EntityID
    var studentName: String
    var title: String
    var dateKey: String
    var timeLabel: String
    var durationMinutes: Int
    var startsAt: String
    var endsAt: String
    var timezone: String
    var status: LessonOccurrenceStatus
    var syncStatus: NativeCalendarSyncStatus
    var syncError: String?
    var firstCheck: String
    var watchFlags: [LessonAttentionFlag]
}

struct CalendarDay: Identifiable, Hashable {
    var id: String { dateKey }
    var dateKey: String
    var label: String
    var isToday: Bool
    var events: [CalendarLessonEvent]
}

struct CalendarWorkbench: Hashable {
    var weekTitle: String
    var todayDateKey: String
    var days: [CalendarDay]
    var todayEvents: [CalendarLessonEvent]
    var roster: [StudentRosterItem]
    var selectedEvent: CalendarLessonEvent?
}

struct ProposedLessonSlot: Equatable {
    var startsAt: String
    var endsAt: String
}

struct ScheduleConflictQuery: Equatable {
    var slots: [ProposedLessonSlot]
    var excludingOccurrenceId: EntityID?
}

struct ScheduleConflict: Identifiable, Equatable {
    var occurrenceId: EntityID
    var studentName: String
    var startsAt: String
    var endsAt: String
    var timezone: String

    var id: EntityID { occurrenceId }

    var displayLabel: String {
        guard let start = ISO8601DateFormatter.withFractions.date(from: startsAt)
            ?? ISO8601DateFormatter.plain.date(from: startsAt),
              let end = ISO8601DateFormatter.withFractions.date(from: endsAt)
            ?? ISO8601DateFormatter.plain.date(from: endsAt) else {
            return studentName
        }
        let timeZone = TimeZone(identifier: timezone) ?? .current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "M월 d일"
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ko_KR")
        timeFormatter.timeZone = timeZone
        timeFormatter.dateFormat = "HH:mm"
        let date = dateFormatter.string(from: start)
        let startTime = timeFormatter.string(from: start)
        let endTime = timeFormatter.string(from: end)
        return "\(date) \(startTime)~\(endTime) · \(studentName)"
    }
}

struct LessonCloseoutDraft: Equatable {
    var coveredMaterial: String
    var observations: String
    var practiceAssigned: String
    var nextStepHint: String
    var nextAction: String
}
