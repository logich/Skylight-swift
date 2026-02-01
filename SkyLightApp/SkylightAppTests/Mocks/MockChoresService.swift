import Foundation
@testable import SkylightApp

final class MockChoresService: ChoresServiceProtocol {
    var choresToReturn: [Chore] = []
    var choreToReturn: Chore?
    var errorToThrow: Error?

    var getChoresCalled = false
    var createChoreCalled = false
    var updateChoreCalled = false
    var deleteChoreCalled = false
    var completeChoreCalled = false

    var lastFrameId: String?
    var lastChoreId: String?
    var lastCreateRequest: CreateChoreRequest?
    var lastUpdateRequest: UpdateChoreRequest?

    func getChores(frameId: String, after: Date, before: Date, includeLate: Bool) async throws -> [Chore] {
        getChoresCalled = true
        lastFrameId = frameId

        if let error = errorToThrow {
            throw error
        }
        return choresToReturn
    }

    func createChore(frameId: String, chore: CreateChoreRequest) async throws -> Chore {
        createChoreCalled = true
        lastFrameId = frameId
        lastCreateRequest = chore

        if let error = errorToThrow {
            throw error
        }
        guard let choreToReturn = choreToReturn else {
            throw APIError.invalidResponse
        }
        return choreToReturn
    }

    func updateChore(frameId: String, choreId: String, updates: UpdateChoreRequest) async throws -> Chore {
        updateChoreCalled = true
        lastFrameId = frameId
        lastChoreId = choreId
        lastUpdateRequest = updates

        if let error = errorToThrow {
            throw error
        }
        guard let choreToReturn = choreToReturn else {
            throw APIError.invalidResponse
        }
        return choreToReturn
    }

    func deleteChore(frameId: String, choreId: String) async throws {
        deleteChoreCalled = true
        lastFrameId = frameId
        lastChoreId = choreId

        if let error = errorToThrow {
            throw error
        }
    }

    func completeChore(frameId: String, choreId: String) async throws -> Chore {
        completeChoreCalled = true
        lastFrameId = frameId
        lastChoreId = choreId

        if let error = errorToThrow {
            throw error
        }
        guard let choreToReturn = choreToReturn else {
            throw APIError.invalidResponse
        }
        return choreToReturn
    }

    func reset() {
        choresToReturn = []
        choreToReturn = nil
        errorToThrow = nil
        getChoresCalled = false
        createChoreCalled = false
        updateChoreCalled = false
        deleteChoreCalled = false
        completeChoreCalled = false
        lastFrameId = nil
        lastChoreId = nil
        lastCreateRequest = nil
        lastUpdateRequest = nil
    }
}
