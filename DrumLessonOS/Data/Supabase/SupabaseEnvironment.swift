import Foundation

struct SupabaseEnvironment: Equatable {
    var url: URL
    var publishableKey: String

    init(url: URL, publishableKey: String) {
        self.url = url
        self.publishableKey = publishableKey
    }

    static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle? = .main
    ) throws -> SupabaseEnvironment {
        let urlString = firstValue(
            keys: [
                "DRUM_LESSON_OS_SUPABASE_URL",
                "SUPABASE_URL"
            ],
            environment: environment,
            bundle: bundle
        )
        let key = firstValue(
            keys: [
                "DRUM_LESSON_OS_SUPABASE_PUBLISHABLE_KEY",
                "SUPABASE_PUBLISHABLE_KEY",
                "SUPABASE_ANON_KEY"
            ],
            environment: environment,
            bundle: bundle
        )

        guard let urlString,
              let url = URL(string: urlString),
              let key else {
            throw RepositoryError(message: "Create a native Supabase config with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.")
        }

        try validatePublishableKey(key)
        return SupabaseEnvironment(url: url, publishableKey: key)
    }

    private static func firstValue(keys: [String], environment: [String: String], bundle: Bundle?) -> String? {
        for key in keys {
            if let value = clean(environment[key]) {
                return value
            }
        }

        for key in keys {
            if let value = clean(bundle?.object(forInfoDictionaryKey: key) as? String) {
                return value
            }
        }

        return nil
    }

    private static func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              !trimmed.contains("$(") else {
            return nil
        }
        return trimmed
    }

    private static func validatePublishableKey(_ key: String) throws {
        let lowered = key.lowercased()
        if lowered.contains("service_role") || lowered.hasPrefix("sb_secret_") || jwtPayloadContainsServiceRole(key) {
            throw RepositoryError(message: "Native Supabase config must use a publishable key, never a service-role key.")
        }
    }

    private static func jwtPayloadContainsServiceRole(_ key: String) -> Bool {
        let parts = key.split(separator: ".")
        guard parts.count >= 2 else { return false }

        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 {
            payload.append("=")
        }

        guard let data = Data(base64Encoded: payload),
              let decoded = String(data: data, encoding: .utf8) else {
            return false
        }

        return decoded.localizedCaseInsensitiveContains("\"role\":\"service_role\"") ||
            decoded.localizedCaseInsensitiveContains("\"role\": \"service_role\"")
    }
}
