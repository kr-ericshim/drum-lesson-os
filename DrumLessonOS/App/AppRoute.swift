import Foundation

enum AppRoute: Hashable, CustomStringConvertible {
    case dashboard
    case calendar
    case tuition
    case student(UUID)
    case lesson(CalendarLessonEvent)

    var description: String {
        switch self {
        case .dashboard:
            "dashboard"
        case .calendar:
            "calendar"
        case .tuition:
            "tuition"
        case .student(let id):
            "student:\(id.uuidString)"
        case .lesson(let event):
            "lesson:\(event.studentId.uuidString):\(event.id.uuidString)"
        }
    }
}
