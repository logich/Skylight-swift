import XCTest
@testable import SkylightApp

@MainActor
final class ChoresViewModelTests: XCTestCase {

    var mockChoresService: MockChoresService!
    var mockKeychainManager: MockKeychainManager!
    var mockAPIClient: MockAPIClient!
    var testDefaults: UserDefaults!
    var authManager: AuthenticationManager!
    var sut: ChoresViewModel!

    override func setUp() async throws {
        try await super.setUp()

        mockChoresService = MockChoresService()
        mockKeychainManager = MockKeychainManager()
        mockAPIClient = MockAPIClient()

        testDefaults = UserDefaults(suiteName: "com.test.skylight.chores")!
        testDefaults.removePersistentDomain(forName: "com.test.skylight.chores")

        // Set up authenticated state with a selected frame
        mockKeychainManager.setupAuthenticatedState()
        testDefaults.set("test-frame-id", forKey: Constants.UserDefaults.selectedFrameIdKey)

        authManager = AuthenticationManager(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient,
            userDefaults: testDefaults
        )

        sut = ChoresViewModel(
            choresService: mockChoresService,
            authManager: authManager
        )
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "com.test.skylight.chores")
        testDefaults = nil
        mockChoresService = nil
        mockKeychainManager = nil
        mockAPIClient = nil
        authManager = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - loadChores Tests

    func testLoadChores_FetchesChoresFromService() async throws {
        // Given
        let expectedChores = [
            TestDataFactory.makeChore(id: "1", title: "Chore 1"),
            TestDataFactory.makeChore(id: "2", title: "Chore 2")
        ]
        mockChoresService.choresToReturn = expectedChores

        // When
        await sut.loadChores()

        // Then
        XCTAssertTrue(mockChoresService.getChoresCalled)
        XCTAssertEqual(sut.chores.count, 2)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadChores_SetsErrorOnFailure() async throws {
        // Given
        mockChoresService.errorToThrow = APIError.serverError(500, nil)

        // When
        await sut.loadChores()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
    }

    // MARK: - Computed Properties Tests

    func testPendingChores_FiltersIncompleteChores() async throws {
        // Given
        let chores = [
            TestDataFactory.makeChore(id: "1", title: "Pending 1", isCompleted: false),
            TestDataFactory.makeChore(id: "2", title: "Completed 1", isCompleted: true),
            TestDataFactory.makeChore(id: "3", title: "Pending 2", isCompleted: false)
        ]
        mockChoresService.choresToReturn = chores
        await sut.loadChores()

        // When
        let pending = sut.pendingChores

        // Then
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { !$0.isCompleted })
    }

    func testPendingChores_SortsByDueDate() async throws {
        // Given
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let chores = [
            TestDataFactory.makeChore(id: "later", title: "Later", dueDate: tomorrow),
            TestDataFactory.makeChore(id: "earlier", title: "Earlier", dueDate: yesterday),
            TestDataFactory.makeChore(id: "middle", title: "Middle", dueDate: today)
        ]
        mockChoresService.choresToReturn = chores
        await sut.loadChores()

        // When
        let pending = sut.pendingChores

        // Then
        XCTAssertEqual(pending[0].id, "earlier")
        XCTAssertEqual(pending[1].id, "middle")
        XCTAssertEqual(pending[2].id, "later")
    }

    func testCompletedChores_FiltersCompletedChores() async throws {
        // Given
        let chores = [
            TestDataFactory.makeChore(id: "1", title: "Pending", isCompleted: false),
            TestDataFactory.makeChore(id: "2", title: "Completed", isCompleted: true, completedAt: Date())
        ]
        mockChoresService.choresToReturn = chores
        await sut.loadChores()

        // When
        let completed = sut.completedChores

        // Then
        XCTAssertEqual(completed.count, 1)
        XCTAssertTrue(completed.first!.isCompleted)
    }

    func testOverdueChores_ReturnsChoresPastDueDate() async throws {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let chores = [
            TestDataFactory.makeChore(id: "overdue", title: "Overdue", dueDate: yesterday, isCompleted: false),
            TestDataFactory.makeChore(id: "upcoming", title: "Upcoming", dueDate: tomorrow, isCompleted: false)
        ]
        mockChoresService.choresToReturn = chores
        await sut.loadChores()

        // When
        let overdue = sut.overdueChores

        // Then
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.id, "overdue")
    }

    // MARK: - createChore Tests

    func testCreateChore_AddsChoreToList() async throws {
        // Given
        let newChore = TestDataFactory.makeChore(id: "new", title: "New Chore")
        mockChoresService.choreToReturn = newChore

        // When
        await sut.createChore(
            title: "New Chore",
            assigneeId: nil,
            dueDate: Date(),
            recurrence: nil,
            points: 10
        )

        // Then
        XCTAssertTrue(mockChoresService.createChoreCalled)
        XCTAssertEqual(sut.chores.count, 1)
        XCTAssertFalse(sut.showCreateSheet)
    }

    func testCreateChore_SetsErrorOnFailure() async throws {
        // Given
        mockChoresService.errorToThrow = APIError.serverError(500, nil)

        // When
        await sut.createChore(
            title: "New Chore",
            assigneeId: nil,
            dueDate: nil,
            recurrence: nil,
            points: nil
        )

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
    }

    // MARK: - markComplete Tests

    func testMarkComplete_UpdatesChoreInList() async throws {
        // Given
        let chore = TestDataFactory.makeChore(id: "1", title: "Test Chore", isCompleted: false)
        mockChoresService.choresToReturn = [chore]
        await sut.loadChores()

        let completedChore = TestDataFactory.makeChore(
            id: "1",
            title: "Test Chore",
            isCompleted: true,
            completedAt: Date()
        )
        mockChoresService.choreToReturn = completedChore

        // When
        await sut.markComplete(choreId: "1")

        // Then
        XCTAssertTrue(mockChoresService.completeChoreCalled)
        XCTAssertEqual(mockChoresService.lastChoreId, "1")
        XCTAssertTrue(sut.chores.first!.isCompleted)
    }

    // MARK: - deleteChore Tests

    func testDeleteChore_RemovesChoreFromList() async throws {
        // Given
        let chores = [
            TestDataFactory.makeChore(id: "1", title: "Chore 1"),
            TestDataFactory.makeChore(id: "2", title: "Chore 2")
        ]
        mockChoresService.choresToReturn = chores
        await sut.loadChores()
        XCTAssertEqual(sut.chores.count, 2)

        // When
        await sut.deleteChore(choreId: "1")

        // Then
        XCTAssertTrue(mockChoresService.deleteChoreCalled)
        XCTAssertEqual(sut.chores.count, 1)
        XCTAssertFalse(sut.chores.contains { $0.id == "1" })
    }

    func testDeleteChore_SetsErrorOnFailure() async throws {
        // Given
        mockChoresService.choresToReturn = [TestDataFactory.makeChore(id: "1")]
        await sut.loadChores()

        mockChoresService.errorToThrow = APIError.notFound

        // When
        await sut.deleteChore(choreId: "1")

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
        // Chore should still be in the list since delete failed
        XCTAssertEqual(sut.chores.count, 1)
    }
}
