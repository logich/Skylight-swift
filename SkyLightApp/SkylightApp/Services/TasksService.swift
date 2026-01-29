import Foundation

protocol TasksServiceProtocol {
    func getTaskBoxItems(frameId: String) async throws -> [SkylightTask]
    func createTaskBoxItem(frameId: String, title: String) async throws -> SkylightTask
}

final class TasksService: TasksServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getTaskBoxItems(frameId: String) async throws -> [SkylightTask] {
        let endpoint = SkylightEndpoint.getTaskBoxItems(frameId: frameId)
        let response: TasksResponse = try await apiClient.request(endpoint)
        return response.tasks
    }

    func createTaskBoxItem(frameId: String, title: String) async throws -> SkylightTask {
        let item = CreateTaskBoxItemRequest(title: title)
        let endpoint = SkylightEndpoint.createTaskBoxItem(frameId: frameId, item: item)
        let response: TaskResponse = try await apiClient.request(endpoint)
        return response.task
    }
}
