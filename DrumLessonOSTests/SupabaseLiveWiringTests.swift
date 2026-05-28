import Foundation
import Testing
@testable import DrumLessonOS

@MainActor
@Test func loadsSupabaseConfigFromEnvironmentAndRejectsServiceRoleKeys() throws {
    let environment = try SupabaseEnvironment.load(
        environment: [
            "SUPABASE_URL": "https://example.supabase.co",
            "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test_key"
        ],
        bundle: nil
    )

    #expect(environment.url.absoluteString == "https://example.supabase.co")
    #expect(environment.publishableKey == "sb_publishable_test_key")

    #expect(throws: RepositoryError.self) {
        try SupabaseEnvironment.load(
            environment: [
                "SUPABASE_URL": "https://example.supabase.co",
                "SUPABASE_PUBLISHABLE_KEY": "sb_secret_service_role_key"
            ],
            bundle: nil
        )
    }
}

@MainActor
@Test func appEnvironmentFallsBackToPreviewWhenLiveConfigIsMissing() {
    let environment = AppEnvironment.liveOrPreview(environment: [:], bundle: nil)

    #expect(environment.students is PreviewRepository)
    #expect(environment.writes is PreviewRepository)
    #expect(environment.schedules is CalendarBackedScheduleRepository)
}

@MainActor
@Test func authSignInUsesPublishableKeyBearerTokenAndStoresRefreshableSession() async throws {
    let transport = RecordingSupabaseTransport(responses: [
        .json("""
        {
          "access_token": "access-token",
          "refresh_token": "refresh-token",
          "expires_in": 3600,
          "token_type": "bearer",
          "user": { "id": "dddddddd-dddd-dddd-dddd-dddddddddddd", "email": "eric@example.com" }
        }
        """),
        .json("""
        [{
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "display_name": "Eric Shim",
          "studio_name": "Drum Lesson OS",
          "auth_user_id": "dddddddd-dddd-dddd-dddd-dddddddddddd"
        }]
        """)
    ])
    let store = MemorySupabaseSessionStore()
    let repository = SupabaseAuthRepository(rest: liveRestClient(transport: transport), sessionStore: store)

    let instructor = try await repository.signIn(email: "eric@example.com", password: "secret")

    #expect(instructor.displayName == "Eric Shim")
    #expect(store.session?.accessToken == "access-token")
    #expect(store.session?.refreshToken == "refresh-token")
    #expect(transport.requests.count == 2)
    #expect(transport.requests[0].url?.path == "/auth/v1/token")
    #expect(transport.requests[0].url?.query == "grant_type=password")
    #expect(transport.requests[0].value(forHTTPHeaderField: "apikey") == "sb_publishable_test_key")
    #expect(transport.requests[1].value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
}

@MainActor
@Test func studentRepositoryReadsRestTablesIntoExistingReadModels() async throws {
    let transport = RecordingSupabaseTransport(responses: [
        .json("""
        [{
          "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          "instructor_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "name": "김민지",
          "profile_cue": "짧은 리듬 확인이 빠르다.",
          "primary_weak_point": "필인 뒤 1박 착지",
          "active": true,
          "created_at": "2026-05-28T00:00:00Z",
          "updated_at": "2026-05-28T00:00:00Z"
        }]
        """),
        .json("""
        [{
          "id": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
          "instructor_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "student_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          "category": "song",
          "status": "in_progress",
          "title": "좋은 밤 좋은 꿈 8비트",
          "current_focus": true,
          "observed_on": "2026-05-28",
          "detail": "코러스 전 필인에서 오른발이 앞선다.",
          "tempo_note": "82 BPM",
          "updated_at": "2026-05-28T00:00:00Z"
        }]
        """),
        .json("[]"),
        .json("[]"),
        .json("[]")
    ])
    let repository = SupabaseStudentRepository(rest: liveRestClient(transport: transport), sessionStore: authenticatedStore())

    let roster = try await repository.loadRoster()

    #expect(roster.count == 1)
    #expect(roster[0].name == "김민지")
    #expect(roster[0].currentFocus?.title == "좋은 밤 좋은 꿈 8비트")
    #expect(transport.requests.allSatisfy { $0.value(forHTTPHeaderField: "apikey") == "sb_publishable_test_key" })
    #expect(transport.requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer access-token" })
}

@MainActor
@Test func studentWritesCallNativeRPCAndDecodeReturnedIdentifier() async throws {
    let transport = RecordingSupabaseTransport(responses: [
        .json("""
        [{ "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "updated_at": "2026-05-28T00:00:00Z" }]
        """)
    ])
    let repository = SupabaseStudentWriteRepository(
        rpc: SupabaseRPCClient(rest: liveRestClient(transport: transport), sessionStore: authenticatedStore())
    )

    let id = try await repository.createStudent(StudentProfileInput(
        studentId: nil,
        name: "김민지",
        profileCue: "짧은 리듬 확인이 빠르다.",
        primaryWeakPoint: "필인 뒤 1박 착지",
        active: true
    ))

    #expect(id.uuidString.lowercased() == "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")
    #expect(transport.requests[0].url?.path == "/rest/v1/rpc/native_create_student")
    let body = String(decoding: transport.requests[0].httpBody ?? Data(), as: UTF8.self)
    #expect(body.contains("\"p_name\":\"김민지\""))
    #expect(body.contains("\"p_profile_cue\":\"짧은 리듬 확인이 빠르다.\""))
    #expect(!body.localizedCaseInsensitiveContains("service_role"))
}

@MainActor
@Test func scheduleRepositoryReturnsFreshOccurrenceAfterMutation() async throws {
    let occurrenceId = "99999999-9999-9999-9999-999999999999"
    let transport = RecordingSupabaseTransport(responses: [
        .json("[{ \"id\": \"\(occurrenceId)\", \"updated_at\": \"2026-05-28T00:00:00Z\" }]"),
        .json("""
        [{
          "id": "\(occurrenceId)",
          "instructor_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "student_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          "schedule_template_id": null,
          "starts_at": "2026-05-28T10:00:00Z",
          "ends_at": "2026-05-28T10:50:00Z",
          "timezone": "Asia/Seoul",
          "status": "scheduled",
          "title": "김민지 drum lesson",
          "native_calendar_event_identifier": null,
          "native_calendar_identifier": null,
          "native_calendar_external_identifier": null,
          "native_calendar_sync_status": "pending",
          "native_calendar_sync_error": null,
          "native_calendar_synced_at": null
        }]
        """)
    ])
    let repository = SupabaseScheduleRepository(
        rpc: SupabaseRPCClient(rest: liveRestClient(transport: transport), sessionStore: authenticatedStore()),
        rest: liveRestClient(transport: transport),
        sessionStore: authenticatedStore()
    )

    let occurrence = try await repository.createOneOffOccurrence(ScheduleLessonInput(
        studentId: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
        title: "김민지 drum lesson",
        startsAt: "2026-05-28T10:00:00Z",
        endsAt: "2026-05-28T10:50:00Z",
        timezone: "Asia/Seoul",
        durationMinutes: 50
    ))

    #expect(occurrence.id.uuidString.lowercased() == occurrenceId)
    #expect(transport.requests[0].url?.path == "/rest/v1/rpc/native_create_one_off_occurrence")
    #expect(transport.requests[1].url?.path == "/rest/v1/lesson_occurrences")
}

@MainActor
private func liveRestClient(transport: RecordingSupabaseTransport) -> SupabaseRESTClient {
    SupabaseRESTClient(
        environment: SupabaseEnvironment(
            url: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test_key"
        ),
        transport: transport
    )
}

@MainActor
private func authenticatedStore() -> MemorySupabaseSessionStore {
    let store = MemorySupabaseSessionStore()
    store.session = SupabaseStoredSession(
        accessToken: "access-token",
        refreshToken: "refresh-token",
        tokenType: "bearer",
        userId: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
    )
    return store
}

@MainActor
private final class MemorySupabaseSessionStore: SupabaseSessionStoring {
    var session: SupabaseStoredSession?

    func save(_ session: SupabaseStoredSession) throws {
        self.session = session
    }

    func loadSession() throws -> SupabaseStoredSession? {
        session
    }

    func delete() throws {
        session = nil
    }
}

@MainActor
private final class RecordingSupabaseTransport: SupabaseHTTPTransport {
    var requests: [URLRequest] = []
    private var responses: [RecordedHTTPResponse]

    init(responses: [RecordedHTTPResponse]) {
        self.responses = responses
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = responses.removeFirst()
        return (response.data, response.response)
    }
}

private struct RecordedHTTPResponse {
    var data: Data
    var response: HTTPURLResponse

    static func json(_ value: String, status: Int = 200) -> RecordedHTTPResponse {
        RecordedHTTPResponse(
            data: Data(value.utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://example.supabase.co")!,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
        )
    }
}
