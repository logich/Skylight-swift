import Foundation

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func requestWithoutResponse(_ endpoint: APIEndpoint) async throws
}

final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let session: URLSession
    private let keychainManager: KeychainManagerProtocol

    init(
        session: URLSession = .shared,
        keychainManager: KeychainManagerProtocol = KeychainManager.shared
    ) {
        self.session = session
        self.keychainManager = keychainManager
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await performRequest(endpoint)

        do {
            let decoded = try JSONCoders.decoder.decode(T.self, from: data)
            return decoded
        } catch {
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode response: \(jsonString)")
            }
            #endif
            throw APIError.decodingError(error)
        }
    }

    func requestWithoutResponse(_ endpoint: APIEndpoint) async throws {
        _ = try await performRequest(endpoint)
    }

    private func performRequest(_ endpoint: APIEndpoint) async throws -> Data {
        var authCredentials: (userId: String, token: String)?
        if endpoint.requiresAuthentication,
           let userId = keychainManager.getUserId(),
           let token = keychainManager.getAccessToken() {
            authCredentials = (userId: userId, token: token)
        }

        let request: URLRequest
        do {
            request = try endpoint.asURLRequest(authCredentials: authCredentials)
        } catch {
            throw APIError.invalidRequest
        }

        #if DEBUG
        logRequest(request)
        #endif

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        logResponse(httpResponse, data: data)
        #endif

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.from(statusCode: httpResponse.statusCode, data: data)
        }

        return data
    }

    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("--- API Request ---")
        print("\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        request.allHTTPHeaderFields?.forEach { key, value in
            if key.lowercased() != "authorization" {
                print("\(key): \(value)")
            } else {
                print("\(key): Bearer ***")
            }
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        print("-------------------")
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        print("--- API Response ---")
        print("Status: \(response.statusCode)")
        if let bodyString = String(data: data, encoding: .utf8) {
            let truncated = bodyString.prefix(500)
            print("Body: \(truncated)\(bodyString.count > 500 ? "..." : "")")
        }
        print("--------------------")
    }
    #endif
}
