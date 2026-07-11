import Foundation

enum LessonSummaryFormatter {
    static func make(
        studentName: String,
        lessonDate: String,
        draft: LessonCloseoutDraft
    ) -> String {
        let sections = [
            ("진행", draft.coveredMaterial),
            ("관찰", draft.observations),
            ("연습 과제", draft.practiceAssigned),
            ("다음 확인", draft.nextStepHint)
        ]
        .map { title, value in
            let bullets = value
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { "- \($0)" }
                .joined(separator: "\n")
            return "\(title)\n\(bullets)"
        }
        .joined(separator: "\n\n")

        return "[\(studentName) \(displayDate(lessonDate)) 레슨]\n\n\(sections)"
    }

    private static func displayDate(_ dateKey: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.timeZone = TimeZone(secondsFromGMT: 0)
        input.dateFormat = "yyyy-MM-dd"
        input.isLenient = false
        guard let date = input.date(from: dateKey) else { return dateKey }

        let output = DateFormatter()
        output.locale = Locale(identifier: "ko_KR")
        output.timeZone = TimeZone(secondsFromGMT: 0)
        output.dateFormat = "M월 d일"
        return output.string(from: date)
    }
}
