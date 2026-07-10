import Testing
@testable import DrumLessonOS

@Test func lessonDisplayDateUsesCompactKoreanFormat() {
    #expect(LessonDateFormatters.displayDate("2026-07-10") == "7월 10일 금")
}

@Test func lessonDisplayDatePreservesAnInvalidValue() {
    #expect(LessonDateFormatters.displayDate("not-a-date") == "not-a-date")
}
