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
@Test func deletingStudentRemovesEveryRelatedLocalRecord() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let studentId = try await repository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "삭제할 학생",
        profileCue: "삭제 테스트",
        primaryWeakPoint: "없음",
        active: true
    ))
    _ = try await repository.upsertTrait(StudentTraitInput(
        studentId: studentId,
        traitId: nil,
        type: .practiceHabit,
        label: "짧게 자주",
        detail: "10분 루틴"
    ))
    let progressItemId = try await repository.upsertProgressItem(ProgressItemInput(
        studentId: studentId,
        progressItemId: nil,
        category: .rudiment,
        status: .inProgress,
        title: "싱글 스트로크",
        detail: "힘 빼기",
        tempoNote: nil,
        observedOn: "2026-07-11",
        currentFocus: true
    ))
    _ = try await repository.createProgressCheckpoint(ProgressCheckpointInput(
        studentId: studentId,
        progressItemId: progressItemId,
        observedOn: "2026-07-11",
        bpm: 90,
        status: .inProgress,
        note: "30초 유지"
    ))
    _ = try await repository.upsertAssignment(AssignmentInput(
        studentId: studentId,
        assignmentId: nil,
        title: "2마디 루프",
        status: .notStarted,
        dueDate: nil,
        detail: "천천히 5회"
    ))
    _ = try await repository.createLessonNote(LessonNoteInput(
        studentId: studentId,
        lessonDate: "2026-07-11",
        coveredMaterial: "8비트",
        observations: "안정적",
        practiceAssigned: "2마디 루프",
        nextStepHint: "필인 연결"
    ))
    _ = try await repository.upsertNextPlan(NextPlanInput(
        studentId: studentId,
        planId: nil,
        plannedFor: nil,
        priority: .normal,
        nextAction: "필인 연결",
        detail: "느린 템포부터"
    ))

    try await repository.deleteStudent(studentId: studentId)

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.loadStudentDetail(studentId: studentId)
    }
    let backupData = try await repository.makeBackupData()
    let payload = try #require(JSONSerialization.jsonObject(with: backupData) as? [String: Any])
    let snapshot = try #require(payload["snapshot"] as? [String: Any])
    let students = try #require(snapshot["students"] as? [[String: Any]])
    #expect(!students.contains { $0["id"] as? String == studentId.uuidString })

    for key in [
        "progressItems",
        "progressCheckpoints",
        "traits",
        "assignments",
        "notes",
        "plans",
        "templates",
        "occurrences",
        "tuitionCycles"
    ] {
        let records = try #require(snapshot[key] as? [[String: Any]])
        #expect(!records.contains { $0["student_id"] as? String == studentId.uuidString })
    }

    let reopenedRepository = try LocalSQLiteRepository(databaseURL: databaseURL)
    await #expect(throws: RepositoryError.self) {
        _ = try await reopenedRepository.loadStudentDetail(studentId: studentId)
    }
}

@MainActor
@Test func deletingStudentRequiresCalendarWorkToBeFinished() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let studentId = try await repository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "일정 있는 학생",
        profileCue: "삭제 차단 테스트",
        primaryWeakPoint: "없음",
        active: true
    ))
    let occurrence = try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: studentId,
        title: "삭제 전 레슨",
        startsAt: "2026-08-06T10:00:00Z",
        endsAt: "2026-08-06T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))

    await #expect(throws: RepositoryError.self) {
        try await repository.deleteStudent(studentId: studentId)
    }
    _ = try await repository.cancelOccurrence(id: occurrence.id)
    await #expect(throws: RepositoryError.self) {
        try await repository.deleteStudent(studentId: studentId)
    }

    try await repository.updateNativeCalendarSync(NativeCalendarSyncUpdateInput(
        occurrenceId: occurrence.id,
        status: .synced,
        eventIdentifier: nil,
        calendarIdentifier: nil,
        externalIdentifier: nil,
        error: nil,
        syncedAt: "2026-07-11T00:00:00Z"
    ))
    try await repository.deleteStudent(studentId: studentId)

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.loadOccurrence(id: occurrence.id)
    }
}

@MainActor
@Test func localBackupRestoreIsReversibleAndPausesPendingCalendarWork() async throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-Backup-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let databaseURL = directory.appendingPathComponent("DrumLessonOS.sqlite")
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let occurrence = try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "복원 테스트 레슨",
        startsAt: "2026-08-06T10:00:00Z",
        endsAt: "2026-08-06T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))
    let backupData = try await repository.makeBackupData()
    let laterStudentID = try await repository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "백업 이후 학생",
        profileCue: "복원 전 상태에만 존재",
        primaryWeakPoint: "없음",
        active: true
    ))

    let safetyBackupURL = try await repository.restoreBackup(from: backupData)

    #expect(FileManager.default.fileExists(atPath: safetyBackupURL.path))
    await #expect(throws: RepositoryError.self) {
        _ = try await repository.loadStudentDetail(studentId: laterStudentID)
    }
    let restoredOccurrence = try await repository.loadOccurrence(id: occurrence.id)
    #expect(restoredOccurrence.nativeCalendarSyncStatus == .failed)
    #expect(restoredOccurrence.nativeCalendarSyncError?.contains("수동으로 재시도") == true)
    #expect(try await repository.loadPendingNativeCalendarOccurrences().contains { $0.id == occurrence.id } == false)

    let safetyBackupData = try Data(contentsOf: safetyBackupURL)
    _ = try await repository.restoreBackup(from: safetyBackupData)
    #expect(try await repository.loadStudentDetail(studentId: laterStudentID).name == "백업 이후 학생")
}

@MainActor
@Test func invalidBackupDoesNotModifyCurrentSnapshot() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let studentID = try await repository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "유지되어야 하는 학생",
        profileCue: "잘못된 복원 뒤에도 유지",
        primaryWeakPoint: "없음",
        active: true
    ))

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.restoreBackup(from: Data("not-a-backup".utf8))
    }

    let validBackup = try await repository.makeBackupData()
    var unsupported = try #require(JSONSerialization.jsonObject(with: validBackup) as? [String: Any])
    unsupported["formatVersion"] = 999
    await #expect(throws: RepositoryError.self) {
        _ = try await repository.restoreBackup(from: JSONSerialization.data(withJSONObject: unsupported))
    }

    #expect(try await repository.loadStudentDetail(studentId: studentID).name == "유지되어야 하는 학생")
}

@MainActor
@Test func backupWithDuplicateTemplateIdIsRejectedWithoutCrashing() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    _ = try await repository.createWeeklySchedule(WeeklyScheduleInput(
        studentId: PreviewData.minjiId,
        title: "중복 검증 주간 레슨",
        defaultDurationMinutes: 50,
        timezone: "Asia/Seoul",
        recurrenceInterval: 1,
        recurrenceWeekday: 4,
        startsOn: "2026-05-28",
        endsOn: nil,
        startTime: "19:00"
    ))

    let validBackup = try await repository.makeBackupData()
    var object = try #require(JSONSerialization.jsonObject(with: validBackup) as? [String: Any])
    var snapshot = try #require(object["snapshot"] as? [String: Any])
    var templates = try #require(snapshot["templates"] as? [[String: Any]])
    templates.append(try #require(templates.first))
    snapshot["templates"] = templates
    object["snapshot"] = snapshot

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.restoreBackup(from: JSONSerialization.data(withJSONObject: object))
    }
}

@MainActor
@Test func backupRejectsDuplicateOccurrenceAndBrokenTemplateReference() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let validBackup = try await repository.makeBackupData()

    var duplicateObject = try #require(JSONSerialization.jsonObject(with: validBackup) as? [String: Any])
    var duplicateSnapshot = try #require(duplicateObject["snapshot"] as? [String: Any])
    var occurrences = try #require(duplicateSnapshot["occurrences"] as? [[String: Any]])
    occurrences.append(try #require(occurrences.first))
    duplicateSnapshot["occurrences"] = occurrences
    duplicateObject["snapshot"] = duplicateSnapshot

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.restoreBackup(from: JSONSerialization.data(withJSONObject: duplicateObject))
    }

    var brokenObject = try #require(JSONSerialization.jsonObject(with: validBackup) as? [String: Any])
    var brokenSnapshot = try #require(brokenObject["snapshot"] as? [String: Any])
    var brokenOccurrences = try #require(brokenSnapshot["occurrences"] as? [[String: Any]])
    brokenOccurrences[0]["schedule_template_id"] = UUID().uuidString
    brokenSnapshot["occurrences"] = brokenOccurrences
    brokenObject["snapshot"] = brokenSnapshot

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.restoreBackup(from: JSONSerialization.data(withJSONObject: brokenObject))
    }
}

@MainActor
@Test func progressCheckpointsAppendWithoutOverwritingProgressItem() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let itemID = try await repository.upsertProgressItem(ProgressItemInput(
        studentId: PreviewData.minjiId,
        progressItemId: nil,
        category: .rudiment,
        status: .inProgress,
        title: "싱글 스트로크",
        detail: "힘을 빼고 일정하게",
        tempoNote: "기준 80 BPM",
        observedOn: "2026-07-01",
        currentFocus: false
    ))

    _ = try await repository.createProgressCheckpoint(ProgressCheckpointInput(
        studentId: PreviewData.minjiId,
        progressItemId: itemID,
        observedOn: "2026-07-04",
        bpm: 90,
        status: .inProgress,
        note: "오른손이 먼저 긴장함"
    ))
    _ = try await repository.createProgressCheckpoint(ProgressCheckpointInput(
        studentId: PreviewData.minjiId,
        progressItemId: itemID,
        observedOn: "2026-07-11",
        bpm: 100,
        status: .inProgress,
        note: "30초 유지"
    ))

    let reopened = try LocalSQLiteRepository(databaseURL: databaseURL)
    let detail = try await reopened.loadStudentDetail(studentId: PreviewData.minjiId)
    let item = try #require(detail.progressItems.first { $0.id == itemID })

    #expect(item.checkpoints.map(\.bpm) == [100, 90])
    #expect(item.checkpoints.map(\.note) == ["30초 유지", "오른손이 먼저 긴장함"])
    #expect(item.observedOn == "2026-07-01")
    #expect(item.tempoNote == "기준 80 BPM")

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.createProgressCheckpoint(ProgressCheckpointInput(
            studentId: PreviewData.joonId,
            progressItemId: itemID,
            observedOn: "2026-07-11",
            bpm: 100,
            status: .inProgress,
            note: "잘못된 학생 연결"
        ))
    }
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
    _ = try await repository.upsertLessonDraft(LessonDraftInput(
        occurrenceId: occurrence.id,
        studentId: PreviewData.minjiId,
        coveredMaterial: "롤백할 진행",
        observations: "롤백할 관찰",
        practiceAssigned: "롤백할 과제",
        nextStepHint: "롤백할 다음 확인"
    ))
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
    #expect(try await repository.loadLessonDraft(occurrenceId: occurrence.id)?.coveredMaterial == "롤백할 진행")
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
@Test func closeoutRejectsFutureOccurrenceWithoutChangingStudentHistory() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let now = try #require(ISO8601DateFormatter.plain.date(from: "2026-07-11T00:00:00Z"))
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL, currentDate: { now })
    let occurrence = try await makeScheduledOccurrence(repository: repository, dateKey: "2026-08-06")
    let before = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)

    await #expect(throws: ValidationError.self) {
        try await repository.closeoutLesson(makeCloseoutInput(
            studentId: PreviewData.minjiId,
            occurrenceId: occurrence.id,
            lessonDate: "2026-08-06"
        ))
    }

    let unchangedOccurrence = try await repository.loadOccurrence(id: occurrence.id)
    let after = try await repository.loadStudentDetail(studentId: PreviewData.minjiId)
    #expect(unchangedOccurrence.status == .scheduled)
    #expect(after.recentNotes.count == before.recentNotes.count)
}

@MainActor
@Test func closeoutCompletesOccurrenceAndRejectsDuplicateCloseout() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let now = try #require(ISO8601DateFormatter.plain.date(from: "2026-08-06T12:00:00Z"))
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL, currentDate: { now })
    let occurrence = try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: PreviewData.minjiId,
        title: "김민지 드럼 레슨",
        startsAt: "2026-08-06T10:00:00Z",
        endsAt: "2026-08-06T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))
    let input = makeCloseoutInput(
        studentId: PreviewData.minjiId,
        occurrenceId: occurrence.id,
        lessonDate: "2026-08-06"
    )
    _ = try await repository.upsertLessonDraft(LessonDraftInput(
        occurrenceId: occurrence.id,
        studentId: PreviewData.minjiId,
        coveredMaterial: "저장 중인 내용",
        observations: "저장 중인 관찰",
        practiceAssigned: "저장 중인 과제",
        nextStepHint: "저장 중인 다음 확인"
    ))

    try await repository.closeoutLesson(input)
    let completed = try await repository.loadOccurrence(id: occurrence.id)
    let noteCount = try await repository.loadStudentDetail(studentId: PreviewData.minjiId).recentNotes.count

    #expect(completed.status == .completed)
    #expect(try await repository.loadLessonDraft(occurrenceId: occurrence.id) == nil)
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
@Test func cancelingOccurrenceDeletesItsLessonDraft() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let occurrence = try await makeScheduledOccurrence(repository: repository, dateKey: "2026-07-10")
    _ = try await repository.upsertLessonDraft(LessonDraftInput(
        occurrenceId: occurrence.id,
        studentId: PreviewData.minjiId,
        coveredMaterial: "취소할 레슨 초안",
        observations: "관찰",
        practiceAssigned: "과제",
        nextStepHint: "다음"
    ))

    _ = try await repository.cancelOccurrence(id: occurrence.id)

    #expect(try await repository.loadLessonDraft(occurrenceId: occurrence.id) == nil)
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
@Test func legacySnapshotWithoutNewCollectionKeysStillDecodes() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    _ = try LocalSQLiteRepository(databaseURL: databaseURL)
    try executeSQLite(
        "UPDATE snapshots SET value = CAST(json_remove(CAST(value AS TEXT), '$.templates', '$.progressCheckpoints', '$.tuitionCycles', '$.lessonDrafts') AS BLOB) WHERE key = 'app_snapshot'",
        at: databaseURL
    )

    let reopened = try LocalSQLiteRepository(databaseURL: databaseURL)
    #expect(try await reopened.loadRoster().count == PreviewData.students.filter(\.active).count)
    let detail = try await reopened.loadStudentDetail(studentId: PreviewData.minjiId)
    #expect(detail.progressItems.allSatisfy { $0.checkpoints.isEmpty })
    #expect(try await reopened.loadTuitionRoster().allSatisfy { $0.currentCycle == nil })
    #expect(try await reopened.loadLessonDraft(occurrenceId: PreviewData.occurrences[0].id) == nil)
}

@MainActor
@Test func lessonDraftsRoundTripInVersionThreeBackupAndOlderVersionsStillRestore() async throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DrumLessonOS-TuitionBackup-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let databaseURL = directory.appendingPathComponent("DrumLessonOS.sqlite")
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let cycleId = try await repository.configureTuitionCycle(
        studentId: PreviewData.minjiId,
        completedLessonCount: 2,
        paymentConfirmedOn: "2026-07-11"
    )
    let occurrence = PreviewData.occurrences[0]
    _ = try await repository.upsertLessonDraft(LessonDraftInput(
        occurrenceId: occurrence.id,
        studentId: occurrence.studentId,
        coveredMaterial: "코러스 전 필인",
        observations: "오른손 긴장",
        practiceAssigned: "84 BPM 반복",
        nextStepHint: "1박 착지"
    ))
    let reopened = try LocalSQLiteRepository(databaseURL: databaseURL)
    #expect(try await reopened.loadLessonDraft(occurrenceId: occurrence.id)?.observations == "오른손 긴장")
    let versionThreeBackup = try await repository.makeBackupData()
    var backupObject = try #require(JSONSerialization.jsonObject(with: versionThreeBackup) as? [String: Any])

    #expect(backupObject["formatVersion"] as? Int == 3)
    try await repository.setTuitionPaymentConfirmation(
        cycleId: cycleId,
        studentId: PreviewData.minjiId,
        confirmedOn: nil
    )
    try await repository.deleteLessonDraft(occurrenceId: occurrence.id)
    _ = try await repository.restoreBackup(from: versionThreeBackup)
    let restoredRoster = try await repository.loadTuitionRoster()
    let restoredItem = try #require(restoredRoster.first { $0.studentId == PreviewData.minjiId })
    let restoredCycle = try #require(restoredItem.currentCycle)
    #expect(restoredCycle.completedLessonCount == 2)
    #expect(restoredCycle.paymentConfirmedOn == "2026-07-11")
    #expect(try await repository.loadLessonDraft(occurrenceId: occurrence.id)?.coveredMaterial == "코러스 전 필인")

    backupObject["formatVersion"] = 2
    var versionTwoSnapshot = try #require(backupObject["snapshot"] as? [String: Any])
    versionTwoSnapshot.removeValue(forKey: "lessonDrafts")
    backupObject["snapshot"] = versionTwoSnapshot
    let versionTwoBackup = try JSONSerialization.data(withJSONObject: backupObject)

    _ = try await repository.restoreBackup(from: versionTwoBackup)
    #expect(try await repository.loadLessonDraft(occurrenceId: occurrence.id) == nil)
    let versionTwoRoster = try await repository.loadTuitionRoster()
    #expect(versionTwoRoster.first { $0.studentId == PreviewData.minjiId }?.currentCycle != nil)

    backupObject["formatVersion"] = 1
    var legacySnapshot = try #require(backupObject["snapshot"] as? [String: Any])
    legacySnapshot.removeValue(forKey: "tuitionCycles")
    backupObject["snapshot"] = legacySnapshot
    let versionOneBackup = try JSONSerialization.data(withJSONObject: backupObject)

    _ = try await repository.restoreBackup(from: versionOneBackup)
    let legacyRoster = try await repository.loadTuitionRoster()
    let legacyItem = try #require(legacyRoster.first { $0.studentId == PreviewData.minjiId })
    #expect(legacyItem.currentCycle == nil)
}

@MainActor
@Test func backupRejectsDraftWithoutMatchingScheduledOccurrence() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let occurrence = PreviewData.occurrences[0]
    _ = try await repository.upsertLessonDraft(LessonDraftInput(
        occurrenceId: occurrence.id,
        studentId: occurrence.studentId,
        coveredMaterial: "검증할 초안",
        observations: "관찰",
        practiceAssigned: "과제",
        nextStepHint: "다음"
    ))
    let validBackup = try await repository.makeBackupData()
    var object = try #require(JSONSerialization.jsonObject(with: validBackup) as? [String: Any])
    var snapshot = try #require(object["snapshot"] as? [String: Any])
    var drafts = try #require(snapshot["lessonDrafts"] as? [[String: Any]])
    drafts[0]["occurrence_id"] = UUID().uuidString
    snapshot["lessonDrafts"] = drafts
    object["snapshot"] = snapshot

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.restoreBackup(from: JSONSerialization.data(withJSONObject: object))
    }
}

@MainActor
@Test func localSQLiteRepositoryResetKeepsInstructorAndPersistsEmptyRecords() async throws {
    let databaseURL = temporarySQLiteURL()
    defer { removeSQLiteFiles(at: databaseURL) }
    let repository = try LocalSQLiteRepository(databaseURL: databaseURL)
    let instructor = try await repository.loadCurrentInstructor()
    let occurrence = PreviewData.occurrences[0]
    _ = try await repository.upsertLessonDraft(LessonDraftInput(
        occurrenceId: occurrence.id,
        studentId: occurrence.studentId,
        coveredMaterial: "초기화할 초안",
        observations: "",
        practiceAssigned: "",
        nextStepHint: ""
    ))

    try await repository.resetLocalData()

    #expect(try await repository.loadCurrentInstructor() == instructor)
    #expect(try await repository.loadRoster().isEmpty)
    #expect(try await repository.loadTuitionRoster().isEmpty)
    #expect(try await repository.loadOccurrencesForDataReset().isEmpty)

    let backupData = try await repository.makeBackupData()
    let payload = try #require(JSONSerialization.jsonObject(with: backupData) as? [String: Any])
    let snapshot = try #require(payload["snapshot"] as? [String: Any])
    let recordKeys = [
        "students",
        "progressItems",
        "progressCheckpoints",
        "traits",
        "assignments",
        "notes",
        "plans",
        "templates",
        "occurrences",
        "tuitionCycles",
        "lessonDrafts"
    ]
    for key in recordKeys {
        #expect((snapshot[key] as? [Any])?.isEmpty == true)
    }

    let reopened = try LocalSQLiteRepository(databaseURL: databaseURL)
    #expect(try await reopened.loadRoster().isEmpty)
    #expect(try await reopened.loadOccurrencesForDataReset().isEmpty)
}

private func makeCloseoutInput(
    studentId: EntityID,
    occurrenceId: EntityID? = nil,
    lessonDate: String = "2026-07-10"
) -> LessonCloseoutInput {
    LessonCloseoutInput(
        studentId: studentId,
        lessonDate: lessonDate,
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
