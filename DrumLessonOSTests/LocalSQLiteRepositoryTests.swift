import Foundation
import SQLite3
import Testing
@testable import DrumLessonOS

@MainActor
@Test func localSQLiteRepositoryPersistsStudentProfileAcrossInstances() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { try? FileManager.default.removeItem(at: databaseURL) }

    let firstRepository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let studentId = try await firstRepository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "최하늘",
        profileCue: "말보다 손으로 먼저 확인하면 편해진다.",
        primaryWeakPoint: "하이햇 오픈 타이밍",
        active: true
    ))

    let reopenedRepository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let detail = try await reopenedRepository.loadStudentDetail(studentId: studentId)

    #expect(detail.name == "최하늘")
    #expect(detail.profileCue == "말보다 손으로 먼저 확인하면 편해진다.")
    #expect(detail.primaryWeakPoint == "하이햇 오픈 타이밍")
}

@MainActor
@Test func localSQLiteRepositoryPersistsCalendarSyncStateForRetryAfterRelaunch() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { try? FileManager.default.removeItem(at: databaseURL) }

    let firstRepository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let occurrence = try await firstRepository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "김민지 드럼 레슨",
        startsAt: "2026-05-29T10:00:00Z",
        endsAt: "2026-05-29T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))
    try await firstRepository.updateNativeCalendarSync(NativeCalendarSyncUpdateInput(
        occurrenceId: occurrence.id,
        status: .failed,
        eventIdentifier: "event-\(occurrence.id)",
        calendarIdentifier: "calendar-1",
        externalIdentifier: nil,
        error: "Temporary database failure",
        syncedAt: nil
    ))

    let reopenedRepository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let reloaded = try await reopenedRepository.loadOccurrence(id: occurrence.id)

    #expect(reloaded.nativeCalendarSyncStatus == .failed)
    #expect(reloaded.nativeCalendarEventIdentifier == "event-\(occurrence.id)")
    #expect(reloaded.nativeCalendarIdentifier == "calendar-1")
    #expect(reloaded.nativeCalendarSyncError == "Temporary database failure")
}

@MainActor
@Test func localSQLiteRepositoryLoadsInactiveStudentDetailWithoutCrashing() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)

    let studentId = try await repository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "비활성 학생",
        profileCue: "보관된 프로필",
        primaryWeakPoint: "없음",
        active: false
    ))
    let detail = try await repository.loadStudentDetail(studentId: studentId)

    #expect(detail.id == studentId)
    #expect(detail.active == false)
}

@MainActor
@Test func closeoutValidationFailureDoesNotCreatePartialLessonNote() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let occurrence = try await makeScheduledOccurrence(repository: repository, dateKey: "2026-07-10")
    let before = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)
    var input = makeCloseoutInput(studentId: PreviewData.minjiId, occurrenceId: occurrence.id)
    input.nextPlanDetail = "   "

    await #expect(throws: ValidationError.self) {
        try await repository.closeoutLesson(input)
    }
    let after = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)

    #expect(after.recentNotes.count == before.recentNotes.count)
}

@MainActor
@Test func closeoutPersistenceFailureRollsBackEveryChange() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let occurrence = try await makeScheduledOccurrence(repository: repository, dateKey: "2026-07-10")
    let before = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)
    try executeSQLite(
        "CREATE TRIGGER reject_snapshot_update BEFORE UPDATE ON snapshots BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
        at: databaseURL
    )
    defer { try? executeSQLite("DROP TRIGGER IF EXISTS reject_snapshot_update", at: databaseURL) }

    await #expect(throws: Error.self) {
        try await repository.closeoutLesson(makeCloseoutInput(
            studentId: PreviewData.minjiId,
            occurrenceId: occurrence.id
        ))
    }
    try executeSQLite("DROP TRIGGER IF EXISTS reject_snapshot_update", at: databaseURL)
    let after = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)

    #expect(after.recentNotes.count == before.recentNotes.count)
    #expect(after.nextPlan == before.nextPlan)
}

@MainActor
@Test func closeoutRequiresScheduledOccurrenceContext() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let before = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)

    await #expect(throws: ValidationError.self) {
        try await repository.closeoutLesson(makeCloseoutInput(studentId: PreviewData.minjiId))
    }

    let after = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)
    #expect(after.recentNotes.count == before.recentNotes.count)
}

@MainActor
@Test func closeoutCompletesOccurrenceAndRejectsDuplicateCloseout() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let occurrence = try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "김민지 드럼 레슨",
        startsAt: "2026-08-06T10:00:00Z",
        endsAt: "2026-08-06T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))
    let input = makeCloseoutInput(studentId: PreviewData.minjiId, occurrenceId: occurrence.id)

    try await repository.closeoutLesson(input)
    let completed = try await repository.loadOccurrence(id: occurrence.id)
    let noteCount = try await repository.loadStudentDetail(studentId: PreviewData.minjiId).recentNotes.count

    #expect(completed.status == .completed)
    await #expect(throws: ValidationError.self) {
        try await repository.closeoutLesson(input)
    }
    await #expect(throws: ValidationError.self) {
        _ = try await repository.editOccurrence(EditOccurrenceInput(
            occurrenceId: occurrence.id,
            startsAt: "2026-08-06T11:00:00Z",
            endsAt: "2026-08-06T11:50:00Z",
            timezone: "Asia/Seoul"
        ))
    }
    await #expect(throws: ValidationError.self) {
        _ = try await repository.cancelOccurrence(id: occurrence.id)
    }
    #expect(try await repository.loadStudentDetail(studentId: PreviewData.minjiId).recentNotes.count == noteCount)
}

@MainActor
@Test func weeklyTemplatePersistsAndExpandsWhenLaterWeekIsLoaded() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let firstRepository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let initial = try await firstRepository.createWeeklySchedule(WeeklyScheduleInput(
        studentId: PreviewData.minjiId,
        title: "김민지 주간 레슨",
        defaultDurationMinutes: 50,
        timezone: "Asia/Seoul",
        recurrenceInterval: 1,
        recurrenceWeekday: 4,
        startsOn: "2026-05-28",
        endsOn: nil,
        startTime: "19:00"
    ))
    #expect(initial.count == 8)

    let reopened = try LocalSQLiteRepository(databaseURL: databaseURL)
    let laterWeek = try #require(ISO8601DateFormatter.plain.date(from: "2026-08-06T12:00:00Z"))
    let workbench = try await reopened.loadCalendarWorkbench(weekContaining: laterWeek)
    let laterOccurrence = workbench.days
        .flatMap(\.events)
        .first { $0.title == "김민지 주간 레슨" && $0.dateKey == "2026-08-06" }

    #expect(laterOccurrence != nil)
    let pending = try await reopened.loadPendingNativeCalendarOccurrences()
    #expect(pending.contains { $0.id == laterOccurrence?.id })
}

@MainActor
@Test func movingRecurringOccurrencePreservesOriginalTemplateSlot() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let initial = try await repository.createWeeklySchedule(WeeklyScheduleInput(
        studentId: PreviewData.minjiId,
        title: "김민지 주간 레슨",
        defaultDurationMinutes: 50,
        timezone: "Asia/Seoul",
        recurrenceInterval: 1,
        recurrenceWeekday: 4,
        startsOn: "2026-05-28",
        endsOn: nil,
        startTime: "19:00"
    ))
    let first = try #require(initial.first)
    let templateId = try #require(first.scheduleTemplateId)

    _ = try await repository.editOccurrence(EditOccurrenceInput(
        occurrenceId: first.id,
        startsAt: "2026-05-29T10:00:00Z",
        endsAt: "2026-05-29T10:50:00Z",
        timezone: "Asia/Seoul"
    ))
    let originalWeek = try #require(ISO8601DateFormatter.plain.date(from: "2026-05-28T12:00:00Z"))
    _ = try await repository.loadCalendarWorkbench(weekContaining: originalWeek)
    let recurring = try await repository.loadPendingNativeCalendarOccurrences()
        .filter { $0.scheduleTemplateId == templateId }

    #expect(recurring.count == initial.count)
    #expect(recurring.first { $0.id == first.id }?.recurrenceSlotDate == "2026-05-28")
}

@MainActor
@Test func unrelatedCanceledOccurrenceDoesNotSuppressWeeklyExpansion() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let unrelated = try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: PreviewData.joonId,
        title: "박준 레슨",
        startsAt: "2026-05-28T09:00:00Z",
        endsAt: "2026-05-28T10:00:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 60
    ))
    _ = try await repository.cancelOccurrence(id: unrelated.id)

    let expanded = try await repository.createWeeklySchedule(WeeklyScheduleInput(
        studentId: PreviewData.minjiId,
        title: "김민지 주간 레슨",
        defaultDurationMinutes: 50,
        timezone: "Asia/Seoul",
        recurrenceInterval: 1,
        recurrenceWeekday: 4,
        startsOn: "2026-05-28",
        endsOn: nil,
        startTime: "19:00"
    ))

    #expect(expanded.count == 8)
    #expect(expanded.first.map { DateOnly.string(fromISOInstant: $0.startsAt, timeZoneIdentifier: $0.timezone) } == "2026-05-28")
}

@MainActor
@Test func progressStatusTransitionsAreEnforcedByRepositoryWrites() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let itemId = try await repository.upsertProgressItem(ProgressItemInput(
        studentId: PreviewData.minjiId,
        progressItemId: nil,
        category: .technique,
        status: .new,
        title: "새 진도",
        detail: "기초 확인",
        tempoNote: nil,
        observedOn: "2026-07-10",
        currentFocus: false
    ))

    await #expect(throws: ValidationError.self) {
        try await repository.updateProgressStatus(ProgressStatusTransitionInput(
            studentId: PreviewData.minjiId,
            progressItemId: itemId,
            nextStatus: .complete
        ))
    }
    await #expect(throws: ValidationError.self) {
        _ = try await repository.upsertProgressItem(ProgressItemInput(
            studentId: PreviewData.minjiId,
            progressItemId: itemId,
            category: .technique,
            status: .complete,
            title: "새 진도",
            detail: "기초 확인",
            tempoNote: nil,
            observedOn: "2026-07-10",
            currentFocus: false
        ))
    }

    let detail = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)
    #expect(detail.progressItems.first { $0.id == itemId }?.status == .new)
}

@MainActor
@Test func repositoryRejectsMissingParentsAndCrossStudentRelatedIds() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let missingStudentId = UUID()

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.createLessonNote(LessonNoteInput(
            studentId: missingStudentId,
            lessonDate: "2026-07-10",
            coveredMaterial: "내용",
            observations: "관찰",
            practiceAssigned: "연습",
            nextStepHint: "다음"
        ))
    }
    await #expect(throws: RepositoryError.self) {
        _ = try await repository.createOneOffOccurrence(ScheduleLessonInput(
            studentId: missingStudentId,
            title: "고아 일정",
            startsAt: "2026-08-06T10:00:00Z",
            endsAt: "2026-08-06T11:00:00Z",
            timezone: "Asia/Seoul",
            durationMinutes: 60
        ))
    }

    let assignmentId = try await repository.upsertAssignment(AssignmentInput(
        studentId: PreviewData.minjiId,
        assignmentId: nil,
        title: "민지 과제",
        status: .inProgress,
        dueDate: nil,
        detail: "반복 연습"
    ))
    await #expect(throws: RepositoryError.self) {
        _ = try await repository.upsertAssignment(AssignmentInput(
            studentId: PreviewData.joonId,
            assignmentId: assignmentId,
            title: "잘못된 이동",
            status: .complete,
            dueDate: nil,
            detail: "학생 간 이동 시도"
        ))
    }
    #expect(try await repository.loadStudentDetail(studentId: PreviewData.minjiId).assignment?.id == assignmentId)
}

@MainActor
@Test func twoRepositoryInstancesMergeWritesFromLatestDatabaseSnapshot() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let first = try LocalSQLiteRepository(databaseURL: databaseURL)
    let second = try LocalSQLiteRepository(databaseURL: databaseURL)

    let firstId = try await first.createStudent(StudentProfileInput(
        studentId: nil,
        name: "첫 학생",
        profileCue: "첫 단서",
        primaryWeakPoint: "첫 약점",
        active: true
    ))
    let secondId = try await second.createStudent(StudentProfileInput(
        studentId: nil,
        name: "둘째 학생",
        profileCue: "둘째 단서",
        primaryWeakPoint: "둘째 약점",
        active: true
    ))

    let reopened = try LocalSQLiteRepository(databaseURL: databaseURL)
    #expect(try await reopened.loadStudentDetail(studentId: firstId).name == "첫 학생")
    #expect(try await reopened.loadStudentDetail(studentId: secondId).name == "둘째 학생")
}

@MainActor
@Test func snapshotWithoutTemplatesKeyStillDecodes() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    _ = try LocalSQLiteRepository(databaseURL: databaseURL)
    try executeSQLite(
        "UPDATE snapshots SET value = CAST(json_remove(CAST(value AS TEXT), '$.templates') AS BLOB) WHERE key = 'app_snapshot'",
        at: databaseURL
    )

    let reopened = try LocalSQLiteRepository(databaseURL: databaseURL)
    #expect(try await reopened.loadRoster().count == PreviewData.students.filter(\.active).count)
}

private func makeCloseoutInput(studentId: EntityID, occurrenceId: EntityID? = nil) -> LessonCloseoutInput {
    LessonCloseoutInput(
        studentId: studentId,
        lessonDate: "2026-07-10",
        coveredMaterial: "코러스 전 필인",
        observations: "착지가 흔들림",
        practiceAssigned: "2마디 루프",
        nextStepHint: "1박 착지",
        nextPlanId: nil,
        nextAction: "1박 착지",
        nextPlanDetail: "필인 뒤 착지 확인",
        plannedFor: "2026-07-17",
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

@MainActor
private func makeScheduledOccurrence(
    repository: LocalSQLiteRepository,
    dateKey: String
) async throws -> LessonOccurrence {
    try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "김민지 드럼 레슨",
        startsAt: "\(dateKey)T10:00:00Z",
        endsAt: "\(dateKey)T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))
}

private func executeSQLite(_ sql: String, at databaseURL: URL) throws {
    var database: OpaquePointer?
    guard sqlite3_open(databaseURL.path, &database) == SQLITE_OK else {
        throw RepositoryError(message: "테스트 SQLite를 열 수 없습니다.")
    }
    defer { sqlite3_close(database) }

    var errorMessage: UnsafeMutablePointer<CChar>?
    guard sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK else {
        let message = errorMessage.map { String(cString: $0) } ?? "테스트 SQLite 실행 실패"
        sqlite3_free(errorMessage)
        throw RepositoryError(message: message)
    }
}

private func removeSQLiteFiles(at databaseURL: URL) {
    try? FileManager.default.removeItem(at: databaseURL)
    try? FileManager.default.removeItem(atPath: databaseURL.path + "-wal")
    try? FileManager.default.removeItem(atPath: databaseURL.path + "-shm")
}

private func temporarySQLiteURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-\(UUID().uuidString)")
        .appendingPathExtension("sqlite")
}
