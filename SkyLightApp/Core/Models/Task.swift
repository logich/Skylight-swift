import Foundation

struct SkylightTask: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let priority: String?
    let createdBy: String?
    let createdByName: String?
    let createdAt: Date?
    let status: String?

    var priorityLevel: Priority {
        guard let priority = priority else { return .medium }
        return Priority(rawValue: priority.lowercased()) ?? .medium
    }

    enum Priority: String, Codable, CaseIterable {
        case low
        case medium
        case high

        var displayName: String {
            rawValue.capitalized
        }
    }
}

struct TasksResponse: Codable {
    let tasks: [SkylightTask]
}

struct TaskResponse: Codable {
    let task: SkylightTask
}
