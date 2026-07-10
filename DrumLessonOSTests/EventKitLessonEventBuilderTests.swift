import Foundation
import Testing
@testable import DrumLessonOS

@Test func eventNotesIncludeStableOccurrenceMarker() {
    let draft = LessonCalendarEventDraft(
        occurrenceId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        studentId: PreviewData.minjiId,
        studentName: "김민지",
        startsAt: Date(timeIntervalSince1970: 0),
        endsAt: Date(timeIntervalSince1970: 3_000),
        timezone: "Asia/Seoul",
        currentFocus: "필인 뒤 1박",
        firstCheck: "착지 확인"
    )

    let notes = EventKitLessonEventBuilder.notes(for: draft)

    #expect(EventKitLessonEventBuilder.title(for: draft) == "드럼 레슨 - 김민지")
    #expect(notes.contains("드럼 레슨 OS 일정 ID: 11111111-1111-1111-1111-111111111111"))
    #expect(notes.contains("학생 ID: \(PreviewData.minjiId.uuidString)"))
}

@Test func eventReminderConvertsMinutesToNegativeAlarmOffset() {
    #expect(EventKitLessonEventBuilder.alarmOffset(reminderMinutes: nil) == nil)
    #expect(EventKitLessonEventBuilder.alarmOffset(reminderMinutes: 15) == -900)
}

@Test func eventKitExternalIdentifierRecoveryPrefersOriginalCalendar() throws {
    let candidates = [
        EventKitEventCandidate(eventIdentifier: "moved-copy", calendarIdentifier: "calendar-2"),
        EventKitEventCandidate(eventIdentifier: "recovered", calendarIdentifier: "calendar-1")
    ]

    let index = try EventKitEventLocator.uniqueCandidateIndex(
        in: candidates,
        preferredCalendarIdentifier: "calendar-1"
    )

    #expect(index == 1)
    #expect(candidates[index!].eventIdentifier == "recovered")
}

@Test func eventKitRecoveryRejectsAmbiguousExternalMatches() {
    let candidates = [
        EventKitEventCandidate(eventIdentifier: "copy-1", calendarIdentifier: "calendar-1"),
        EventKitEventCandidate(eventIdentifier: "copy-2", calendarIdentifier: "calendar-1")
    ]

    #expect(throws: RepositoryError.self) {
        try EventKitEventLocator.uniqueCandidateIndex(
            in: candidates,
            preferredCalendarIdentifier: "calendar-1"
        )
    }
}

@Test func eventKitRecoveryWindowsCoverRangeWithoutExceedingFourYears() throws {
    let start = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-28T10:00:00Z"))
    let end = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-28T11:00:00Z"))
    let windows = EventKitRecoveryWindowPlanner.windows(from: start, through: end)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    let expectedStart = try #require(calendar.date(byAdding: .year, value: -10, to: start))
    let expectedEnd = try #require(calendar.date(byAdding: .year, value: 10, to: end))

    #expect(windows.first?.start == expectedStart)
    #expect(windows.last?.end == expectedEnd)
    #expect(zip(windows, windows.dropFirst()).allSatisfy { pair in
        pair.0.end == pair.1.start
    })
    #expect(windows.allSatisfy { window in
        guard let fourYearLimit = calendar.date(byAdding: .year, value: 4, to: window.start) else {
            return false
        }
        return window.end <= fourYearLimit
    })
}
