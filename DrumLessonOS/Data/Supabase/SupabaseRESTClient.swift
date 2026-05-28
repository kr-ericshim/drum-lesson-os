import Foundation

enum JSONValue: Encodable, Equatable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    static func uuid(_ value: EntityID) -> JSONValue {
        .string(value.uuidString.lowercased())
    }

    static func optionalUUID(_ value: EntityID?) -> JSONValue {
        value.map { .uuid($0) } ?? .null
    }

    static func optionalString(_ value: String?) -> JSONValue {
        value.map { .string($0) } ?? .null
    }
}

@MainActor
protocol SupabaseHTTPTransport: AnyObject {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension URLSession: SupabaseHTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError(message: "Supabase returned a non-HTTP response.")
        }
        return (data, httpResponse)
    }
}

struct SupabaseMutationResult: Decodable, Equatable {
    var id: EntityID
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case updatedAt = "updated_at"
    }
}

@MainActor
final class SupabaseRESTClient {
    private let environment: SupabaseEnvironment
    private let transport: SupabaseHTTPTransport
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(environment: SupabaseEnvironment, transport: SupabaseHTTPTransport = URLSession.shared) {
        self.environment = environment
        self.transport = transport
    }

    func signIn(email: String, password: String) async throws -> SupabaseStoredSession {
        let body: [String: JSONValue] = [
            "email": .string(email),
            "password": .string(password)
        ]
        let response: SupabaseAuthTokenResponse = try await post(
            path: "auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: body,
            accessToken: nil
        )
        return response.storedSession
    }

    func refreshSession(refreshToken: String) async throws -> SupabaseStoredSession {
        let response: SupabaseAuthTokenResponse = try await post(
            path: "auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: ["refresh_token": .string(refreshToken)],
            accessToken: nil
        )
        return response.storedSession
    }

    func signOut(accessToken: String) async throws {
        try await postWithoutResponse(
            path: "auth/v1/logout",
            queryItems: [],
            body: [:],
            accessToken: accessToken
        )
    }

    func recoverPassword(email: String) async throws {
        try await postWithoutResponse(
            path: "auth/v1/recover",
            queryItems: [],
            body: ["email": .string(email)],
            accessToken: nil
        )
    }

    func select<T: Decodable>(
        _ type: T.Type,
        table: String,
        queryItems: [URLQueryItem],
        accessToken: String
    ) async throws -> T {
        var items = [URLQueryItem(name: "select", value: "*")]
        items.append(contentsOf: queryItems)

        var request = try makeRequest(path: "rest/v1/\(table)", queryItems: items, accessToken: accessToken)
        request.httpMethod = "GET"
        return try await execute(request, as: T.self)
    }

    func rpc<T: Decodable>(
        _ type: T.Type,
        name: String,
        payload: [String: JSONValue],
        accessToken: String
    ) async throws -> T {
        try SupabaseRPCClient.validate(name: name)
        return try await post(
            path: "rest/v1/rpc/\(name)",
            queryItems: [],
            body: payload,
            accessToken: accessToken
        )
    }

    func rpcVoid(name: String, payload: [String: JSONValue], accessToken: String) async throws {
        try SupabaseRPCClient.validate(name: name)
        try await postWithoutResponse(
            path: "rest/v1/rpc/\(name)",
            queryItems: [],
            body: payload,
            accessToken: accessToken
        )
    }

    private func post<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        body: [String: JSONValue],
        accessToken: String?
    ) async throws -> T {
        var request = try makeRequest(path: path, queryItems: queryItems, accessToken: accessToken)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await execute(request, as: T.self)
    }

    private func postWithoutResponse(
        path: String,
        queryItems: [URLQueryItem],
        body: [String: JSONValue],
        accessToken: String?
    ) async throws {
        var request = try makeRequest(path: path, queryItems: queryItems, accessToken: accessToken)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try await executeRaw(request)
    }

    private func makeRequest(path: String, queryItems: [URLQueryItem], accessToken: String?) throws -> URLRequest {
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let baseURL = environment.url.appendingPathComponent(cleanPath)
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw RepositoryError(message: "Invalid Supabase URL.")
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw RepositoryError(message: "Invalid Supabase request URL.")
        }

        var request = URLRequest(url: url)
        request.setValue(environment.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data = try await executeRaw(request)
        return try decoder.decode(T.self, from: data)
    }

    private func executeRaw(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            throw RepositoryError(message: errorMessage(from: data, statusCode: response.statusCode))
        }
        return data.isEmpty ? Data("{}".utf8) : data
    }

    private func errorMessage(from data: Data, statusCode: Int) -> String {
        if let payload = try? decoder.decode(SupabaseErrorPayload.self, from: data),
           let message = payload.resolvedMessage {
            return message
        }
        return "Supabase request failed with HTTP \(statusCode)."
    }
}

private struct SupabaseAuthTokenResponse: Decodable {
    var accessToken: String
    var refreshToken: String
    var tokenType: String
    var user: SupabaseAuthUser

    var storedSession: SupabaseStoredSession {
        SupabaseStoredSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            userId: user.id
        )
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case user
    }
}

private struct SupabaseAuthUser: Decodable {
    var id: EntityID
}

private struct SupabaseErrorPayload: Decodable {
    var message: String?
    var msg: String?
    var error: String?
    var errorDescription: String?

    var resolvedMessage: String? {
        message ?? msg ?? errorDescription ?? error
    }

    enum CodingKeys: String, CodingKey {
        case message
        case msg
        case error
        case errorDescription = "error_description"
    }
}
