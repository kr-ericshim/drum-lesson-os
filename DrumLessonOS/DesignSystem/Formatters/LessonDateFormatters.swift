import Foundation

enum LessonDateFormatters {
    static func displayDate(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .iso8601SeoulCompatible
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "M월 d일 EEE"
        let parser = DateFormatter()
        parser.calendar = .iso8601SeoulCompatible
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        parser.isLenient = false
        guard let date = parser.date(from: dateKey) else { return dateKey }
        return formatter.string(from: date)
    }
}
