import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var requiresAuthentication: Bool { get }
}

extension APIEndpoint {
    var baseURL: String {
        Constants.API.baseURL
    }

    var headers: [String: String]? {
        nil
    }

    var queryItems: [URLQueryItem]? {
        nil
    }

    var body: Data? {
        nil
    }

    var requiresAuthentication: Bool {
        true
    }

    var url: URL? {
        var components = URLComponents(string: baseURL)
        components?.path = path

        if let queryItems = queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        return components?.url
    }

    func asURLRequest(authCredentials: (userId: String, token: String)?) throws -> URLRequest {
        guard let url = url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = Constants.API.timeout

        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add authentication header if required
        // Skylight API uses Basic auth with userId:token base64 encoded
        if requiresAuthentication, let credentials = authCredentials {
            let credentialString = "\(credentials.userId):\(credentials.token)"
            if let credentialData = credentialString.data(using: .utf8) {
                let base64Credentials = credentialData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
        }

        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if present
        if let body = body {
            request.httpBody = body
        }

        return request
    }
}
