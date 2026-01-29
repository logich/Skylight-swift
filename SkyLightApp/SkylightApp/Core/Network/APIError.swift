import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case noData
    case unknown(Error?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error: \(statusCode)"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .noData:
            return "No data received"
        case .unknown(let error):
            if let error = error {
                return "Unknown error: \(error.localizedDescription)"
            }
            return "An unknown error occurred"
        }
    }

    var isAuthenticationError: Bool {
        switch self {
        case .unauthorized:
            return true
        default:
            return false
        }
    }

    static func from(statusCode: Int, data: Data?) -> APIError {
        var message: String?
        if let data = data, let errorResponse = try? JSONCoders.decoder.decode(ErrorResponse.self, from: data) {
            message = errorResponse.message ?? errorResponse.error
        }

        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited
        case 400..<500:
            return .serverError(statusCode: statusCode, message: message)
        case 500..<600:
            return .serverError(statusCode: statusCode, message: message ?? "Internal server error")
        default:
            return .serverError(statusCode: statusCode, message: message)
        }
    }
}

struct ErrorResponse: Decodable {
    let error: String?
    let message: String?
    let statusCode: Int?
}
