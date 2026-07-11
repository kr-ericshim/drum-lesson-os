import Foundation
import Testing
@testable import DrumLessonOS

@Test func decodesStudentDetailRowsFromSnakeCase() throws {
    let json = """
    {
      "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "instructor_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "student_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "category": "song",
      "status": "in_progress",
      "title": "좋은 밤 좋은 꿈 8비트",
      "current_focus": true,
      "observed_on": "2026-05-28",
      "detail": "필인 뒤 1박 착지",
      "tempo_note": "82 BPM",
      "updated_at": "2026-05-28T08:00:00Z"
    }
    """.data(using: .utf8)!

    let item = try JSONDecoder().decode(ProgressItem.self, from: json)

    #expect(item.category == .song)
    #expect(item.status == .inProgress)
    #expect(item.currentFocus)
    #expect(item.tempoNote == "82 BPM")
}

@Test func invalidEnumFailsDecoding() throws {
    let json = """
    {
      "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "instructor_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "student_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "category": "unknown",
      "status": "in_progress",
      "title": "Bad",
      "current_focus": true,
      "observed_on": "2026-05-28",
      "detail": "Bad"
    }
    """.data(using: .utf8)!

    #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(ProgressItem.self, from: json)
    }
}

@Test func decodesLessonOccurrenceWhenNativeCalendarColumnsAreMissing() throws {
    let json = """
    {
      "id": "99999999-9999-9999-9999-999999999999",
      "instructor_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "student_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "schedule_template_id": null,
      "starts_at": "2026-05-28T10:00:00Z",
      "ends_at": "2026-05-28T10:50:00Z",
      "timezone": "Asia/Seoul",
      "status": "scheduled",
      "title": "김민지 드럼 레슨",
      "apple_sync_status": "failed",
      "apple_sync_error": "legacy failure",
      "apple_synced_at": "2026-05-28T10:01:00Z"
    }
    """.data(using: .utf8)!

    let occurrence = try JSONDecoder().decode(LessonOccurrence.self, from: json)

    #expect(occurrence.nativeCalendarSyncStatus == .failed)
    #expect(occurrence.nativeCalendarSyncError == "legacy failure")
    #expect(occurrence.nativeCalendarSyncedAt == "2026-05-28T10:01:00Z")
}
