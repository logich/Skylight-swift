import Foundation

struct ShoppingList: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: String?
    let itemCount: Int?
    let createdAt: Date?
    let updatedAt: Date?

    var displayType: String {
        guard let type = type else { return "List" }

        switch type.lowercased() {
        case "shopping":
            return "Shopping List"
        case "todo":
            return "To-Do List"
        case "grocery":
            return "Grocery List"
        default:
            return type.capitalized
        }
    }
}

struct ListsResponse: Codable {
    let lists: [ShoppingList]
}

struct ListItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let quantity: Int?
    let notes: String?
    let isChecked: Bool
    let addedBy: String?
    let addedByName: String?
    let createdAt: Date?
    let updatedAt: Date?

    var displayQuantity: String? {
        guard let quantity = quantity, quantity > 1 else { return nil }
        return "x\(quantity)"
    }
}

struct ListItemsResponse: Codable {
    let items: [ListItem]
}

struct ListItemResponse: Codable {
    let item: ListItem
}
