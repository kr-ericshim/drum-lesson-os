import Foundation

enum TuitionValidation {
    static let targetLessonCount = 4

    static func validate(completedLessonCount: Int, paymentConfirmedOn: String?) throws {
        try validateCompletedLessonCount(completedLessonCount)
        try validatePaymentConfirmedOn(paymentConfirmedOn)
    }

    static func validate(_ cycle: TuitionCycle) throws {
        guard cycle.targetLessonCount == targetLessonCount else {
            throw ValidationError(field: "targetLessonCount", message: "수강 주기는 4회로 설정해야 합니다.")
        }
        try validate(
            completedLessonCount: cycle.completedLessonCount,
            paymentConfirmedOn: cycle.paymentConfirmedOn
        )
    }

    static func validateCompletedLessonCount(_ completedLessonCount: Int) throws {
        guard (0...targetLessonCount).contains(completedLessonCount) else {
            throw ValidationError(field: "completedLessonCount", message: "완료 회차는 0회에서 4회 사이로 입력하세요.")
        }
    }

    static func validatePaymentConfirmedOn(_ paymentConfirmedOn: String?) throws {
        guard let paymentConfirmedOn else { return }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false

        guard paymentConfirmedOn.count == 10,
              formatter.date(from: paymentConfirmedOn) != nil else {
            throw ValidationError(field: "paymentConfirmedOn", message: "입금 확인일은 YYYY-MM-DD 형식으로 입력하세요.")
        }
    }
}
