import Foundation

enum SkylightEndpoint: APIEndpoint {
    // Authentication
    case login(email: String, password: String)
    case refreshToken(refreshToken: String)

    // Frames
    case getFrames
    case getFrame(frameId: String)

    // Calendar
    case getCalendarEvents(frameId: String, startDate: Date, endDate: Date)
    case getCalendarSources(frameId: String)

    // Chores
    case getChores(frameId: String)
    case createChore(frameId: String, chore: CreateChoreRequest)
    case updateChore(frameId: String, choreId: String, updates: UpdateChoreRequest)
    case deleteChore(frameId: String, choreId: String)
    case completeChore(frameId: String, choreId: String)

    // Lists
    case getLists(frameId: String)
    case getListItems(frameId: String, listId: String)
    case addListItem(frameId: String, listId: String, item: CreateListItemRequest)
    case updateListItem(frameId: String, listId: String, itemId: String, updates: UpdateListItemRequest)
    case deleteListItem(frameId: String, listId: String, itemId: String)

    // Tasks
    case getTasks(frameId: String)
    case createTask(frameId: String, task: CreateTaskRequest)

    // Family
    case getFamilyMembers(frameId: String)
    case getDevices(frameId: String)

    var path: String {
        let basePath = "/api/\(Constants.API.apiVersion)"

        switch self {
        case .login:
            return "\(basePath)/auth/login"
        case .refreshToken:
            return "\(basePath)/auth/refresh"
        case .getFrames:
            return "\(basePath)/frames"
        case .getFrame(let frameId):
            return "\(basePath)/frames/\(frameId)"
        case .getCalendarEvents(let frameId, _, _):
            return "\(basePath)/frames/\(frameId)/calendar/events"
        case .getCalendarSources(let frameId):
            return "\(basePath)/frames/\(frameId)/calendar/sources"
        case .getChores(let frameId):
            return "\(basePath)/frames/\(frameId)/chores"
        case .createChore(let frameId, _):
            return "\(basePath)/frames/\(frameId)/chores"
        case .updateChore(let frameId, let choreId, _):
            return "\(basePath)/frames/\(frameId)/chores/\(choreId)"
        case .deleteChore(let frameId, let choreId):
            return "\(basePath)/frames/\(frameId)/chores/\(choreId)"
        case .completeChore(let frameId, let choreId):
            return "\(basePath)/frames/\(frameId)/chores/\(choreId)/complete"
        case .getLists(let frameId):
            return "\(basePath)/frames/\(frameId)/lists"
        case .getListItems(let frameId, let listId):
            return "\(basePath)/frames/\(frameId)/lists/\(listId)/items"
        case .addListItem(let frameId, let listId, _):
            return "\(basePath)/frames/\(frameId)/lists/\(listId)/items"
        case .updateListItem(let frameId, let listId, let itemId, _):
            return "\(basePath)/frames/\(frameId)/lists/\(listId)/items/\(itemId)"
        case .deleteListItem(let frameId, let listId, let itemId):
            return "\(basePath)/frames/\(frameId)/lists/\(listId)/items/\(itemId)"
        case .getTasks(let frameId):
            return "\(basePath)/frames/\(frameId)/tasks"
        case .createTask(let frameId, _):
            return "\(basePath)/frames/\(frameId)/tasks"
        case .getFamilyMembers(let frameId):
            return "\(basePath)/frames/\(frameId)/family/members"
        case .getDevices(let frameId):
            return "\(basePath)/frames/\(frameId)/devices"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .refreshToken, .createChore, .addListItem, .createTask, .completeChore:
            return .post
        case .updateChore, .updateListItem:
            return .patch
        case .deleteChore, .deleteListItem:
            return .delete
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getCalendarEvents(_, let startDate, let endDate):
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return [
                URLQueryItem(name: "start_date", value: formatter.string(from: startDate)),
                URLQueryItem(name: "end_date", value: formatter.string(from: endDate))
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
        case .refreshToken(let refreshToken):
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            return try? JSONCoders.encoder.encode(request)
        case .createChore(_, let chore):
            return try? JSONCoders.encoder.encode(chore)
        case .updateChore(_, _, let updates):
            return try? JSONCoders.encoder.encode(updates)
        case .addListItem(_, _, let item):
            return try? JSONCoders.encoder.encode(item)
        case .updateListItem(_, _, _, let updates):
            return try? JSONCoders.encoder.encode(updates)
        case .createTask(_, let task):
            return try? JSONCoders.encoder.encode(task)
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

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
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
    let isCompleted: Bool?
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
    let isChecked: Bool?
}

struct CreateTaskRequest: Encodable {
    let title: String
    let description: String?
    let assigneeId: String?
    let dueDate: Date?
}
