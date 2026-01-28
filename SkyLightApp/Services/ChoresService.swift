import Foundation

protocol ChoresServiceProtocol {
    func getChores(frameId: String) async throws -> [Chore]
    func createChore(frameId: String, chore: CreateChoreRequest) async throws -> Chore
    func updateChore(frameId: String, choreId: String, updates: UpdateChoreRequest) async throws -> Chore
    func deleteChore(frameId: String, choreId: String) async throws
    func completeChore(frameId: String, choreId: String) async throws -> Chore
}

final class ChoresService: ChoresServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getChores(frameId: String) async throws -> [Chore] {
        let endpoint = SkylightEndpoint.getChores(frameId: frameId)
        let response: ChoresResponse = try await apiClient.request(endpoint)
        return response.chores
    }

    func createChore(frameId: String, chore: CreateChoreRequest) async throws -> Chore {
        let endpoint = SkylightEndpoint.createChore(frameId: frameId, chore: chore)
        let response: ChoreResponse = try await apiClient.request(endpoint)
        return response.chore
    }

    func updateChore(frameId: String, choreId: String, updates: UpdateChoreRequest) async throws -> Chore {
        let endpoint = SkylightEndpoint.updateChore(frameId: frameId, choreId: choreId, updates: updates)
        let response: ChoreResponse = try await apiClient.request(endpoint)
        return response.chore
    }

    func deleteChore(frameId: String, choreId: String) async throws {
        let endpoint = SkylightEndpoint.deleteChore(frameId: frameId, choreId: choreId)
        try await apiClient.requestWithoutResponse(endpoint)
    }

    func completeChore(frameId: String, choreId: String) async throws -> Chore {
        let endpoint = SkylightEndpoint.completeChore(frameId: frameId, choreId: choreId)
        let response: ChoreResponse = try await apiClient.request(endpoint)
        return response.chore
    }
}
