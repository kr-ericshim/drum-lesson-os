import Foundation

@MainActor
final class SupabaseScheduleRepository: ScheduleRepository {
    private let rpc: SupabaseRPCClient
    private let rest: SupabaseRESTClient
    private let sessionStore: SupabaseSessionStoring

    init(rpc: SupabaseRPCClient, rest: SupabaseRESTClient, sessionStore: SupabaseSessionStoring) {
        self.rpc = rpc
        self.rest = rest
        self.sessionStore = sessionStore
    }

    func createOneOffOccurrence(_ input: ScheduleLessonInput) async throws -> LessonOccurrence {
        try ScheduleValidation.validate(input)
        let result = try await rpc.executeMutation(
            name: "native_create_one_off_occurrence",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_starts_at": .string(input.startsAt),
                "p_ends_at": .string(input.endsAt),
                "p_timezone": .string(input.timezone),
                "p_title": .string(input.title),
                "p_native_calendar_sync_status": .string(NativeCalendarSyncStatus.pending.rawValue)
            ]
        )
        return try await fetchOccurrence(id: result.id)
    }

    func createWeeklySchedule(_ input: WeeklyScheduleInput) async throws -> [LessonOccurrence] {
        try ScheduleValidation.validate(input)
        let instructor = try await loadCurrentInstructor()
        let templateResult = try await rpc.executeMutation(
            name: "native_create_weekly_schedule_template",
            payload: [
                "p_student_id": .uuid(input.studentId),
                "p_title": .string(input.title),
                "p_default_duration_minutes": .int(input.defaultDurationMinutes),
                "p_timezone": .string(input.timezone),
                "p_starts_on": .string(input.startsOn),
                "p_start_time": .string(input.startTime),
                "p_ends_on": .optionalString(input.endsOn),
                "p_recurrence_interval": .int(input.recurrenceInterval),
                "p_recurrence_weekday": .int(input.recurrenceWeekday)
            ]
        )
        let template = LessonScheduleTemplate(
            id: templateResult.id,
            instructorId: instructor.id,
            studentId: input.studentId,
            title: input.title,
            defaultDurationMinutes: input.defaultDurationMinutes,
            timezone: input.timezone,
            recurrenceKind: "weekly",
            recurrenceInterval: input.recurrenceInterval,
            recurrenceWeekday: input.recurrenceWeekday,
            startsOn: input.startsOn,
            endsOn: input.endsOn,
            startTime: input.startTime,
            active: true
        )
        let expanded = WeeklyOccurrenceExpander.expand(
            template: template,
            horizonStartDate: input.startsOn,
            existingDateKeys: []
        )
        guard !expanded.isEmpty else {
            return []
        }

        _ = try await rpc.execute(
            name: "native_insert_expanded_occurrences",
            payload: [
                "p_occurrences": .array(expanded.map(Self.payload(for:)))
            ]
        ) as [SupabaseMutationResult]
        return try await fetchOccurrences(templateId: templateResult.id)
    }

    func editOccurrence(_ input: EditOccurrenceInput) async throws -> LessonOccurrence {
        let result = try await rpc.executeMutation(
            name: "native_edit_occurrence_time",
            payload: [
                "p_occurrence_id": .uuid(input.occurrenceId),
                "p_starts_at": .string(input.startsAt),
                "p_ends_at": .string(input.endsAt),
                "p_timezone": .string(input.timezone),
                "p_native_calendar_sync_status": .string(NativeCalendarSyncStatus.pending.rawValue)
            ]
        )
        return try await fetchOccurrence(id: result.id)
    }

    func cancelOccurrence(id: EntityID) async throws -> LessonOccurrence {
        let result = try await rpc.executeMutation(
            name: "native_cancel_occurrence",
            payload: [
                "p_occurrence_id": .uuid(id),
                "p_native_calendar_sync_status": .string(NativeCalendarSyncStatus.pending.rawValue),
                "p_native_calendar_sync_error": .null
            ]
        )
        return try await fetchOccurrence(id: result.id)
    }

    func retryNativeCalendarSync(occurrenceId: EntityID) async throws {
        try await updateNativeCalendarSync(NativeCalendarSyncUpdateInput(
            occurrenceId: occurrenceId,
            status: .pending,
            eventIdentifier: nil,
            calendarIdentifier: nil,
            externalIdentifier: nil,
            error: nil,
            syncedAt: nil
        ))
    }

    func updateNativeCalendarSync(_ input: NativeCalendarSyncUpdateInput) async throws {
        _ = try await rpc.executeMutation(
            name: "native_update_occurrence_calendar_sync",
            payload: [
                "p_occurrence_id": .uuid(input.occurrenceId),
                "p_native_calendar_sync_status": .string(input.status.rawValue),
                "p_native_calendar_event_identifier": .optionalString(input.eventIdentifier),
                "p_native_calendar_identifier": .optionalString(input.calendarIdentifier),
                "p_native_calendar_external_identifier": .optionalString(input.externalIdentifier),
                "p_native_calendar_sync_error": .optionalString(input.error),
                "p_native_calendar_synced_at": .optionalString(input.syncedAt)
            ]
        )
    }

    private func fetchOccurrence(id: EntityID) async throws -> LessonOccurrence {
        let rows: [LessonOccurrence] = try await select(
            table: "lesson_occurrences",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(id.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        guard let occurrence = rows.first else {
            throw RepositoryError.notFound
        }
        return occurrence
    }

    private func fetchOccurrences(templateId: EntityID) async throws -> [LessonOccurrence] {
        try await select(
            table: "lesson_occurrences",
            queryItems: [
                URLQueryItem(name: "schedule_template_id", value: "eq.\(templateId.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "starts_at.asc")
            ]
        )
    }

    private func loadCurrentInstructor() async throws -> Instructor {
        let rows: [Instructor] = try await select(
            table: "instructors",
            queryItems: [URLQueryItem(name: "limit", value: "1")]
        )
        guard let instructor = rows.first else {
            throw RepositoryError(message: "Instructor profile was not found for this Supabase account.")
        }
        return instructor
    }

    private func select<T: Decodable>(table: String, queryItems: [URLQueryItem]) async throws -> [T] {
        guard let session = try sessionStore.loadSession() else {
            throw RepositoryError.signedOut
        }
        return try await rest.select([T].self, table: table, queryItems: queryItems, accessToken: session.accessToken)
    }

    private static func payload(for occurrence: LessonOccurrence) -> JSONValue {
        .object([
            "student_id": .uuid(occurrence.studentId),
            "schedule_template_id": .optionalUUID(occurrence.scheduleTemplateId),
            "starts_at": .string(occurrence.startsAt),
            "ends_at": .string(occurrence.endsAt),
            "timezone": .string(occurrence.timezone),
            "status": .string(occurrence.status.rawValue),
            "title": .string(occurrence.title),
            "native_calendar_sync_status": .string(occurrence.nativeCalendarSyncStatus.rawValue)
        ])
    }
}
