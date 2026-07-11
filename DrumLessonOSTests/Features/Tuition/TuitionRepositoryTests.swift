import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func legacySeededStudentsRequireTuitionSetup() async throws {
    let database = try TuitionTestDatabase()
    defer { database.remove() }
    let repository = try LocalSQLiteRepository(databaseURL: database.url)

    let roster = try await repository.loadTuitionRoster()
    let minji = try #require(roster.first { $0.studentId == PreviewData.minjiId })
    let joon = try #require(roster.first { $0.studentId == PreviewData.joonId })

    #expect(minji.currentCycle == nil)
    #expect(joon.currentCycle == nil)
    #expect(minji.cycles.isEmpty)
    #expect(joon.cycles.isEmpty)
}

@MainActor
@Test func configuredTuitionCycleAndPaymentPersistAcrossRepositoryInstances() async throws {
    let database = try TuitionTestDatabase()
    defer { database.remove() }
    let firstRepository = try LocalSQLiteRepository(databaseURL: database.url)

    let cycleId = try await firstRepository.configureTuitionCycle(
        studentId: PreviewData.minjiId,
        completedLessonCount: 2,
        paymentConfirmedOn: "2026-07-11"
    )

    let reopenedRepository = try LocalSQLiteRepository(databaseURL: database.url)
    let item = try await tuitionRosterItem(
        studentId: PreviewData.minjiId,
        repository: reopenedRepository
    )
    let cycle = try #require(item.currentCycle)

    #expect(cycle.id == cycleId)
    #expect(cycle.sequence == 1)
    #expect(cycle.targetLessonCount == 4)
    #expect(cycle.completedLessonCount == 2)
    #expect(cycle.nextLessonNumber == 3)
    #expect(cycle.paymentConfirmedOn == "2026-07-11")
    #expect(cycle.isPaymentConfirmed)
    #expect(item.outstandingCycles.isEmpty)
}

@MainActor
@Test func newStudentStartsWithUnconfirmedZeroOfFourCycle() async throws {
    let database = try TuitionTestDatabase()
    defer { database.remove() }
    let repository = try LocalSQLiteRepository(databaseURL: database.url)
    let studentId = try await repository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "신규 학생",
        profileCue: "첫 레슨 전",
        primaryWeakPoint: "아직 확인 전",
        active: true
    ))

    let item = try await tuitionRosterItem(studentId: studentId, repository: repository)
    let cycle = try #require(item.currentCycle)

    #expect(cycle.sequence == 1)
    #expect(cycle.completedLessonCount == 0)
    #expect(cycle.nextLessonNumber == 1)
    #expect(cycle.paymentConfirmedOn == nil)
}

@MainActor
@Test func successfulCloseoutAdvancesTuitionOnceAndDuplicateDoesNotAdvanceAgain() async throws {
    let database = try TuitionTestDatabase()
    defer { database.remove() }
    let now = try #require(ISO8601DateFormatter.plain.date(from: "2026-08-06T12:00:00Z"))
    let repository = try LocalSQLiteRepository(databaseURL: database.url, currentDate: { now })
    let cycleId = try await repository.configureTuitionCycle(
        studentId: PreviewData.minjiId,
        completedLessonCount: 0,
        paymentConfirmedOn: nil
    )
    let occurrence = try await makeTuitionOccurrence(
        repository: repository,
        studentId: PreviewData.minjiId,
        dateKey: "2026-08-06"
    )
    let closeout = makeTuitionCloseoutInput(
        studentId: PreviewData.minjiId,
        occurrenceId: occurrence.id,
        lessonDate: "2026-08-06"
    )

    try await repository.closeoutLesson(closeout)
    let itemAfterCloseout = try await tuitionRosterItem(
        studentId: PreviewData.minjiId,
        repository: repository
    )
    var cycle = try #require(itemAfterCloseout.currentCycle)
    #expect(cycle.id == cycleId)
    #expect(cycle.completedLessonCount == 1)
    #expect(cycle.nextLessonNumber == 2)

    await #expect(throws: ValidationError.self) {
        try await repository.closeoutLesson(closeout)
    }

    let itemAfterDuplicate = try await tuitionRosterItem(
        studentId: PreviewData.minjiId,
        repository: repository
    )
    cycle = try #require(itemAfterDuplicate.currentCycle)
    #expect(cycle.id == cycleId)
    #expect(cycle.completedLessonCount == 1)
    #expect(cycle.nextLessonNumber == 2)
}

@MainActor
@Test func nextTuitionCycleStartsOnlyAfterFourLessonsAndPreservesPriorCycle() async throws {
    let database = try TuitionTestDatabase()
    defer { database.remove() }
    let repository = try LocalSQLiteRepository(databaseURL: database.url)
    let firstCycleId = try await repository.configureTuitionCycle(
        studentId: PreviewData.minjiId,
        completedLessonCount: 3,
        paymentConfirmedOn: "2026-07-01"
    )

    await #expect(throws: ValidationError.self) {
        _ = try await repository.startNextTuitionCycle(
            studentId: PreviewData.minjiId,
            currentCycleId: firstCycleId,
            paymentConfirmedOn: nil
        )
    }

    try await repository.updateTuitionCycleProgress(
        cycleId: firstCycleId,
        studentId: PreviewData.minjiId,
        completedLessonCount: 4
    )
    let secondCycleId = try await repository.startNextTuitionCycle(
        studentId: PreviewData.minjiId,
        currentCycleId: firstCycleId,
        paymentConfirmedOn: nil
    )

    let item = try await tuitionRosterItem(studentId: PreviewData.minjiId, repository: repository)
    #expect(item.cycles.map(\.sequence) == [1, 2])
    let firstCycle = try #require(item.cycles.first { $0.id == firstCycleId })
    let secondCycle = try #require(item.cycles.first { $0.id == secondCycleId })

    #expect(firstCycle.completedLessonCount == 4)
    #expect(firstCycle.paymentConfirmedOn == "2026-07-01")
    #expect(firstCycle.isComplete)
    #expect(firstCycle.nextLessonNumber == nil)
    #expect(secondCycle.completedLessonCount == 0)
    #expect(secondCycle.paymentConfirmedOn == nil)
    #expect(secondCycle.nextLessonNumber == 1)
    #expect(item.currentCycle?.id == secondCycleId)
}

@MainActor
@Test func closeoutAfterFullCycleCreatesNewUnpaidCycleAtOneOfFour() async throws {
    let database = try TuitionTestDatabase()
    defer { database.remove() }
    let now = try #require(ISO8601DateFormatter.plain.date(from: "2026-08-13T12:00:00Z"))
    let repository = try LocalSQLiteRepository(databaseURL: database.url, currentDate: { now })
    let firstCycleId = try await repository.configureTuitionCycle(
        studentId: PreviewData.minjiId,
        completedLessonCount: 4,
        paymentConfirmedOn: nil
    )
    let occurrence = try await makeTuitionOccurrence(
        repository: repository,
        studentId: PreviewData.minjiId,
        dateKey: "2026-08-13"
    )

    try await repository.closeoutLesson(makeTuitionCloseoutInput(
        studentId: PreviewData.minjiId,
        occurrenceId: occurrence.id,
        lessonDate: "2026-08-13"
    ))

    let item = try await tuitionRosterItem(studentId: PreviewData.minjiId, repository: repository)
    #expect(item.cycles.map(\.sequence) == [1, 2])
    let priorCycle = try #require(item.cycles.first { $0.id == firstCycleId })
    let currentCycle = try #require(item.currentCycle)

    #expect(priorCycle.completedLessonCount == 4)
    #expect(priorCycle.paymentConfirmedOn == nil)
    #expect(currentCycle.id != firstCycleId)
    #expect(currentCycle.sequence == 2)
    #expect(currentCycle.completedLessonCount == 1)
    #expect(currentCycle.nextLessonNumber == 2)
    #expect(currentCycle.paymentConfirmedOn == nil)
    #expect(!currentCycle.isPaymentConfirmed)
    #expect(item.oldestOutstandingCycle?.id == firstCycleId)
}

@MainActor
@Test func paymentWriteFromStaleRepositoryPreservesConcurrentCloseoutProgress() async throws {
    let database = try TuitionTestDatabase()
    defer { database.remove() }
    let now = try #require(ISO8601DateFormatter.plain.date(from: "2026-08-20T12:00:00Z"))
    let lessonRepository = try LocalSQLiteRepository(databaseURL: database.url, currentDate: { now })
    let paymentRepository = try LocalSQLiteRepository(databaseURL: database.url, currentDate: { now })
    let cycleId = try await lessonRepository.configureTuitionCycle(
        studentId: PreviewData.minjiId,
        completedLessonCount: 0,
        paymentConfirmedOn: nil
    )
    let occurrence = try await makeTuitionOccurrence(
        repository: lessonRepository,
        studentId: PreviewData.minjiId,
        dateKey: "2026-08-20"
    )

    try await lessonRepository.closeoutLesson(makeTuitionCloseoutInput(
        studentId: PreviewData.minjiId,
        occurrenceId: occurrence.id,
        lessonDate: "2026-08-20"
    ))
    try await paymentRepository.setTuitionPaymentConfirmation(
        cycleId: cycleId,
        studentId: PreviewData.minjiId,
        confirmedOn: "2026-08-20"
    )

    let reopenedRepository = try LocalSQLiteRepository(databaseURL: database.url)
    let item = try await tuitionRosterItem(
        studentId: PreviewData.minjiId,
        repository: reopenedRepository
    )
    let cycle = try #require(item.currentCycle)

    #expect(cycle.id == cycleId)
    #expect(cycle.completedLessonCount == 1)
    #expect(cycle.nextLessonNumber == 2)
    #expect(cycle.paymentConfirmedOn == "2026-08-20")
}

@MainActor
private func tuitionRosterItem(
    studentId: EntityID,
    repository: LocalSQLiteRepository
) async throws -> TuitionRosterItem {
    let roster = try await repository.loadTuitionRoster()
    return try #require(roster.first { $0.studentId == studentId })
}

@MainActor
private func makeTuitionOccurrence(
    repository: LocalSQLiteRepository,
    studentId: EntityID,
    dateKey: String
) async throws -> LessonOccurrence {
    try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: studentId,
        title: "수강비 회차 테스트 레슨",
        startsAt: "\(dateKey)T10:00:00Z",
        endsAt: "\(dateKey)T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))
}

private func makeTuitionCloseoutInput(
    studentId: EntityID,
    occurrenceId: EntityID,
    lessonDate: String
) -> LessonCloseoutInput {
    LessonCloseoutInput(
        studentId: studentId,
        lessonDate: lessonDate,
        coveredMaterial: "4회 수강 주기 테스트",
        observations: "회차 증가 확인",
        practiceAssigned: "기본 루틴 반복",
        nextStepHint: "다음 회차 확인",
        nextPlanId: nil,
        nextAction: "다음 회차 확인",
        nextPlanDetail: "다음 레슨에서 이어서 확인",
        plannedFor: nil,
        priority: .normal,
        assignmentId: nil,
        assignmentTitle: nil,
        assignmentStatus: nil,
        assignmentDueDate: nil,
        assignmentDetail: nil,
        progressItemId: nil,
        progressStatus: nil,
        progressCurrentFocus: false,
        occurrenceId: occurrenceId
    )
}

private struct TuitionTestDatabase {
    let directoryURL: URL
    let url: URL

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DrumLessonOS-Tuition-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        url = directoryURL.appendingPathComponent("TuitionTests.sqlite")
    }

    func remove() {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}
