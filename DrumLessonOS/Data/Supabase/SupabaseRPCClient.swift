import Foundation

struct NativeRPC: Equatable {
    var name: String
    var payload: [String: String]
}

@MainActor
final class SupabaseRPCClient {
    static let allowedRPCNames: Set<String> = [
        "native_create_student",
        "native_update_student_profile",
        "native_upsert_student_trait",
        "native_upsert_progress_item",
        "native_update_progress_status",
        "native_upsert_assignment",
        "native_create_lesson_note",
        "native_upsert_next_lesson_plan",
        "native_create_one_off_occurrence",
        "native_create_weekly_schedule_template",
        "native_insert_expanded_occurrences",
        "native_edit_occurrence_time",
        "native_cancel_occurrence",
        "native_update_occurrence_calendar_sync",
        "closeout_lesson"
    ]

    private let rest: SupabaseRESTClient?
    private let sessionStore: SupabaseSessionStoring?

    init(rest: SupabaseRESTClient? = nil, sessionStore: SupabaseSessionStoring? = nil) {
        self.rest = rest
        self.sessionStore = sessionStore
    }

    static func validate(name: String) throws {
        guard allowedRPCNames.contains(name) else {
            throw RepositoryError(message: "RPC \(name) is not part of the native write boundary.")
        }
    }

    func makeRequest(name: String, payload: [String: String]) throws -> NativeRPC {
        try Self.validate(name: name)
        return NativeRPC(name: name, payload: payload)
    }

    func executeMutation(name: String, payload: [String: JSONValue]) async throws -> SupabaseMutationResult {
        let rows: [SupabaseMutationResult] = try await execute(name: name, payload: payload)
        guard let row = rows.first else {
            throw RepositoryError(message: "Supabase RPC \(name) returned no rows.")
        }
        return row
    }

    func execute<T: Decodable>(name: String, payload: [String: JSONValue]) async throws -> T {
        guard let rest, let sessionStore else {
            throw RepositoryError(message: "Live Supabase RPC client is missing its REST transport.")
        }
        guard let session = try sessionStore.loadSession() else {
            throw RepositoryError.signedOut
        }
        return try await rest.rpc(T.self, name: name, payload: payload, accessToken: session.accessToken)
    }

    func executeVoid(name: String, payload: [String: JSONValue]) async throws {
        guard let rest, let sessionStore else {
            throw RepositoryError(message: "Live Supabase RPC client is missing its REST transport.")
        }
        guard let session = try sessionStore.loadSession() else {
            throw RepositoryError.signedOut
        }
        try await rest.rpcVoid(name: name, payload: payload, accessToken: session.accessToken)
    }
}
