import Foundation

enum SkylightEndpoint: APIEndpoint {
    // Authentication
    case login(email: String, password: String)
    case getCurrentUser

    // Frames
    case getFrames
    case getFrame(frameId: String)
    case getFrameCategories(frameId: String)
    case getDevices(frameId: String)

    // Calendar
    case getCalendarEvents(frameId: String, dateMin: Date, dateMax: Date, timezone: String)
    case createCalendarEvent(frameId: String, event: CreateCalendarEventRequest)
    case updateCalendarEvent(frameId: String, eventId: String, event: UpdateCalendarEventRequest)
    case deleteCalendarEvent(frameId: String, eventId: String)

    // Chores
    case getChores(frameId: String, after: Date, before: Date, includeLate: Bool)
    case createChore(frameId: String, chore: CreateChoreRequest)
    case updateChore(frameId: String, choreId: String, updates: UpdateChoreRequest)
    case deleteChore(frameId: String, choreId: String)

    // Lists
    case getLists(frameId: String)
    case getListItems(frameId: String, listId: String)
    case createList(frameId: String, list: CreateListRequest)
    case updateList(frameId: String, listId: String, updates: UpdateListRequest)
    case deleteList(frameId: String, listId: String)
    case addListItem(frameId: String, listId: String, item: CreateListItemRequest)
    case updateListItem(frameId: String, listId: String, itemId: String, updates: UpdateListItemRequest)
    case deleteListItem(frameId: String, listId: String, itemId: String)

    // Task Box
    case getTaskBoxItems(frameId: String)
    case createTaskBoxItem(frameId: String, item: CreateTaskBoxItemRequest)

    // Rewards
    case getRewards(frameId: String)
    case getRewardPoints(frameId: String)

    // Resources
    case getAvatars
    case getColors

    var path: String {
        switch self {
        // Auth
        case .login:
            return "/api/sessions"
        case .getCurrentUser:
            return "/api/user"

        // Frames
        case .getFrames:
            return "/api/frames"
        case .getFrame(let frameId):
            return "/api/frames/\(frameId)"
        case .getFrameCategories(let frameId):
            return "/api/frames/\(frameId)/categories"
        case .getDevices(let frameId):
            return "/api/frames/\(frameId)/devices"

        // Calendar
        case .getCalendarEvents(let frameId, _, _, _):
            return "/api/frames/\(frameId)/calendar_events"
        case .createCalendarEvent(let frameId, _):
            return "/api/frames/\(frameId)/calendar_events"
        case .updateCalendarEvent(let frameId, let eventId, _):
            return "/api/frames/\(frameId)/calendar_events/\(eventId)"
        case .deleteCalendarEvent(let frameId, let eventId):
            return "/api/frames/\(frameId)/calendar_events/\(eventId)"

        // Chores
        case .getChores(let frameId, _, _, _):
            return "/api/frames/\(frameId)/chores"
        case .createChore(let frameId, _):
            return "/api/frames/\(frameId)/chores"
        case .updateChore(let frameId, let choreId, _):
            return "/api/frames/\(frameId)/chores/\(choreId)"
        case .deleteChore(let frameId, let choreId):
            return "/api/frames/\(frameId)/chores/\(choreId)"

        // Lists
        case .getLists(let frameId):
            return "/api/frames/\(frameId)/lists"
        case .getListItems(let frameId, let listId):
            return "/api/frames/\(frameId)/lists/\(listId)/list_items"
        case .createList(let frameId, _):
            return "/api/frames/\(frameId)/lists"
        case .updateList(let frameId, let listId, _):
            return "/api/frames/\(frameId)/lists/\(listId)"
        case .deleteList(let frameId, let listId):
            return "/api/frames/\(frameId)/lists/\(listId)"
        case .addListItem(let frameId, let listId, _):
            return "/api/frames/\(frameId)/lists/\(listId)/list_items"
        case .updateListItem(let frameId, let listId, let itemId, _):
            return "/api/frames/\(frameId)/lists/\(listId)/list_items/\(itemId)"
        case .deleteListItem(let frameId, let listId, let itemId):
            return "/api/frames/\(frameId)/lists/\(listId)/list_items/\(itemId)"

        // Task Box
        case .getTaskBoxItems(let frameId):
            return "/api/frames/\(frameId)/task_box_items"
        case .createTaskBoxItem(let frameId, _):
            return "/api/frames/\(frameId)/task_box_items"

        // Rewards
        case .getRewards(let frameId):
            return "/api/frames/\(frameId)/rewards"
        case .getRewardPoints(let frameId):
            return "/api/frames/\(frameId)/reward_points"

        // Resources
        case .getAvatars:
            return "/api/avatars"
        case .getColors:
            return "/api/colors"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .createCalendarEvent, .createChore, .createList, .addListItem, .createTaskBoxItem:
            return .post
        case .updateCalendarEvent, .updateChore, .updateList, .updateListItem:
            return .put
        case .deleteCalendarEvent, .deleteChore, .deleteList, .deleteListItem:
            return .delete
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getCalendarEvents(_, let dateMin, let dateMax, let timezone):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return [
                URLQueryItem(name: "date_min", value: formatter.string(from: dateMin)),
                URLQueryItem(name: "date_max", value: formatter.string(from: dateMax)),
                URLQueryItem(name: "timezone", value: timezone),
                URLQueryItem(name: "include", value: "categories,calendar_account,event_notification_setting")
            ]
        case .getChores(_, let after, let before, let includeLate):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return [
                URLQueryItem(name: "after", value: formatter.string(from: after)),
                URLQueryItem(name: "before", value: formatter.string(from: before)),
                URLQueryItem(name: "include_late", value: includeLate ? "true" : "false")
            ]
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .login(let email, let password):
            let credentials = LoginRequest(email: email, password: password)
            return try? JSONCoders.encoder.encode(credentials)
        case .createCalendarEvent(_, let event):
            return try? JSONCoders.encoder.encode(event)
        case .updateCalendarEvent(_, _, let event):
            return try? JSONCoders.encoder.encode(event)
        case .createChore(_, let chore):
            return try? JSONCoders.encoder.encode(chore)
        case .updateChore(_, _, let updates):
            return try? JSONCoders.encoder.encode(updates)
        case .createList(_, let list):
            return try? JSONCoders.encoder.encode(list)
        case .updateList(_, _, let updates):
            return try? JSONCoders.encoder.encode(updates)
        case .addListItem(_, _, let item):
            return try? JSONCoders.encoder.encode(item)
        case .updateListItem(_, _, _, let updates):
            return try? JSONCoders.encoder.encode(updates)
        case .createTaskBoxItem(_, let item):
            return try? JSONCoders.encoder.encode(item)
        default:
            return nil
        }
    }

    var requiresAuthentication: Bool {
        switch self {
        case .login:
            return false
        default:
            return true
        }
    }
}

// MARK: - Request Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct CreateCalendarEventRequest: Encodable {
    let title: String
    let startDate: Date
    let endDate: Date?
    let allDay: Bool
    let location: String?
    let notes: String?
}

struct UpdateCalendarEventRequest: Encodable {
    let title: String?
    let startDate: Date?
    let endDate: Date?
    let allDay: Bool?
    let location: String?
    let notes: String?
}

struct CreateChoreRequest: Encodable {
    let title: String
    let assigneeId: String?
    let dueDate: Date?
    let recurrence: String?
    let points: Int?
}

struct UpdateChoreRequest: Encodable {
    let title: String?
    let assigneeId: String?
    let dueDate: Date?
    let recurrence: String?
    let points: Int?
    let completed: Bool?
}

struct CreateListRequest: Encodable {
    let name: String
    let listType: String?
}

struct UpdateListRequest: Encodable {
    let name: String?
}

struct CreateListItemRequest: Encodable {
    let title: String
    let quantity: Int?
    let notes: String?
}

struct UpdateListItemRequest: Encodable {
    let title: String?
    let quantity: Int?
    let notes: String?
    let checked: Bool?
}

struct CreateTaskBoxItemRequest: Encodable {
    let title: String
}
