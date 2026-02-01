import Foundation
@testable import SkylightApp

final class MockTasksService: TasksServiceProtocol {
    var tasksToReturn: [SkylightTask] = []
    var taskToReturn: SkylightTask?
    var errorToThrow: Error?

    var getTaskBoxItemsCalled = false
    var createTaskBoxItemCalled = false
    var lastFrameId: String?
    var lastTitle: String?

    func getTaskBoxItems(frameId: String) async throws -> [SkylightTask] {
        getTaskBoxItemsCalled = true
        lastFrameId = frameId

        if let error = errorToThrow {
            throw error
        }
        return tasksToReturn
    }

    func createTaskBoxItem(frameId: String, title: String) async throws -> SkylightTask {
        createTaskBoxItemCalled = true
        lastFrameId = frameId
        lastTitle = title

        if let error = errorToThrow {
            throw error
        }
        guard let taskToReturn = taskToReturn else {
            throw APIError.invalidResponse
        }
        return taskToReturn
    }

    func reset() {
        tasksToReturn = []
        taskToReturn = nil
        errorToThrow = nil
        getTaskBoxItemsCalled = false
        createTaskBoxItemCalled = false
        lastFrameId = nil
        lastTitle = nil
    }
}
