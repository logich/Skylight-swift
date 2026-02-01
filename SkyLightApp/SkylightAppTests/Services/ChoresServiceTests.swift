import XCTest
@testable import SkylightApp

@MainActor
final class ChoresServiceTests: XCTestCase {

    var mockAPIClient: MockAPIClient!
    var sut: ChoresService!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = ChoresService(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        mockAPIClient = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - getChores Tests

    func testGetChores_ReturnsChoresFromAPI() async throws {
        // Given
        let expectedChores = [
            TestDataFactory.makeChore(id: "1", title: "Chore 1"),
            TestDataFactory.makeChore(id: "2", title: "Chore 2")
        ]
        let response = ChoresResponse(chores: expectedChores)
        mockAPIClient.responseToReturn = response

        // When
        let chores = try await sut.getChores(
            frameId: "frame-123",
            after: Date(),
            before: Date().addingTimeInterval(86400 * 30),
            includeLate: true
        )

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(chores.count, 2)
        XCTAssertEqual(chores[0].title, "Chore 1")
        XCTAssertEqual(chores[1].title, "Chore 2")
    }

    func testGetChores_WhenAPIFails_ThrowsError() async {
        // Given
        mockAPIClient.errorToThrow = APIError.serverError(500, nil)

        // When/Then
        do {
            _ = try await sut.getChores(
                frameId: "frame-123",
                after: Date(),
                before: Date().addingTimeInterval(86400 * 30),
                includeLate: true
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }

    // MARK: - createChore Tests

    func testCreateChore_ReturnsCreatedChore() async throws {
        // Given
        let createdChore = TestDataFactory.makeChore(id: "new-chore", title: "New Chore")
        let response = ChoreResponse(chore: createdChore)
        mockAPIClient.responseToReturn = response

        let request = CreateChoreRequest(
            title: "New Chore",
            assigneeId: nil,
            dueDate: Date(),
            recurrence: nil,
            points: 10
        )

        // When
        let chore = try await sut.createChore(frameId: "frame-123", chore: request)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(chore.id, "new-chore")
        XCTAssertEqual(chore.title, "New Chore")
    }

    // MARK: - updateChore Tests

    func testUpdateChore_ReturnsUpdatedChore() async throws {
        // Given
        let updatedChore = TestDataFactory.makeChore(id: "chore-1", title: "Updated Title")
        let response = ChoreResponse(chore: updatedChore)
        mockAPIClient.responseToReturn = response

        let updates = UpdateChoreRequest(
            title: "Updated Title",
            assigneeId: nil,
            dueDate: nil,
            recurrence: nil,
            points: nil,
            completed: nil
        )

        // When
        let chore = try await sut.updateChore(
            frameId: "frame-123",
            choreId: "chore-1",
            updates: updates
        )

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(chore.title, "Updated Title")
    }

    // MARK: - deleteChore Tests

    func testDeleteChore_CallsAPI() async throws {
        // Given - no response needed for delete

        // When
        try await sut.deleteChore(frameId: "frame-123", choreId: "chore-1")

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
    }

    func testDeleteChore_WhenAPIFails_ThrowsError() async {
        // Given
        mockAPIClient.errorToThrow = APIError.notFound

        // When/Then
        do {
            try await sut.deleteChore(frameId: "frame-123", choreId: "chore-1")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }

    // MARK: - completeChore Tests

    func testCompleteChore_SetsCompletedToTrue() async throws {
        // Given
        let completedChore = TestDataFactory.makeChore(
            id: "chore-1",
            title: "Done Chore",
            isCompleted: true,
            completedAt: Date()
        )
        let response = ChoreResponse(chore: completedChore)
        mockAPIClient.responseToReturn = response

        // When
        let chore = try await sut.completeChore(frameId: "frame-123", choreId: "chore-1")

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertTrue(chore.isCompleted)
    }
}

// MARK: - Response Types for Testing

private struct ChoresResponse: Codable {
    let chores: [Chore]
}

private struct ChoreResponse: Codable {
    let chore: Chore
}
