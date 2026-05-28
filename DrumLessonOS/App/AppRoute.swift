import Foundation

enum AppRoute: Hashable, CustomStringConvertible {
    case dashboard
    case student(UUID)
    case lesson(CalendarLessonEvent)
    case settings

    var description: String {
        switch self {
        case .dashboard:
            "dashboard"
        case .student(let id):
            "student:\(id.uuidString)"
        case .lesson(let event):
            "lesson:\(event.studentId.uuidString):\(event.id.uuidString)"
        case .settings:
            "settings"
        }
    }
}
