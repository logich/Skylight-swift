import Foundation

protocol TasksServiceProtocol {
    func getTasks(frameId: String) async throws -> [SkylightTask]
    func createTask(frameId: String, task: CreateTaskRequest) async throws -> SkylightTask
}

final class TasksService: TasksServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getTasks(frameId: String) async throws -> [SkylightTask] {
        let endpoint = SkylightEndpoint.getTasks(frameId: frameId)
        let response: TasksResponse = try await apiClient.request(endpoint)
        return response.tasks
    }

    func createTask(frameId: String, task: CreateTaskRequest) async throws -> SkylightTask {
        let endpoint = SkylightEndpoint.createTask(frameId: frameId, task: task)
        let response: TaskResponse = try await apiClient.request(endpoint)
        return response.task
    }
}
