import EventKit
import Foundation

enum EventKitPermissionState: String, Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case writeOnly
    case unknown

    init(status: EKAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized, .fullAccess:
            self = .authorized
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        case .writeOnly:
            self = .writeOnly
        @unknown default:
            self = .unknown
        }
    }
}

struct WritableCalendar: Identifiable, Hashable {
    var id: String
    var title: String
    var sourceTitle: String
}

struct CalendarWriteResult: Equatable {
    var eventIdentifier: String
    var calendarIdentifier: String
    var externalIdentifier: String?
    var syncedAt: Date
}

struct LessonCalendarEventDraft: Equatable {
    var occurrenceId: EntityID
    var studentId: EntityID
    var title: String? = nil
    var studentName: String
    var startsAt: Date
    var endsAt: Date
    var timezone: String
    var currentFocus: String?
    var firstCheck: String
}
