import Foundation
import SQLite3

@MainActor
final class LocalSQLiteRepository: StudentRepository, StudentWriteRepository, ScheduleRepository {
    private let store: LocalSQLiteStore
    private var snapshot: LocalAppSnapshot

    convenience init() throws {
        try self.init(databaseURL: Self.defaultDatabaseURL())
    }

    init(databaseURL: URL) throws {
        let openedStore = try LocalSQLiteStore(databaseURL: databaseURL)
        store = openedStore
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

    func loadStudentDetail(studentId: EntityID) async throws -> StudentDetail {
        try refreshSnapshot()
        guard let student = snapshot.students.first(where: { $0.id == studentId }) else {
            throw RepositoryError.notFound
        }

        return StudentDetailMapper.map(
            student: student,
            progressItems: snapshot.progressItems.filter { $0.studentId == studentId },
            traits: snapshot.traits.filter { $0.studentId == studentId },
            assignments: snapshot.assignments.filter { $0.studentId == studentId },
            notes: snapshot.notes.filter { $0.studentId == studentId },
            nextPlans: snapshot.plans.filter { $0.studentId == studentId },
            todayDate: DateOnly.today(in: .current)
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

    private func refreshSnapshot() throws {
        snapshot = try loadLatestSnapshot()
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
        try mutateSnapshot { snapshot in
            for template in snapshot.templates where template.active {
                let timeZone = TimeZone(identifier: template.timezone) ?? .current
                var calendar = Calendar.iso8601SeoulCompatible
                calendar.timeZone = timeZone
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
                let horizonStartDate = DateOnly.string(from: weekStart, timeZone: timeZone)
                let expanded = WeeklyOccurrenceExpander.expand(
                    template: template,
                    horizonStartDate: horizonStartDate,
                    horizonWeeks: 1,
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
        ISO8601DateFormatter.plain.string(from: Date())
    }

    private static let snapshotKey = "app_snapshot"
}

private struct LocalAppSnapshot: Codable, Equatable {
    var instructor: Instructor
    var students: [Student]
    var progressItems: [ProgressItem]
    var traits: [StudentTrait]
    var assignments: [Assignment]
    var notes: [LessonNote]
    var plans: [NextLessonPlan]
    var templates: [LessonScheduleTemplate]
    var occurrences: [LessonOccurrence]

    enum CodingKeys: String, CodingKey {
        case instructor
        case students
        case progressItems
        case traits
        case assignments
        case notes
        case plans
        case templates
        case occurrences
    }

    init(
        instructor: Instructor,
        students: [Student],
        progressItems: [ProgressItem],
        traits: [StudentTrait],
        assignments: [Assignment],
        notes: [LessonNote],
        plans: [NextLessonPlan],
        templates: [LessonScheduleTemplate],
        occurrences: [LessonOccurrence]
    ) {
        self.instructor = instructor
        self.students = students
        self.progressItems = progressItems
        self.traits = traits
        self.assignments = assignments
        self.notes = notes
        self.plans = plans
        self.templates = templates
        self.occurrences = occurrences
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instructor = try container.decode(Instructor.self, forKey: .instructor)
        students = try container.decode([Student].self, forKey: .students)
        progressItems = try container.decode([ProgressItem].self, forKey: .progressItems)
        traits = try container.decode([StudentTrait].self, forKey: .traits)
        assignments = try container.decode([Assignment].self, forKey: .assignments)
        notes = try container.decode([LessonNote].self, forKey: .notes)
        plans = try container.decode([NextLessonPlan].self, forKey: .plans)
        var decodedOccurrences = try container.decode([LessonOccurrence].self, forKey: .occurrences)
        templates = try container.decodeIfPresent([LessonScheduleTemplate].self, forKey: .templates) ?? []

        let templateTimezones = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0.timezone) })
        for index in decodedOccurrences.indices where decodedOccurrences[index].recurrenceSlotDate == nil {
            guard let templateId = decodedOccurrences[index].scheduleTemplateId,
                  let timezone = templateTimezones[templateId] else { continue }
            decodedOccurrences[index].recurrenceSlotDate = DateOnly.string(
                fromISOInstant: decodedOccurrences[index].startsAt,
                timeZoneIdentifier: timezone
            )
        }
        occurrences = decodedOccurrences
    }

    static let seed = LocalAppSnapshot(
        instructor: PreviewData.instructor,
        students: PreviewData.students,
        progressItems: PreviewData.progressItems,
        traits: PreviewData.traits,
        assignments: PreviewData.assignments,
        notes: PreviewData.notes,
        plans: PreviewData.nextPlans,
        templates: [],
        occurrences: PreviewData.occurrences
    )
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
