import Foundation
import SwiftUI

// MARK: - Simple ShoppingList Model
struct ShoppingList: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let kind: String?
    let color: String?

    var displayType: String {
        guard let kind = kind else { return "List" }
        switch kind.lowercased() {
        case "shopping":
            return "Shopping List"
        case "to_do":
            return "To-Do List"
        case "grocery":
            return "Grocery List"
        default:
            return kind.capitalized
        }
    }

    var displayColor: Color {
        guard let colorHex = color else { return .blue }
        return Color(hex: colorHex) ?? .blue
    }
}

// MARK: - JSON:API Lists Response
struct ListsResponse: Codable {
    let data: [ListData]
    let included: [ListIncludedData]?

    var lists: [ShoppingList] {
        data.map { listData in
            ShoppingList(
                id: listData.id,
                name: listData.attributes.label,
                kind: listData.attributes.kind,
                color: listData.attributes.color
            )
        }
    }
}

struct ListData: Codable {
    let id: String
    let type: String
    let attributes: ListAttributes
    let relationships: ListRelationships?
}

struct ListAttributes: Codable {
    let label: String
    let color: String?
    let kind: String?
    let hideOnDevice: Bool?
    let defaultGroceryList: Bool?
}

struct ListRelationships: Codable {
    let listItems: ListItemsRelationship?
}

struct ListItemsRelationship: Codable {
    let data: [ResourceIdentifier]?
}

struct ListIncludedData: Codable {
    let id: String
    let type: String
}

// MARK: - Simple ListItem Model
struct ListItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let quantity: Int?
    let notes: String?
    let isChecked: Bool

    var displayQuantity: String? {
        guard let quantity = quantity, quantity > 1 else { return nil }
        return "x\(quantity)"
    }
}

// MARK: - JSON:API ListItems Response
struct ListItemsResponse: Codable {
    let data: [ListItemData]

    var items: [ListItem] {
        data.map { itemData in
            ListItem(
                id: itemData.id,
                title: itemData.attributes.label ?? itemData.attributes.title ?? "",
                quantity: itemData.attributes.quantity,
                notes: itemData.attributes.notes,
                isChecked: itemData.attributes.checked ?? false
            )
        }
    }
}

struct ListItemData: Codable {
    let id: String
    let type: String
    let attributes: ListItemAttributes
}

struct ListItemAttributes: Codable {
    let label: String?
    let title: String?
    let quantity: Int?
    let notes: String?
    let checked: Bool?
}

// MARK: - Single ListItem Response
struct ListItemResponse: Codable {
    let data: ListItemData

    var item: ListItem {
        ListItem(
            id: data.id,
            title: data.attributes.label ?? data.attributes.title ?? "",
            quantity: data.attributes.quantity,
            notes: data.attributes.notes,
            isChecked: data.attributes.checked ?? false
        )
    }
}
