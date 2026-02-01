import Foundation
@testable import SkylightApp

final class MockListsService: ListsServiceProtocol {
    var listsToReturn: [ShoppingList] = []
    var itemsToReturn: [ListItem] = []
    var itemToReturn: ListItem?
    var errorToThrow: Error?

    var getListsCalled = false
    var getListItemsCalled = false
    var addItemCalled = false
    var updateItemCalled = false
    var deleteItemCalled = false

    var lastFrameId: String?
    var lastListId: String?
    var lastItemId: String?

    func getLists(frameId: String) async throws -> [ShoppingList] {
        getListsCalled = true
        lastFrameId = frameId

        if let error = errorToThrow {
            throw error
        }
        return listsToReturn
    }

    func getListItems(frameId: String, listId: String) async throws -> [ListItem] {
        getListItemsCalled = true
        lastFrameId = frameId
        lastListId = listId

        if let error = errorToThrow {
            throw error
        }
        return itemsToReturn
    }

    func addItem(frameId: String, listId: String, item: CreateListItemRequest) async throws -> ListItem {
        addItemCalled = true
        lastFrameId = frameId
        lastListId = listId

        if let error = errorToThrow {
            throw error
        }
        guard let itemToReturn = itemToReturn else {
            throw APIError.invalidResponse
        }
        return itemToReturn
    }

    func updateItem(frameId: String, listId: String, itemId: String, updates: UpdateListItemRequest) async throws -> ListItem {
        updateItemCalled = true
        lastFrameId = frameId
        lastListId = listId
        lastItemId = itemId

        if let error = errorToThrow {
            throw error
        }
        guard let itemToReturn = itemToReturn else {
            throw APIError.invalidResponse
        }
        return itemToReturn
    }

    func deleteItem(frameId: String, listId: String, itemId: String) async throws {
        deleteItemCalled = true
        lastFrameId = frameId
        lastListId = listId
        lastItemId = itemId

        if let error = errorToThrow {
            throw error
        }
    }

    func reset() {
        listsToReturn = []
        itemsToReturn = []
        itemToReturn = nil
        errorToThrow = nil
        getListsCalled = false
        getListItemsCalled = false
        addItemCalled = false
        updateItemCalled = false
        deleteItemCalled = false
        lastFrameId = nil
        lastListId = nil
        lastItemId = nil
    }
}
