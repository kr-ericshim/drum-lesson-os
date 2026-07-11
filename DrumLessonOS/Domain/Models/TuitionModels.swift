import Foundation

struct TuitionCycle: Codable, Identifiable, Hashable {
    var id: EntityID
    var instructorId: EntityID
    var studentId: EntityID
    var sequence: Int
    var targetLessonCount: Int
    var completedLessonCount: Int
    var paymentConfirmedOn: String?
    var createdAt: String?
    var updatedAt: String?

    var isPaymentConfirmed: Bool {
        paymentConfirmedOn != nil
    }

    var isComplete: Bool {
        completedLessonCount >= targetLessonCount
    }

    var nextLessonNumber: Int? {
        isComplete ? nil : completedLessonCount + 1
    }

    enum CodingKeys: String, CodingKey {
        case id
        case instructorId = "instructor_id"
        case studentId = "student_id"
        case sequence
        case targetLessonCount = "target_lesson_count"
        case completedLessonCount = "completed_lesson_count"
        case paymentConfirmedOn = "payment_confirmed_on"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TuitionRosterItem: Identifiable, Hashable {
    var id: EntityID { studentId }

    var studentId: EntityID
    var studentName: String
    var cycles: [TuitionCycle]

    init(studentId: EntityID, studentName: String, cycles: [TuitionCycle]) {
        self.studentId = studentId
        self.studentName = studentName
        self.cycles = cycles.sorted { $0.sequence < $1.sequence }
    }

    var currentCycle: TuitionCycle? {
        cycles.last
    }

    var outstandingCycles: [TuitionCycle] {
        cycles.filter { !$0.isPaymentConfirmed }
    }

    var oldestOutstandingCycle: TuitionCycle? {
        outstandingCycles.first
    }
}
