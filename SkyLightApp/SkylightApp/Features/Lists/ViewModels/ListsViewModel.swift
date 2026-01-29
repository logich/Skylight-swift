import Foundation
import Combine

@MainActor
final class ListsViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false

    private let listsService: ListsServiceProtocol
    private let authManager: AuthenticationManager

    init(
        listsService: ListsServiceProtocol = ListsService(),
        authManager: AuthenticationManager = .shared
    ) {
        self.listsService = listsService
        self.authManager = authManager
    }

    func loadLists() async {
        guard let frameId = authManager.currentFrameId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            lists = try await listsService.getLists(frameId: frameId)
        } catch {
            self.error = error
            self.showError = true
        }
    }
}

@MainActor
final class ListDetailViewModel: ObservableObject {
    @Published var list: ShoppingList?
    @Published var items: [ListItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false
    @Published var newItemTitle: String = ""

    private let listsService: ListsServiceProtocol
    private let authManager: AuthenticationManager
    let listId: String

    var uncheckedItems: [ListItem] {
        items.filter { !$0.isChecked }
    }

    var checkedItems: [ListItem] {
        items.filter { $0.isChecked }
    }

    init(
        listId: String,
        listsService: ListsServiceProtocol = ListsService(),
        authManager: AuthenticationManager = .shared
    ) {
        self.listId = listId
        self.listsService = listsService
        self.authManager = authManager
    }

    func loadItems() async {
        guard let frameId = authManager.currentFrameId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            items = try await listsService.getListItems(frameId: frameId, listId: listId)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func addItem() async {
        guard let frameId = authManager.currentFrameId else { return }
        guard !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let request = CreateListItemRequest(
            title: newItemTitle.trimmingCharacters(in: .whitespaces),
            quantity: nil,
            notes: nil
        )

        do {
            let newItem = try await listsService.addItem(frameId: frameId, listId: listId, item: request)
            items.append(newItem)
            newItemTitle = ""
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func toggleItem(_ item: ListItem) async {
        guard let frameId = authManager.currentFrameId else { return }

        let request = UpdateListItemRequest(
            title: nil,
            quantity: nil,
            notes: nil,
            checked: !item.isChecked
        )

        do {
            let updatedItem = try await listsService.updateItem(
                frameId: frameId,
                listId: listId,
                itemId: item.id,
                updates: request
            )
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = updatedItem
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func deleteItem(_ item: ListItem) async {
        guard let frameId = authManager.currentFrameId else { return }

        do {
            try await listsService.deleteItem(frameId: frameId, listId: listId, itemId: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            self.error = error
            self.showError = true
        }
    }
}
