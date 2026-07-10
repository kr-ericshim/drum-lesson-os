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

    var label: String {
        switch self {
        case .notDetermined: "확인 전"
        case .authorized: "허용됨"
        case .denied: "거부됨"
        case .restricted: "제한됨"
        case .writeOnly: "쓰기 전용"
        case .unknown: "알 수 없음"
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
