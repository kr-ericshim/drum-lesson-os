import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var instructor: Instructor?
    var isLoading = false
    var errorMessage: String?

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    var isAuthenticated: Bool {
        instructor != nil
    }

    func restoreSession() async {
        do {
            instructor = try await repository.restoreSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        do {
            instructor = try await repository.signIn(email: email, password: password)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await repository.signOut()
            instructor = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recoverPassword() async {
        do {
            try await repository.openPasswordRecovery(email: email)
            errorMessage = "Password recovery opened in your browser."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
