import Foundation
import Testing
@testable import DrumLessonOS

@Test func scheduleConflictDetectorFindsOverlapsButAllowsTouchingBoundaries() throws {
    let occurrence = PreviewData.occurrences[0]
    let overlap = ScheduleConflictQuery(
        slots: [ProposedLessonSlot(
            startsAt: "2026-05-28T10:30:00Z",
            endsAt: "2026-05-28T11:20:00Z"
        )],
        excludingOccurrenceId: nil
    )
    let touching = ScheduleConflictQuery(
        slots: [ProposedLessonSlot(
            startsAt: occurrence.endsAt,
            endsAt: "2026-05-28T11:40:00Z"
        )],
        excludingOccurrenceId: nil
    )

    let overlaps = ScheduleConflictDetector.detect(
        query: overlap,
        occurrences: [occurrence],
        students: PreviewData.students
    )
    let boundary = ScheduleConflictDetector.detect(
        query: touching,
        occurrences: [occurrence],
        students: PreviewData.students
    )

    #expect(overlaps.map(\.occurrenceId) == [occurrence.id])
    #expect(overlaps.first?.studentName == "김민지")
    #expect(boundary.isEmpty)
}

@Test func scheduleConflictDetectorExcludesEditedAndCanceledOccurrences() {
    let scheduled = PreviewData.occurrences[0]
    var canceled = PreviewData.occurrences[1]
    canceled.status = .canceled
    let query = ScheduleConflictQuery(
        slots: [ProposedLessonSlot(
            startsAt: "2026-05-28T09:00:00Z",
            endsAt: "2026-05-28T14:00:00Z"
        )],
        excludingOccurrenceId: scheduled.id
    )

    let conflicts = ScheduleConflictDetector.detect(
        query: query,
        occurrences: [scheduled, canceled],
        students: PreviewData.students
    )

    #expect(conflicts.isEmpty)
}
