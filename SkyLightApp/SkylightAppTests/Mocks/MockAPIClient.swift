import Foundation
@testable import SkylightApp

final class MockAPIClient: APIClientProtocol {
    var responseToReturn: Any?
    var errorToThrow: Error?
    var requestCalled = false
    var lastEndpoint: APIEndpoint?

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        requestCalled = true
        lastEndpoint = endpoint

        if let error = errorToThrow {
            throw error
        }

        guard let response = responseToReturn as? T else {
            throw APIError.decodingError(NSError(domain: "MockAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock response configured"]))
        }
        return response
    }

    func requestWithoutResponse(_ endpoint: APIEndpoint) async throws {
        requestCalled = true
        lastEndpoint = endpoint

        if let error = errorToThrow {
            throw error
        }
    }

    func reset() {
        responseToReturn = nil
        errorToThrow = nil
        requestCalled = false
        lastEndpoint = nil
    }
}
