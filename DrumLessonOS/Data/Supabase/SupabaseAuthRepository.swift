import Foundation

@MainActor
final class SupabaseAuthRepository: AuthRepository {
    private let rest: SupabaseRESTClient
    private let sessionStore: SupabaseSessionStoring

    init(rest: SupabaseRESTClient, sessionStore: SupabaseSessionStoring = AuthSessionStore()) {
        self.rest = rest
        self.sessionStore = sessionStore
    }

    func restoreSession() async throws -> Instructor? {
        guard let session = try sessionStore.loadSession() else {
            return nil
        }

        do {
            let refreshed = try await rest.refreshSession(refreshToken: session.refreshToken)
            try sessionStore.save(refreshed)
            return try await fetchInstructor(accessToken: refreshed.accessToken)
        } catch {
            try? sessionStore.delete()
            return nil
        }
    }

    func signIn(email: String, password: String) async throws -> Instructor {
        guard email.contains("@"), !password.isEmpty else {
            throw RepositoryError(message: "Email and password are required.")
        }

        let session = try await rest.signIn(email: email, password: password)
        try sessionStore.save(session)
        return try await fetchInstructor(accessToken: session.accessToken)
    }

    func signOut() async throws {
        let session = try sessionStore.loadSession()
        try sessionStore.delete()
        if let accessToken = session?.accessToken {
            try? await rest.signOut(accessToken: accessToken)
        }
    }

    func openPasswordRecovery(email: String) async throws {
        guard email.contains("@") else {
            throw RepositoryError(message: "Enter your account email first.")
        }
        try await rest.recoverPassword(email: email)
    }

    private func fetchInstructor(accessToken: String) async throws -> Instructor {
        let instructors: [Instructor] = try await rest.select(
            [Instructor].self,
            table: "instructors",
            queryItems: [
                URLQueryItem(name: "limit", value: "1")
            ],
            accessToken: accessToken
        )

        guard let instructor = instructors.first else {
            throw RepositoryError(message: "Instructor profile was not found for this Supabase account.")
        }
        return instructor
    }
}
