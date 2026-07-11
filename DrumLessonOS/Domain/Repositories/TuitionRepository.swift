import Foundation

@MainActor
protocol TuitionRepository {
    func loadTuitionRoster() async throws -> [TuitionRosterItem]
    func configureTuitionCycle(
        studentId: EntityID,
        completedLessonCount: Int,
        paymentConfirmedOn: String?
    ) async throws -> EntityID
    func updateTuitionCycleProgress(
        cycleId: EntityID,
        studentId: EntityID,
        completedLessonCount: Int
    ) async throws
    func setTuitionPaymentConfirmation(
        cycleId: EntityID,
        studentId: EntityID,
        confirmedOn: String?
    ) async throws
    func startNextTuitionCycle(
        studentId: EntityID,
        currentCycleId: EntityID,
        paymentConfirmedOn: String?
    ) async throws -> EntityID
}
