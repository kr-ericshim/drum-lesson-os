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

    #expect(EventKitLessonEventBuilder.title(for: draft) == "Drum lesson - 김민지")
    #expect(notes.contains("Drum Lesson OS occurrence: 11111111-1111-1111-1111-111111111111"))
    #expect(notes.contains("Student id: \(PreviewData.minjiId.uuidString)"))
}
