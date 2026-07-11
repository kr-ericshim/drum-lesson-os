import Foundation
import SQLite3

@MainActor
final class LocalSQLiteRepository: StudentRepository, StudentWriteRepository, ScheduleRepository, TuitionRepository, LessonDraftRepository, LocalDataBackupRepository, LocalDataResetStore {
    private let store: LocalSQLiteStore
    private let databaseURL: URL
    private let currentDate: () -> Date
    private var snapshot: LocalAppSnapshot

    convenience init() throws {
        try self.init(databaseURL: Self.defaultDatabaseURL())
    }

    init(databaseURL: URL, currentDate: @escaping () -> Date = Date.init) throws {
        let openedStore = try LocalSQLiteStore(databaseURL: databaseURL)
        store = openedStore
        self.databaseURL = databaseURL
        self.currentDate = currentDate
        snapshot = try openedStore.withImmediateTransaction {
            if let data = try openedStore.loadData(forKey: Self.snapshotKey) {
                return try JSONDecoder().decode(LocalAppSnapshot.self, from: data)
            }
            let seed = LocalAppSnapshot.seed
            try openedStore.saveData(JSONEncoder().encode(seed), forKey: Self.snapshotKey)
            return seed
        }
    }

    static func defaultDatabaseURL() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = baseURL.appendingPathComponent("DrumLessonOS", isDirectory: true)
        try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory.appendingPathComponent("DrumLessonOS.sqlite")
    }

    func loadCurrentInstructor() async throws -> Instructor {
        try refreshSnapshot()
        return snapshot.instructor
    }

    func loadRoster() async throws -> [StudentRosterItem] {
        try refreshSnapshot()
        return mapRoster(snapshot)
    }

    func loadTuitionRoster() async throws -> [TuitionRosterItem] {
        try refreshSnapshot()
        return snapshot.students
            .filter(\.active)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { student in
                TuitionRosterItem(
                    studentId: student.id,
                    studentName: student.name,
                    cycles: snapshot.tuitionCycles.filter { $0.studentId == student.id }
                )
            }
    }

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        try refreshSnapshot()
        guard let student = snapshot.students.first(where: { $0.id == studentId }) else {
            throw RepositoryError.notFound
        }

        return StudentDetailMapper.map(
            student: student,
            progressItems: snapshot.progressItems.filter { $0.studentId == studentId },
            progressCheckpoints: snapshot.progressCheckpoints.filter { $0.studentId == studentId },
            traits: snapshot.traits.filter { $0.studentId == studentId },
            assignments: snapshot.assignments.filter { $0.studentId == studentId },
            notes: snapshot.notes.filter { $0.studentId == studentId },
            nextPlans: snapshot.plans.filter { $0.studentId == studentId },
            todayDate: DateOnly.string(from: currentDate(), timeZone: .current)
        )
    }

    func loadUpcomingLessons(studentId: EntityID, after date: Date, limit: Int) async throws -> [StudentUpcomingLesson] {
        try expandRecurringSchedules(
            from: date,
            horizonWeeks: 25,
            studentId: studentId
        )
        return StudentUpcomingLessonMapper.map(
            occurrences: snapshot.occurrences,
            studentId: studentId,
            after: date,
            limit: limit
        )
    }

    func loadCalendarWorkbench(weekContaining date: Date) async throws -> CalendarWorkbench {
        try expandRecurringSchedules(weekContaining: date)
        let roster = mapRoster(snapshot)
        return CalendarWorkbenchMapper.map(
            occurrences: snapshot.occurrences,
            students: roster,
            weekContaining: date,
            timezone: TimeZone.current.identifier
        )
    }

    func loadLessonDraft(occurrenceId: EntityID) async throws -> LessonDraft? {
        try refreshSnapshot()
        return snapshot.lessonDrafts.first { $0.occurrenceId == occurrenceId }
    }

    func upsertLessonDraft(_ input: LessonDraftInput) async throws -> LessonDraft {
        try StudentEditingValidation.validate(input)
        return try mutateSnapshot { snapshot in
            guard let occurrence = snapshot.occurrences.first(where: { $0.id == input.occurrenceId }),
                  occurrence.studentId == input.studentId,
                  occurrence.status == .scheduled else {
                throw ValidationError(field: "occurrenceId", message: "예정 상태인 레슨에만 초안을 저장할 수 있습니다.")
            }
            let draft = LessonDraft(
                occurrenceId: input.occurrenceId,
                studentId: input.studentId,
                coveredMaterial: input.coveredMaterial,
                observations: input.observations,
                practiceAssigned: input.practiceAssigned,
                nextStepHint: input.nextStepHint,
                updatedAt: nowString()
            )
            snapshot.lessonDrafts.removeAll { $0.occurrenceId == input.occurrenceId }
            snapshot.lessonDrafts.append(draft)
            return draft
        }
    }

    func deleteLessonDraft(occurrenceId: EntityID) async throws {
        try mutateSnapshot { snapshot in
            snapshot.lessonDrafts.removeAll { $0.occurrenceId == occurrenceId }
        }
    }

    func createStudent(_ input: StudentProfileInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let id = UUID()
        try mutateSnapshot { snapshot in
            let timestamp = nowString()
            snapshot.students.append(Student(
                id: id,
                instructorId: snapshot.instructor.id,
                name: input.name,
                profileCue: input.profileCue,
                primaryWeakPoint: input.primaryWeakPoint,
                active: input.active,
                createdAt: timestamp,
                updatedAt: timestamp
            ))
            snapshot.tuitionCycles.append(TuitionCycle(
                id: UUID(),
                instructorId: snapshot.instructor.id,
                studentId: id,
                sequence: 1,
                targetLessonCount: TuitionValidation.targetLessonCount,
                completedLessonCount: 0,
                paymentConfirmedOn: nil,
                createdAt: timestamp,
                updatedAt: timestamp
            ))
        }
        return id
    }

    func updateStudentProfile(_ input: StudentProfileInput) async throws {
        try StudentEditingValidation.validate(input)
        try mutateSnapshot { snapshot in
            guard let id = input.studentId,
                  let index = snapshot.students.firstIndex(where: { $0.id == id }) else {
                throw RepositoryError.notFound
            }
            snapshot.students[index].name = input.name
            snapshot.students[index].profileCue = input.profileCue
            snapshot.students[index].primaryWeakPoint = input.primaryWeakPoint
            snapshot.students[index].active = input.active
            snapshot.students[index].updatedAt = nowString()
        }
    }

    func deleteStudent(studentId: EntityID) async throws {
        try mutateSnapshot { snapshot in
            try requireStudent(studentId, in: snapshot)
            let relatedOccurrences = snapshot.occurrences.filter { $0.studentId == studentId }
            guard !relatedOccurrences.contains(where: { $0.status == .scheduled }) else {
                throw RepositoryError(message: "예정된 레슨이 있습니다. 캘린더에서 먼저 모두 취소한 뒤 학생을 삭제하세요.")
            }
            guard !relatedOccurrences.contains(where: {
                $0.nativeCalendarSyncStatus == .pending || $0.nativeCalendarSyncStatus == .failed
            }) else {
                throw RepositoryError(message: "Apple 캘린더 처리가 끝나지 않은 레슨이 있습니다. 동기화를 완료한 뒤 다시 시도하세요.")
            }

            snapshot.students.removeAll { $0.id == studentId }
            snapshot.progressItems.removeAll { $0.studentId == studentId }
            snapshot.progressCheckpoints.removeAll { $0.studentId == studentId }
            snapshot.traits.removeAll { $0.studentId == studentId }
            snapshot.assignments.removeAll { $0.studentId == studentId }
            snapshot.notes.removeAll { $0.studentId == studentId }
            snapshot.plans.removeAll { $0.studentId == studentId }
            snapshot.templates.removeAll { $0.studentId == studentId }
            snapshot.occurrences.removeAll { $0.studentId == studentId }
            snapshot.tuitionCycles.removeAll { $0.studentId == studentId }
            snapshot.lessonDrafts.removeAll { $0.studentId == studentId }
        }
    }

    func upsertTrait(_ input: StudentTraitInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let id = input.traitId ?? UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            _ = try relatedRecord(
                id: input.traitId,
                studentId: input.studentId,
                records: snapshot.traits,
                recordID: \.id,
                ownerID: \.studentId
            )
            snapshot.traits.removeAll { $0.id == id }
            snapshot.traits.append(StudentTrait(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                type: input.type,
                label: input.label,
                detail: input.detail
            ))
        }
        return id
    }

    func upsertProgressItem(_ input: ProgressItemInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let id = input.progressItemId ?? UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            let existing = try relatedRecord(
                id: input.progressItemId,
                studentId: input.studentId,
                records: snapshot.progressItems,
                recordID: \.id,
                ownerID: \.studentId
            )
            if let existing {
                try StudentEditingValidation.validateProgressStatusTransition(
                    currentStatus: existing.status,
                    nextStatus: input.status
                )
            }
            if input.currentFocus {
                for index in snapshot.progressItems.indices where snapshot.progressItems[index].studentId == input.studentId {
                    snapshot.progressItems[index].currentFocus = false
                }
            }
            snapshot.progressItems.removeAll { $0.id == id }
            snapshot.progressItems.append(ProgressItem(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                category: input.category,
                status: input.status,
                title: input.title,
                currentFocus: input.currentFocus,
                observedOn: input.observedOn,
                detail: input.detail,
                tempoNote: input.tempoNote,
                updatedAt: nowString()
            ))
        }
        return id
    }

    func createProgressCheckpoint(_ input: ProgressCheckpointInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let id = UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            guard let item = snapshot.progressItems.first(where: { $0.id == input.progressItemId }) else {
                throw RepositoryError.notFound
            }
            guard item.studentId == input.studentId else {
                throw RepositoryError(message: "선택한 진도 항목이 해당 학생에게 속하지 않습니다.")
            }
            guard item.status == input.status else {
                throw ValidationError(field: "status", message: "진도 상태가 변경되었습니다. 새로고침 후 다시 저장하세요.")
            }
            snapshot.progressCheckpoints.append(ProgressCheckpoint(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                progressItemId: input.progressItemId,
                observedOn: input.observedOn,
                bpm: input.bpm,
                status: input.status,
                note: input.note.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: nowString()
            ))
        }
        return id
    }

    func updateProgressStatus(_ input: ProgressStatusTransitionInput) async throws {
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            let existing = try relatedRecord(
                id: input.progressItemId,
                studentId: input.studentId,
                records: snapshot.progressItems,
                recordID: \.id,
                ownerID: \.studentId
            )
            guard let existing,
                  let index = snapshot.progressItems.firstIndex(where: { $0.id == existing.id }) else {
                throw RepositoryError.notFound
            }
            try StudentEditingValidation.validateProgressStatusTransition(
                currentStatus: existing.status,
                nextStatus: input.nextStatus
            )
            snapshot.progressItems[index].status = input.nextStatus
            snapshot.progressItems[index].updatedAt = nowString()
        }
    }

    func upsertAssignment(_ input: AssignmentInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let id = input.assignmentId ?? UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            _ = try relatedRecord(
                id: input.assignmentId,
                studentId: input.studentId,
                records: snapshot.assignments,
                recordID: \.id,
                ownerID: \.studentId
            )
            snapshot.assignments.removeAll { $0.id == id }
            snapshot.assignments.append(Assignment(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                title: input.title,
                status: input.status,
                dueDate: input.dueDate,
                detail: input.detail,
                updatedAt: nowString()
            ))
        }
        return id
    }

    func createLessonNote(_ input: LessonNoteInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let id = UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            snapshot.notes.append(LessonNote(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                lessonDate: input.lessonDate,
                coveredMaterial: input.coveredMaterial,
                observations: input.observations,
                practiceAssigned: input.practiceAssigned,
                nextStepHint: input.nextStepHint,
                createdAt: nowString()
            ))
        }
        return id
    }

    func upsertNextPlan(_ input: NextPlanInput) async throws -> EntityID {
        try StudentEditingValidation.validate(input)
        let id = input.planId ?? UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            let existing = try relatedRecord(
                id: input.planId,
                studentId: input.studentId,
                records: snapshot.plans,
                recordID: \.id,
                ownerID: \.studentId
            )
            let timestamp = nowString()
            snapshot.plans.removeAll { $0.id == id }
            snapshot.plans.append(NextLessonPlan(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                plannedFor: input.plannedFor,
                priority: input.priority,
                nextAction: input.nextAction,
                detail: input.detail,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            ))
        }
        return id
    }

    func closeoutLesson(_ input: LessonCloseoutInput) async throws {
        try StudentEditingValidation.validate(input)
        try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            let existingPlan = try relatedRecord(
                id: input.nextPlanId,
                studentId: input.studentId,
                records: snapshot.plans,
                recordID: \.id,
                ownerID: \.studentId
            )
            _ = try relatedRecord(
                id: input.assignmentId,
                studentId: input.studentId,
                records: snapshot.assignments,
                recordID: \.id,
                ownerID: \.studentId
            )
            let existingProgress = try relatedRecord(
                id: input.progressItemId,
                studentId: input.studentId,
                records: snapshot.progressItems,
                recordID: \.id,
                ownerID: \.studentId
            )
            guard let occurrence = try relatedRecord(
                id: input.occurrenceId,
                studentId: input.studentId,
                records: snapshot.occurrences,
                recordID: \.id,
                ownerID: \.studentId
            ) else {
                throw ValidationError(field: "occurrenceId", message: "예약된 레슨에서만 마무리 기록을 저장할 수 있습니다.")
            }

            if let existingProgress, let nextStatus = input.progressStatus {
                try StudentEditingValidation.validateProgressStatusTransition(
                    currentStatus: existingProgress.status,
                    nextStatus: nextStatus
                )
            }
            if occurrence.status != .scheduled {
                throw ValidationError(field: "occurrenceId", message: "예정 상태인 레슨만 마무리할 수 있습니다.")
            }
            let occurrenceDate = DateOnly.string(
                fromISOInstant: occurrence.startsAt,
                timeZoneIdentifier: occurrence.timezone
            )
            guard input.lessonDate == occurrenceDate else {
                throw ValidationError(field: "lessonDate", message: "선택한 레슨 날짜와 마무리 기록 날짜가 일치하지 않습니다.")
            }
            let occurrenceTimeZone = TimeZone(identifier: occurrence.timezone) ?? .current
            let today = DateOnly.string(from: currentDate(), timeZone: occurrenceTimeZone)
            guard occurrenceDate <= today else {
                throw ValidationError(field: "occurrenceId", message: "미래 레슨은 당일이 된 뒤 마무리할 수 있습니다.")
            }

            let timestamp = nowString()
            snapshot.notes.append(LessonNote(
                id: UUID(),
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                lessonDate: input.lessonDate,
                coveredMaterial: input.coveredMaterial,
                observations: input.observations,
                practiceAssigned: input.practiceAssigned,
                nextStepHint: input.nextStepHint,
                createdAt: timestamp
            ))

            let planId = input.nextPlanId ?? UUID()
            snapshot.plans.removeAll { $0.id == planId }
            snapshot.plans.append(NextLessonPlan(
                id: planId,
                instructorId: snapshot.instructor.id,
                studentId: input.studentId,
                plannedFor: input.plannedFor,
                priority: input.priority,
                nextAction: input.nextAction,
                detail: input.nextPlanDetail ?? input.nextStepHint,
                createdAt: existingPlan?.createdAt ?? timestamp,
                updatedAt: timestamp
            ))

            if let title = input.assignmentTitle,
               let status = input.assignmentStatus,
               let detail = input.assignmentDetail {
                let assignmentId = input.assignmentId ?? UUID()
                snapshot.assignments.removeAll { $0.id == assignmentId }
                snapshot.assignments.append(Assignment(
                    id: assignmentId,
                    instructorId: snapshot.instructor.id,
                    studentId: input.studentId,
                    title: title,
                    status: status,
                    dueDate: input.assignmentDueDate,
                    detail: detail,
                    updatedAt: timestamp
                ))
            }

            if let progressItemId = input.progressItemId,
               let progressStatus = input.progressStatus,
               let index = snapshot.progressItems.firstIndex(where: { $0.id == progressItemId }) {
                if input.progressCurrentFocus {
                    for itemIndex in snapshot.progressItems.indices where snapshot.progressItems[itemIndex].studentId == input.studentId {
                        snapshot.progressItems[itemIndex].currentFocus = false
                    }
                    snapshot.progressItems[index].currentFocus = true
                }
                snapshot.progressItems[index].status = progressStatus
                snapshot.progressItems[index].updatedAt = timestamp
            }

            if let occurrenceId = input.occurrenceId,
               let index = snapshot.occurrences.firstIndex(where: { $0.id == occurrenceId }) {
                snapshot.occurrences[index].status = .completed
                try advanceTuitionCycle(for: input.studentId, in: &snapshot, timestamp: timestamp)
                snapshot.lessonDrafts.removeAll { $0.occurrenceId == occurrenceId }
            }
        }
    }

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        try ScheduleValidation.validate(input)
        return try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            let occurrence = input.makeOccurrence(instructorId: snapshot.instructor.id)
            snapshot.occurrences.append(occurrence)
            return occurrence
        }
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        try ScheduleValidation.validate(input)
        return try mutateSnapshot { snapshot in
            try requireStudent(input.studentId, in: snapshot)
            let template = input.template(instructorId: snapshot.instructor.id)
            let expanded = WeeklyOccurrenceExpander.expand(
                template: template,
                horizonStartDate: input.startsOn,
                existingOccurrenceKeys: occurrenceKeys(for: template, in: snapshot.occurrences)
            )
            guard !expanded.isEmpty else {
                throw ValidationError(field: "endsOn", message: "선택한 반복 범위에 생성되는 레슨이 없습니다.")
            }
            snapshot.templates.append(template)
            snapshot.occurrences.append(contentsOf: expanded)
            return expanded
        }
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        try ScheduleValidation.validate(input)
        return try mutateSnapshot { snapshot in
            guard let index = snapshot.occurrences.firstIndex(where: { $0.id == input.occurrenceId }) else {
                throw RepositoryError.notFound
            }
            guard snapshot.occurrences[index].status == .scheduled else {
                throw ValidationError(field: "occurrenceId", message: "예정 상태인 레슨만 수정할 수 있습니다.")
            }
            snapshot.occurrences[index].startsAt = input.startsAt
            snapshot.occurrences[index].endsAt = input.endsAt
            snapshot.occurrences[index].timezone = input.timezone
            snapshot.occurrences[index].nativeCalendarSyncStatus = .pending
            snapshot.occurrences[index].nativeCalendarSyncError = nil
            return snapshot.occurrences[index]
        }
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        try mutateSnapshot { snapshot in
            guard let index = snapshot.occurrences.firstIndex(where: { $0.id == id }) else {
                throw RepositoryError.notFound
            }
            guard snapshot.occurrences[index].status == .scheduled else {
                throw ValidationError(field: "occurrenceId", message: "예정 상태인 레슨만 취소할 수 있습니다.")
            }
            snapshot.occurrences[index].status = .canceled
            snapshot.occurrences[index].nativeCalendarSyncStatus = .pending
            snapshot.occurrences[index].nativeCalendarSyncError = nil
            snapshot.lessonDrafts.removeAll { $0.occurrenceId == id }
            return snapshot.occurrences[index]
        }
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {
        try mutateSnapshot { snapshot in
            guard let index = snapshot.occurrences.firstIndex(where: { $0.id == occurrenceId }) else {
                throw RepositoryError.notFound
            }
            snapshot.occurrences[index].nativeCalendarSyncStatus = .pending
            snapshot.occurrences[index].nativeCalendarSyncError = nil
        }
    }

    func loadOccurrence(id: EntityID) async throws -> LessonOccurrence {
        try refreshSnapshot()
        guard let occurrence = snapshot.occurrences.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return occurrence
    }

    func loadPendingNativeCalendarOccurrences() async throws -> [LessonOccurrence] {
        try refreshSnapshot()
        return snapshot.occurrences
            .filter { $0.nativeCalendarSyncStatus == .pending }
            .sorted { $0.startsAt < $1.startsAt }
    }

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        try mutateSnapshot { snapshot in
            guard let index = snapshot.occurrences.firstIndex(where: { $0.id == input.occurrenceId }) else {
                throw RepositoryError.notFound
            }
            snapshot.occurrences[index].nativeCalendarEventIdentifier = input.eventIdentifier
            snapshot.occurrences[index].nativeCalendarIdentifier = input.calendarIdentifier
            snapshot.occurrences[index].nativeCalendarExternalIdentifier = input.externalIdentifier
            snapshot.occurrences[index].nativeCalendarSyncStatus = input.status
            snapshot.occurrences[index].nativeCalendarSyncError = input.error
            snapshot.occurrences[index].nativeCalendarSyncedAt = input.syncedAt
        }
    }

    func configureTuitionCycle(
        studentId: EntityID,
        completedLessonCount: Int,
        paymentConfirmedOn: String?
    ) async throws -> EntityID {
        try TuitionValidation.validate(
            completedLessonCount: completedLessonCount,
            paymentConfirmedOn: paymentConfirmedOn
        )
        let id = UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(studentId, in: snapshot)
            guard !snapshot.tuitionCycles.contains(where: { $0.studentId == studentId }) else {
                throw ValidationError(field: "studentId", message: "이미 수강비 관리가 시작된 학생입니다.")
            }
            let timestamp = nowString()
            snapshot.tuitionCycles.append(TuitionCycle(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: studentId,
                sequence: 1,
                targetLessonCount: TuitionValidation.targetLessonCount,
                completedLessonCount: completedLessonCount,
                paymentConfirmedOn: paymentConfirmedOn,
                createdAt: timestamp,
                updatedAt: timestamp
            ))
        }
        return id
    }

    func updateTuitionCycleProgress(
        cycleId: EntityID,
        studentId: EntityID,
        completedLessonCount: Int
    ) async throws {
        try TuitionValidation.validateCompletedLessonCount(completedLessonCount)
        try mutateSnapshot { snapshot in
            try requireStudent(studentId, in: snapshot)
            guard let cycle = try relatedRecord(
                id: cycleId,
                studentId: studentId,
                records: snapshot.tuitionCycles,
                recordID: \.id,
                ownerID: \.studentId
            ), let index = snapshot.tuitionCycles.firstIndex(where: { $0.id == cycle.id }) else {
                throw RepositoryError.notFound
            }
            let latestCycleId = snapshot.tuitionCycles
                .filter { $0.studentId == studentId }
                .max { $0.sequence < $1.sequence }?
                .id
            guard latestCycleId == cycleId else {
                throw ValidationError(field: "cycleId", message: "현재 수강 주기의 회차만 수정할 수 있습니다.")
            }
            snapshot.tuitionCycles[index].completedLessonCount = completedLessonCount
            snapshot.tuitionCycles[index].updatedAt = nowString()
        }
    }

    func setTuitionPaymentConfirmation(
        cycleId: EntityID,
        studentId: EntityID,
        confirmedOn: String?
    ) async throws {
        try TuitionValidation.validatePaymentConfirmedOn(confirmedOn)
        try mutateSnapshot { snapshot in
            try requireStudent(studentId, in: snapshot)
            guard let cycle = try relatedRecord(
                id: cycleId,
                studentId: studentId,
                records: snapshot.tuitionCycles,
                recordID: \.id,
                ownerID: \.studentId
            ), let index = snapshot.tuitionCycles.firstIndex(where: { $0.id == cycle.id }) else {
                throw RepositoryError.notFound
            }
            snapshot.tuitionCycles[index].paymentConfirmedOn = confirmedOn
            snapshot.tuitionCycles[index].updatedAt = nowString()
        }
    }

    func startNextTuitionCycle(
        studentId: EntityID,
        currentCycleId: EntityID,
        paymentConfirmedOn: String?
    ) async throws -> EntityID {
        try TuitionValidation.validatePaymentConfirmedOn(paymentConfirmedOn)
        let id = UUID()
        try mutateSnapshot { snapshot in
            try requireStudent(studentId, in: snapshot)
            guard let current = try relatedRecord(
                id: currentCycleId,
                studentId: studentId,
                records: snapshot.tuitionCycles,
                recordID: \.id,
                ownerID: \.studentId
            ) else {
                throw RepositoryError.notFound
            }
            let latest = snapshot.tuitionCycles
                .filter { $0.studentId == studentId }
                .max { $0.sequence < $1.sequence }
            guard latest?.id == currentCycleId else {
                throw ValidationError(field: "currentCycleId", message: "가장 최근 수강 주기에서만 다음 4회를 시작할 수 있습니다.")
            }
            guard current.isComplete else {
                throw ValidationError(field: "completedLessonCount", message: "현재 4회를 모두 마친 뒤 다음 4회를 시작하세요.")
            }

            let timestamp = nowString()
            snapshot.tuitionCycles.append(TuitionCycle(
                id: id,
                instructorId: snapshot.instructor.id,
                studentId: studentId,
                sequence: current.sequence + 1,
                targetLessonCount: TuitionValidation.targetLessonCount,
                completedLessonCount: 0,
                paymentConfirmedOn: paymentConfirmedOn,
                createdAt: timestamp,
                updatedAt: timestamp
            ))
        }
        return id
    }

    func makeBackupData() async throws -> Data {
        try refreshSnapshot()
        return try encodeBackup(snapshot)
    }

    func restoreBackup(from data: Data) async throws -> URL {
        let payload: LocalDataBackupPayload
        do {
            payload = try JSONDecoder().decode(LocalDataBackupPayload.self, from: data)
        } catch {
            throw RepositoryError(message: "Drum Lesson OS 백업 파일을 읽을 수 없습니다.")
        }
        guard LocalDataBackupPayload.supportedFormatVersions.contains(payload.formatVersion) else {
            throw RepositoryError(message: "지원하지 않는 백업 버전입니다.")
        }
        try validateBackupSnapshot(payload.snapshot)

        let latest = try loadLatestSnapshot()
        let safetyBackupURL = try writeSafetyBackup(for: latest)
        var restored = payload.snapshot
        for index in restored.occurrences.indices where restored.occurrences[index].nativeCalendarSyncStatus == .pending {
            restored.occurrences[index].nativeCalendarSyncStatus = .failed
            restored.occurrences[index].nativeCalendarSyncError = "백업에서 복원되었습니다. Apple 캘린더 동기화를 수동으로 재시도하세요."
        }

        try store.withImmediateTransaction {
            try store.saveData(JSONEncoder().encode(restored), forKey: Self.snapshotKey)
        }
        snapshot = restored
        return safetyBackupURL
    }

    func loadOccurrencesForDataReset() async throws -> [LessonOccurrence] {
        try refreshSnapshot()
        return snapshot.occurrences
    }

    func markCalendarEventDeletedForDataReset(occurrenceId: EntityID) async throws {
        try await updateNativeCalendarSync(.deleted(occurrenceId: occurrenceId))
    }

    func resetLocalData() async throws {
        try mutateSnapshot { snapshot in
            snapshot.students = []
            snapshot.progressItems = []
            snapshot.progressCheckpoints = []
            snapshot.traits = []
            snapshot.assignments = []
            snapshot.notes = []
            snapshot.plans = []
            snapshot.templates = []
            snapshot.occurrences = []
            snapshot.tuitionCycles = []
            snapshot.lessonDrafts = []
        }
    }

    private func mapRoster(_ snapshot: LocalAppSnapshot) -> [StudentRosterItem] {
        StudentRosterMapper.map(
            students: snapshot.students,
            progressItems: snapshot.progressItems,
            assignments: snapshot.assignments,
            nextPlans: snapshot.plans,
            notes: snapshot.notes,
            todayDate: DateOnly.today(in: .current)
        )
    }

    private func advanceTuitionCycle(
        for studentId: EntityID,
        in snapshot: inout LocalAppSnapshot,
        timestamp: String
    ) throws {
        guard let currentIndex = snapshot.tuitionCycles.indices
            .filter({ snapshot.tuitionCycles[$0].studentId == studentId })
            .max(by: { snapshot.tuitionCycles[$0].sequence < snapshot.tuitionCycles[$1].sequence }) else {
            return
        }

        let current = snapshot.tuitionCycles[currentIndex]
        try TuitionValidation.validate(current)
        if current.isComplete {
            snapshot.tuitionCycles.append(TuitionCycle(
                id: UUID(),
                instructorId: snapshot.instructor.id,
                studentId: studentId,
                sequence: current.sequence + 1,
                targetLessonCount: TuitionValidation.targetLessonCount,
                completedLessonCount: 1,
                paymentConfirmedOn: nil,
                createdAt: timestamp,
                updatedAt: timestamp
            ))
        } else {
            snapshot.tuitionCycles[currentIndex].completedLessonCount += 1
            snapshot.tuitionCycles[currentIndex].updatedAt = timestamp
        }
    }

    private func refreshSnapshot() throws {
        snapshot = try loadLatestSnapshot()
    }

    private func encodeBackup(_ snapshot: LocalAppSnapshot) throws -> Data {
        let payload = LocalDataBackupPayload(
            formatVersion: LocalDataBackupPayload.currentFormatVersion,
            createdAt: nowString(),
            snapshot: snapshot
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    private func writeSafetyBackup(for snapshot: LocalAppSnapshot) throws -> URL {
        let directory = databaseURL.deletingLastPathComponent().appendingPathComponent("Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let suffix = UUID().uuidString.prefix(8)
        let url = directory.appendingPathComponent("Before-Restore-\(formatter.string(from: Date()))-\(suffix).drumlessonbackup")
        try encodeBackup(snapshot).write(to: url, options: .atomic)
        return url
    }

    private func validateBackupSnapshot(_ candidate: LocalAppSnapshot) throws {
        let studentIDs = Set(candidate.students.map(\.id))
        let progressByID = Dictionary(candidate.progressItems.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let tuitionSequenceKeys = Set(candidate.tuitionCycles.map { "\($0.studentId.uuidString):\($0.sequence)" })
        let templateByID = Dictionary(candidate.templates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let occurrenceByID = Dictionary(candidate.occurrences.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        guard hasUniqueIDs(candidate.students),
              hasUniqueIDs(candidate.progressItems),
              hasUniqueIDs(candidate.progressCheckpoints),
              hasUniqueIDs(candidate.traits),
              hasUniqueIDs(candidate.assignments),
              hasUniqueIDs(candidate.notes),
              hasUniqueIDs(candidate.plans),
              hasUniqueIDs(candidate.templates),
              hasUniqueIDs(candidate.occurrences),
              hasUniqueIDs(candidate.tuitionCycles),
              hasUniqueIDs(candidate.lessonDrafts),
              tuitionSequenceKeys.count == candidate.tuitionCycles.count else {
            throw RepositoryError(message: "백업 파일에 중복된 기록 식별자가 있습니다.")
        }
        guard candidate.students.allSatisfy({ $0.instructorId == candidate.instructor.id }),
              candidate.progressItems.allSatisfy({ studentIDs.contains($0.studentId) && $0.instructorId == candidate.instructor.id }),
              candidate.traits.allSatisfy({ studentIDs.contains($0.studentId) && $0.instructorId == candidate.instructor.id }),
              candidate.assignments.allSatisfy({ studentIDs.contains($0.studentId) && $0.instructorId == candidate.instructor.id }),
              candidate.notes.allSatisfy({ studentIDs.contains($0.studentId) && $0.instructorId == candidate.instructor.id }),
              candidate.plans.allSatisfy({ studentIDs.contains($0.studentId) && $0.instructorId == candidate.instructor.id }),
              candidate.templates.allSatisfy({ studentIDs.contains($0.studentId) && $0.instructorId == candidate.instructor.id }),
              candidate.occurrences.allSatisfy({ occurrence in
                  guard studentIDs.contains(occurrence.studentId),
                        occurrence.instructorId == candidate.instructor.id else {
                      return false
                  }
                  guard let templateId = occurrence.scheduleTemplateId else { return true }
                  guard let template = templateByID[templateId] else { return false }
                  return template.studentId == occurrence.studentId &&
                      template.instructorId == occurrence.instructorId
              }),
              candidate.tuitionCycles.allSatisfy({ cycle in
                  studentIDs.contains(cycle.studentId) &&
                      cycle.instructorId == candidate.instructor.id &&
                      cycle.sequence > 0 &&
                      cycle.targetLessonCount == TuitionValidation.targetLessonCount &&
                      (0...cycle.targetLessonCount).contains(cycle.completedLessonCount) &&
                      isValidTuitionPaymentDate(cycle.paymentConfirmedOn)
              }),
              candidate.lessonDrafts.allSatisfy({ draft in
                  guard let occurrence = occurrenceByID[draft.occurrenceId] else { return false }
                  return occurrence.studentId == draft.studentId &&
                      occurrence.status == .scheduled &&
                      studentIDs.contains(draft.studentId)
              }),
              candidate.progressCheckpoints.allSatisfy({ checkpoint in
                  guard let item = progressByID[checkpoint.progressItemId] else { return false }
                  return checkpoint.studentId == item.studentId &&
                      studentIDs.contains(checkpoint.studentId) &&
                      checkpoint.instructorId == candidate.instructor.id
              }) else {
            throw RepositoryError(message: "백업 파일의 학생 연결 정보를 확인할 수 없습니다.")
        }
    }

    private func hasUniqueIDs<Record: Identifiable>(_ records: [Record]) -> Bool where Record.ID == EntityID {
        Set(records.map(\.id)).count == records.count
    }

    private func isValidTuitionPaymentDate(_ value: String?) -> Bool {
        guard let value else { return true }
        do {
            try TuitionValidation.validatePaymentConfirmedOn(value)
            return true
        } catch {
            return false
        }
    }

    private func loadLatestSnapshot() throws -> LocalAppSnapshot {
        guard let data = try store.loadData(forKey: Self.snapshotKey) else {
            return .seed
        }
        return try JSONDecoder().decode(LocalAppSnapshot.self, from: data)
    }

    @discardableResult
    private func mutateSnapshot<Result>(_ mutation: (inout LocalAppSnapshot) throws -> Result) throws -> Result {
        let outcome: (snapshot: LocalAppSnapshot, result: Result) = try store.withImmediateTransaction {
            let latest = try loadLatestSnapshot()
            var candidate = latest
            let result = try mutation(&candidate)
            if candidate != latest {
                try store.saveData(JSONEncoder().encode(candidate), forKey: Self.snapshotKey)
            }
            return (candidate, result)
        }
        snapshot = outcome.snapshot
        return outcome.result
    }

    private func expandRecurringSchedules(weekContaining date: Date) throws {
        try expandRecurringSchedules(from: date, horizonWeeks: 1)
    }

    private func expandRecurringSchedules(
        from date: Date,
        horizonWeeks: Int,
        studentId: EntityID? = nil
    ) throws {
        try mutateSnapshot { snapshot in
            for template in snapshot.templates where template.active && (studentId == nil || template.studentId == studentId) {
                let timeZone = TimeZone(identifier: template.timezone) ?? .current
                var calendar = Calendar.iso8601SeoulCompatible
                calendar.timeZone = timeZone
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
                let horizonStartDate = DateOnly.string(from: weekStart, timeZone: timeZone)
                let expanded = WeeklyOccurrenceExpander.expand(
                    template: template,
                    horizonStartDate: horizonStartDate,
                    horizonWeeks: horizonWeeks,
                    existingOccurrenceKeys: occurrenceKeys(for: template, in: snapshot.occurrences)
                )
                snapshot.occurrences.append(contentsOf: expanded)
            }
        }
    }

    private func occurrenceKeys(
        for template: LessonScheduleTemplate,
        in occurrences: [LessonOccurrence]
    ) -> Set<String> {
        Set(occurrences.compactMap { occurrence in
            guard occurrence.scheduleTemplateId == template.id else { return nil }
            let dateKey = occurrence.recurrenceSlotDate ?? DateOnly.string(
                fromISOInstant: occurrence.startsAt,
                timeZoneIdentifier: template.timezone
            )
            return WeeklyOccurrenceExpander.occurrenceKey(templateId: template.id, dateKey: dateKey)
        })
    }

    private func requireStudent(_ studentId: EntityID, in snapshot: LocalAppSnapshot) throws {
        guard snapshot.students.contains(where: { $0.id == studentId }) else {
            throw RepositoryError.notFound
        }
    }

    private func relatedRecord<Record>(
        id: EntityID?,
        studentId: EntityID,
        records: [Record],
        recordID: KeyPath<Record, EntityID>,
        ownerID: KeyPath<Record, EntityID>
    ) throws -> Record? {
        guard let id else { return nil }
        guard let record = records.first(where: { $0[keyPath: recordID] == id }) else {
            throw RepositoryError.notFound
        }
        guard record[keyPath: ownerID] == studentId else {
            throw RepositoryError(message: "선택한 기록이 해당 학생에게 속하지 않습니다.")
        }
        return record
    }

    private func nowString() -> String {
        ISO8601DateFormatter.plain.string(from: currentDate())
    }

    private static let snapshotKey = "app_snapshot"
}

private struct LocalAppSnapshot: Codable, Equatable {
    var instructor: Instructor
    var students: [Student]
    var progressItems: [ProgressItem]
    var progressCheckpoints: [ProgressCheckpoint]
    var traits: [StudentTrait]
    var assignments: [Assignment]
    var notes: [LessonNote]
    var plans: [NextLessonPlan]
    var templates: [LessonScheduleTemplate]
    var occurrences: [LessonOccurrence]
    var tuitionCycles: [TuitionCycle]
    var lessonDrafts: [LessonDraft]

    enum CodingKeys: String, CodingKey {
        case instructor
        case students
        case progressItems
        case progressCheckpoints
        case traits
        case assignments
        case notes
        case plans
        case templates
        case occurrences
        case tuitionCycles
        case lessonDrafts
    }

    init(
        instructor: Instructor,
        students: [Student],
        progressItems: [ProgressItem],
        progressCheckpoints: [ProgressCheckpoint],
        traits: [StudentTrait],
        assignments: [Assignment],
        notes: [LessonNote],
        plans: [NextLessonPlan],
        templates: [LessonScheduleTemplate],
        occurrences: [LessonOccurrence],
        tuitionCycles: [TuitionCycle],
        lessonDrafts: [LessonDraft]
    ) {
        self.instructor = instructor
        self.students = students
        self.progressItems = progressItems
        self.progressCheckpoints = progressCheckpoints
        self.traits = traits
        self.assignments = assignments
        self.notes = notes
        self.plans = plans
        self.templates = templates
        self.occurrences = occurrences
        self.tuitionCycles = tuitionCycles
        self.lessonDrafts = lessonDrafts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instructor = try container.decode(Instructor.self, forKey: .instructor)
        students = try container.decode([Student].self, forKey: .students)
        progressItems = try container.decode([ProgressItem].self, forKey: .progressItems)
        progressCheckpoints = try container.decodeIfPresent([ProgressCheckpoint].self, forKey: .progressCheckpoints) ?? []
        traits = try container.decode([StudentTrait].self, forKey: .traits)
        assignments = try container.decode([Assignment].self, forKey: .assignments)
        notes = try container.decode([LessonNote].self, forKey: .notes)
        plans = try container.decode([NextLessonPlan].self, forKey: .plans)
        var decodedOccurrences = try container.decode([LessonOccurrence].self, forKey: .occurrences)
        templates = try container.decodeIfPresent([LessonScheduleTemplate].self, forKey: .templates) ?? []

        let templateTimezones = Dictionary(
            templates.map { ($0.id, $0.timezone) },
            uniquingKeysWith: { first, _ in first }
        )
        for index in decodedOccurrences.indices where decodedOccurrences[index].recurrenceSlotDate == nil {
            guard let templateId = decodedOccurrences[index].scheduleTemplateId,
                  let timezone = templateTimezones[templateId] else { continue }
            decodedOccurrences[index].recurrenceSlotDate = DateOnly.string(
                fromISOInstant: decodedOccurrences[index].startsAt,
                timeZoneIdentifier: timezone
            )
        }
        occurrences = decodedOccurrences
        tuitionCycles = try container.decodeIfPresent([TuitionCycle].self, forKey: .tuitionCycles) ?? []
        lessonDrafts = try container.decodeIfPresent([LessonDraft].self, forKey: .lessonDrafts) ?? []
    }

    static let seed = LocalAppSnapshot(
        instructor: PreviewData.instructor,
        students: PreviewData.students,
        progressItems: PreviewData.progressItems,
        progressCheckpoints: PreviewData.progressCheckpoints,
        traits: PreviewData.traits,
        assignments: PreviewData.assignments,
        notes: PreviewData.notes,
        plans: PreviewData.nextPlans,
        templates: [],
        occurrences: PreviewData.occurrences,
        tuitionCycles: [],
        lessonDrafts: []
    )
}

private struct LocalDataBackupPayload: Codable {
    static let currentFormatVersion = 3
    static let supportedFormatVersions = 1...currentFormatVersion

    var formatVersion: Int
    var createdAt: String
    var snapshot: LocalAppSnapshot
}

private final class LocalSQLiteStore {
    private let databaseURL: URL
    private var database: OpaquePointer?

    init(databaseURL: URL) throws {
        self.databaseURL = databaseURL
        let directory = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(databaseURL.path, &database, flags, nil) == SQLITE_OK else {
            throw makeError("SQLite DB를 열 수 없습니다.")
        }
        try execute("PRAGMA busy_timeout = 5000")
        try execute("PRAGMA journal_mode = WAL")
        try execute("""
        CREATE TABLE IF NOT EXISTS snapshots (
            key TEXT PRIMARY KEY NOT NULL,
            value BLOB NOT NULL,
            updated_at TEXT NOT NULL
        )
        """)
    }

    deinit {
        sqlite3_close(database)
    }

    func withImmediateTransaction<Result>(_ operation: () throws -> Result) throws -> Result {
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            let result = try operation()
            try execute("COMMIT TRANSACTION")
            return result
        } catch {
            try? execute("ROLLBACK TRANSACTION")
            throw error
        }
    }

    func loadData(forKey key: String) throws -> Data? {
        let statement = try prepare("SELECT value FROM snapshots WHERE key = ? LIMIT 1")
        defer { sqlite3_finalize(statement) }

        try bindText(key, at: 1, in: statement)
        let status = sqlite3_step(statement)
        if status == SQLITE_DONE {
            return nil
        }
        guard status == SQLITE_ROW else {
            throw makeError("SQLite 값을 읽을 수 없습니다.")
        }
        guard let bytes = sqlite3_column_blob(statement, 0) else {
            return Data()
        }
        let count = sqlite3_column_bytes(statement, 0)
        return Data(bytes: bytes, count: Int(count))
    }

    func saveData(_ data: Data, forKey key: String) throws {
        let statement = try prepare("""
        INSERT INTO snapshots (key, value, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(key) DO UPDATE SET
            value = excluded.value,
            updated_at = excluded.updated_at
        """)
        defer { sqlite3_finalize(statement) }

        try bindText(key, at: 1, in: statement)
        try bindBlob(data, at: 2, in: statement)
        try bindText(ISO8601DateFormatter.plain.string(from: Date()), at: 3, in: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw makeError("SQLite 값을 저장할 수 없습니다.")
        }
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(database, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? "알 수 없는 SQLite 오류"
            sqlite3_free(errorMessage)
            throw RepositoryError(message: message)
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("SQLite 쿼리를 준비할 수 없습니다.")
        }
        return statement
    }

    private func bindText(_ value: String, at index: Int32, in statement: OpaquePointer?) throws {
        let status = value.withCString {
            sqlite3_bind_text(statement, index, $0, -1, sqliteTransient)
        }
        guard status == SQLITE_OK else {
            throw makeError("SQLite 텍스트 값을 바인딩할 수 없습니다.")
        }
    }

    private func bindBlob(_ data: Data, at index: Int32, in statement: OpaquePointer?) throws {
        let status = data.withUnsafeBytes {
            sqlite3_bind_blob(statement, index, $0.baseAddress, Int32(data.count), sqliteTransient)
        }
        guard status == SQLITE_OK else {
            throw makeError("SQLite 데이터를 바인딩할 수 없습니다.")
        }
    }

    private func makeError(_ fallback: String) -> RepositoryError {
        if let database {
            let message = sqlite3_errmsg(database).map { String(cString: $0) } ?? fallback
            return RepositoryError(message: message)
        }
        return RepositoryError(message: "\(fallback) \(databaseURL.path)")
    }

    private var sqliteTransient: sqlite3_destructor_type {
        unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    }
}
