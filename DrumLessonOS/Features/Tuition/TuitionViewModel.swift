import Foundation
import Observation

@Observable
@MainActor
final class TuitionViewModel {
    private(set) var roster: [TuitionRosterItem] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var actionStudentId: EntityID?
    var errorMessage: String?
    var successMessage: String?

    private let repository: TuitionRepository

    init(repository: TuitionRepository) {
        self.repository = repository
    }

    var isPerformingAction: Bool {
        actionStudentId != nil
    }

    var setupNeededCount: Int {
        roster.lazy.filter { $0.currentCycle == nil }.count
    }

    var outstandingStudentCount: Int {
        roster.lazy.filter { $0.oldestOutstandingCycle != nil }.count
    }

    var readyForNextCycleCount: Int {
        roster.lazy.filter { $0.currentCycle?.isComplete == true }.count
    }

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            roster = try await repository.loadTuitionRoster()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func configureCycle(
        studentId: EntityID,
        completedLessonCount: Int,
        paymentConfirmedOn: String?
    ) async -> Bool {
        await performAction(
            studentId: studentId,
            successMessage: "\(studentName(for: studentId)) 학생의 현재 수강 회차를 설정했습니다."
        ) {
            _ = try await repository.configureTuitionCycle(
                studentId: studentId,
                completedLessonCount: completedLessonCount,
                paymentConfirmedOn: paymentConfirmedOn
            )
        }
    }

    @discardableResult
    func correctProgress(
        cycleId: EntityID,
        studentId: EntityID,
        completedLessonCount: Int
    ) async -> Bool {
        await performAction(
            studentId: studentId,
            successMessage: "\(studentName(for: studentId)) 학생의 완료 회차를 수정했습니다."
        ) {
            try await repository.updateTuitionCycleProgress(
                cycleId: cycleId,
                studentId: studentId,
                completedLessonCount: completedLessonCount
            )
        }
    }

    @discardableResult
    func setPaymentConfirmation(
        cycleId: EntityID,
        studentId: EntityID,
        confirmedOn: String?
    ) async -> Bool {
        let message = confirmedOn == nil
            ? "\(studentName(for: studentId)) 학생의 입금 확인을 취소했습니다."
            : "\(studentName(for: studentId)) 학생의 입금 확인을 저장했습니다."

        return await performAction(studentId: studentId, successMessage: message) {
            try await repository.setTuitionPaymentConfirmation(
                cycleId: cycleId,
                studentId: studentId,
                confirmedOn: confirmedOn
            )
        }
    }

    @discardableResult
    func startNextCycle(
        studentId: EntityID,
        currentCycleId: EntityID,
        paymentConfirmedOn: String?
    ) async -> Bool {
        await performAction(
            studentId: studentId,
            successMessage: "\(studentName(for: studentId)) 학생의 다음 4회를 시작했습니다."
        ) {
            _ = try await repository.startNextTuitionCycle(
                studentId: studentId,
                currentCycleId: currentCycleId,
                paymentConfirmedOn: paymentConfirmedOn
            )
        }
    }

    private func performAction(
        studentId: EntityID,
        successMessage: String,
        operation: @MainActor () async throws -> Void
    ) async -> Bool {
        guard actionStudentId == nil else { return false }

        actionStudentId = studentId
        errorMessage = nil
        self.successMessage = nil
        defer { actionStudentId = nil }

        do {
            try await operation()
            roster = try await repository.loadTuitionRoster()
            self.successMessage = successMessage
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func studentName(for studentId: EntityID) -> String {
        roster.first { $0.studentId == studentId }?.studentName ?? "학생"
    }
}
