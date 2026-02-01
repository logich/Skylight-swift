import XCTest
@testable import SkylightApp

@MainActor
final class ListsServiceTests: XCTestCase {

    var mockAPIClient: MockAPIClient!
    var sut: ListsService!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = ListsService(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        mockAPIClient = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - getLists Tests

    func testGetLists_ReturnsListsFromAPI() async throws {
        // Given
        let expectedLists = [
            TestDataFactory.makeShoppingList(id: "1", name: "Groceries"),
            TestDataFactory.makeShoppingList(id: "2", name: "Hardware Store")
        ]
        let response = ListsResponse(lists: expectedLists)
        mockAPIClient.responseToReturn = response

        // When
        let lists = try await sut.getLists(frameId: "frame-123")

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(lists.count, 2)
        XCTAssertEqual(lists[0].name, "Groceries")
        XCTAssertEqual(lists[1].name, "Hardware Store")
    }

    func testGetLists_WithEmptyResponse_ReturnsEmptyArray() async throws {
        // Given
        let response = ListsResponse(lists: [])
        mockAPIClient.responseToReturn = response

        // When
        let lists = try await sut.getLists(frameId: "frame-123")

        // Then
        XCTAssertTrue(lists.isEmpty)
    }

    // MARK: - getListItems Tests

    func testGetListItems_ReturnsItemsFromAPI() async throws {
        // Given
        let expectedItems = [
            TestDataFactory.makeListItem(id: "1", title: "Milk"),
            TestDataFactory.makeListItem(id: "2", title: "Bread")
        ]
        let response = ListItemsResponse(items: expectedItems)
        mockAPIClient.responseToReturn = response

        // When
        let items = try await sut.getListItems(frameId: "frame-123", listId: "list-1")

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "Milk")
        XCTAssertEqual(items[1].title, "Bread")
    }

    // MARK: - addItem Tests

    func testAddItem_ReturnsCreatedItem() async throws {
        // Given
        let createdItem = TestDataFactory.makeListItem(id: "new-item", title: "Eggs")
        let response = ListItemResponse(item: createdItem)
        mockAPIClient.responseToReturn = response

        let request = CreateListItemRequest(title: "Eggs", quantity: "12", notes: nil)

        // When
        let item = try await sut.addItem(frameId: "frame-123", listId: "list-1", item: request)

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(item.title, "Eggs")
    }

    // MARK: - updateItem Tests

    func testUpdateItem_ReturnsUpdatedItem() async throws {
        // Given
        let updatedItem = TestDataFactory.makeListItem(id: "item-1", title: "Eggs", isChecked: true)
        let response = ListItemResponse(item: updatedItem)
        mockAPIClient.responseToReturn = response

        let updates = UpdateListItemRequest(title: nil, quantity: nil, notes: nil, checked: true)

        // When
        let item = try await sut.updateItem(
            frameId: "frame-123",
            listId: "list-1",
            itemId: "item-1",
            updates: updates
        )

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertTrue(item.isChecked)
    }

    // MARK: - deleteItem Tests

    func testDeleteItem_CallsAPI() async throws {
        // When
        try await sut.deleteItem(frameId: "frame-123", listId: "list-1", itemId: "item-1")

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
    }

    func testDeleteItem_WhenAPIFails_ThrowsError() async {
        // Given
        mockAPIClient.errorToThrow = APIError.notFound

        // When/Then
        do {
            try await sut.deleteItem(frameId: "frame-123", listId: "list-1", itemId: "item-1")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
}

// MARK: - Response Types for Testing

private struct ListsResponse: Codable {
    let lists: [ShoppingList]
}

private struct ListItemsResponse: Codable {
    let items: [ListItem]
}

private struct ListItemResponse: Codable {
    let item: ListItem
}
