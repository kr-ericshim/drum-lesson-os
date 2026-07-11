import Foundation
import Testing
@testable import DrumLessonOS

@Test func nativeSmokeTest() {
    #expect(AppRoute.dashboard.description == "dashboard")
    #expect(AppRoute.calendar.description == "calendar")
    #expect(AppRoute.tuition.description == "tuition")
}

@Test func associatedRoutesKeepDashboardSelectedInSidebar() {
    let studentID = UUID()
    let event = CalendarLessonEvent(
        id: UUID(),
        studentId: studentID,
        studentName: "김민지",
        title: "김민지 드럼 레슨",
        dateKey: "2026-07-10",
        timeLabel: "19:00",
        durationMinutes: 50,
        startsAt: "2026-07-10T10:00:00Z",
        endsAt: "2026-07-10T10:50:00Z",
        timezone: "Asia/Seoul",
        status: .scheduled,
        syncStatus: .synced,
        syncError: nil,
        firstCheck: "1박 착지",
        watchFlags: []
    )

    #expect(AppRoute.dashboard.sidebarDestination == .dashboard)
    #expect(AppRoute.calendar.sidebarDestination == .calendar)
    #expect(AppRoute.tuition.sidebarDestination == .tuition)
    #expect(AppRoute.student(studentID).sidebarDestination == .dashboard)
    #expect(AppRoute.lesson(event).sidebarDestination == .dashboard)
}
