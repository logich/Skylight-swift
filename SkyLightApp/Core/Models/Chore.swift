import Foundation

struct Chore: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let assigneeId: String?
    let assigneeName: String?
    let dueDate: Date?
    let recurrence: String?
    let points: Int?
    let isCompleted: Bool
    let completedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var recurrenceDisplay: String? {
        guard let recurrence = recurrence else { return nil }

        switch recurrence.lowercased() {
        case "daily":
            return "Daily"
        case "weekly":
            return "Weekly"
        case "monthly":
            return "Monthly"
        default:
            return recurrence.capitalized
        }
    }
}

struct ChoresResponse: Codable {
    let chores: [Chore]
}

struct ChoreResponse: Codable {
    let chore: Chore
}
