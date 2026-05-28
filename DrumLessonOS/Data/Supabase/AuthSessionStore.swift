import Foundation
import Security

struct SupabaseStoredSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var tokenType: String
    var userId: EntityID

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case userId = "user_id"
    }
}

@MainActor
protocol SupabaseSessionStoring: AnyObject {
    func save(_ session: SupabaseStoredSession) throws
    func loadSession() throws -> SupabaseStoredSession?
    func delete() throws
}

final class AuthSessionStore: SupabaseSessionStoring {
    private let service = "DrumLessonOS.SupabaseSession"
    private let account = "current"

    func save(_ session: SupabaseStoredSession) throws {
        let data = try JSONEncoder().encode(session)
        try delete()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw RepositoryError(message: "Keychain save failed with status \(status).")
        }
    }

    func loadSession() throws -> SupabaseStoredSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw RepositoryError(message: "Keychain load failed with status \(status).")
        }
        return try JSONDecoder().decode(SupabaseStoredSession.self, from: data)
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw RepositoryError(message: "Keychain delete failed with status \(status).")
        }
    }
}
