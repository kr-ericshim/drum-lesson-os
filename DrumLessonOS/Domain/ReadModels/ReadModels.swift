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
}

struct StudentAssignment: Identifiable, Hashable {
    var id: EntityID
    var title: String
    var status: AssignmentStatus
    var dueDate: String?
    var detail: String
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

struct LessonCloseoutDraft: Equatable {
    var coveredMaterial: String
    var observations: String
    var practiceAssigned: String
    var nextStepHint: String
    var nextAction: String
}
