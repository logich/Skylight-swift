import Foundation

protocol ListsServiceProtocol {
    func getLists(frameId: String) async throws -> [ShoppingList]
    func getListItems(frameId: String, listId: String) async throws -> [ListItem]
    func addItem(frameId: String, listId: String, item: CreateListItemRequest) async throws -> ListItem
    func updateItem(frameId: String, listId: String, itemId: String, updates: UpdateListItemRequest) async throws -> ListItem
    func deleteItem(frameId: String, listId: String, itemId: String) async throws
}

final class ListsService: ListsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getLists(frameId: String) async throws -> [ShoppingList] {
        let endpoint = SkylightEndpoint.getLists(frameId: frameId)
        let response: ListsResponse = try await apiClient.request(endpoint)
        return response.lists
    }

    func getListItems(frameId: String, listId: String) async throws -> [ListItem] {
        let endpoint = SkylightEndpoint.getListItems(frameId: frameId, listId: listId)
        let response: ListItemsResponse = try await apiClient.request(endpoint)
        return response.items
    }

    func addItem(frameId: String, listId: String, item: CreateListItemRequest) async throws -> ListItem {
        let endpoint = SkylightEndpoint.addListItem(frameId: frameId, listId: listId, item: item)
        let response: ListItemResponse = try await apiClient.request(endpoint)
        return response.item
    }

    func updateItem(frameId: String, listId: String, itemId: String, updates: UpdateListItemRequest) async throws -> ListItem {
        let endpoint = SkylightEndpoint.updateListItem(frameId: frameId, listId: listId, itemId: itemId, updates: updates)
        let response: ListItemResponse = try await apiClient.request(endpoint)
        return response.item
    }

    func deleteItem(frameId: String, listId: String, itemId: String) async throws {
        let endpoint = SkylightEndpoint.deleteListItem(frameId: frameId, listId: listId, itemId: itemId)
        try await apiClient.requestWithoutResponse(endpoint)
    }
}
