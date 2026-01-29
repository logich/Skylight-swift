import Foundation

// MARK: - Simple Chore Model
struct Chore: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let categoryId: String?
    let categoryColor: String?
    let categoryLabel: String?
    let points: Int?
    let isCompleted: Bool
    let completedAt: Date?
    let isRecurring: Bool

    var isOverdue: Bool {
        // Chores from API don't have due dates in the same way
        false
    }

    var isDueToday: Bool {
        // Could be enhanced based on API data
        false
    }

    var dueDate: Date? {
        nil
    }
}

// MARK: - JSON:API Chores Response
struct ChoresResponse: Codable {
    let data: [ChoreData]
    let included: [ChoreIncludedData]?

    var chores: [Chore] {
        // Build category lookup
        var categoryColors: [String: String] = [:]
        var categoryLabels: [String: String] = [:]
        if let included = included {
            for item in included where item.type == "category" {
                if let color = item.attributes?.color {
                    categoryColors[item.id] = color
                }
                if let label = item.attributes?.label {
                    categoryLabels[item.id] = label
                }
            }
        }

        return data.map { choreData in
            let categoryId = choreData.relationships?.category?.data?.id
            let categoryColor = categoryId.flatMap { categoryColors[$0] }
            let categoryLabel = categoryId.flatMap { categoryLabels[$0] }

            return Chore(
                id: choreData.id,
                title: choreData.attributes.summary,
                categoryId: categoryId,
                categoryColor: categoryColor,
                categoryLabel: categoryLabel,
                points: choreData.attributes.rewardPoints,
                isCompleted: choreData.attributes.status == "completed",
                completedAt: choreData.attributes.completedOn,
                isRecurring: choreData.attributes.recurring ?? false
            )
        }
    }
}

struct ChoreData: Codable {
    let id: String
    let type: String
    let attributes: ChoreAttributes
    let relationships: ChoreRelationships?
}

struct ChoreAttributes: Codable {
    let summary: String
    let status: String?
    let rewardPoints: Int?
    let completedOn: Date?
    let recurring: Bool?
    let routine: Bool?
    let position: Int?
}

struct ChoreRelationships: Codable {
    let category: ChoreCategoryRelationship?
}

struct ChoreCategoryRelationship: Codable {
    let data: ResourceIdentifier?
}

struct ChoreIncludedData: Codable {
    let id: String
    let type: String
    let attributes: ChoreIncludedAttributes?
}

struct ChoreIncludedAttributes: Codable {
    let color: String?
    let label: String?
}

// MARK: - Single Chore Response
struct ChoreResponse: Codable {
    let data: ChoreData
    let included: [ChoreIncludedData]?

    var chore: Chore {
        var categoryColors: [String: String] = [:]
        var categoryLabels: [String: String] = [:]
        if let included = included {
            for item in included where item.type == "category" {
                if let color = item.attributes?.color {
                    categoryColors[item.id] = color
                }
                if let label = item.attributes?.label {
                    categoryLabels[item.id] = label
                }
            }
        }

        let categoryId = data.relationships?.category?.data?.id
        let categoryColor = categoryId.flatMap { categoryColors[$0] }
        let categoryLabel = categoryId.flatMap { categoryLabels[$0] }

        return Chore(
            id: data.id,
            title: data.attributes.summary,
            categoryId: categoryId,
            categoryColor: categoryColor,
            categoryLabel: categoryLabel,
            points: data.attributes.rewardPoints,
            isCompleted: data.attributes.status == "completed",
            completedAt: data.attributes.completedOn,
            isRecurring: data.attributes.recurring ?? false
        )
    }
}
