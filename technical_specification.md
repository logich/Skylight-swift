# Skylight iOS App - Technical Specification

## 1. System Architecture

### 1.1 Architecture Pattern
**MVVM (Model-View-ViewModel)** with SwiftUI

**Rationale**:
- Natural fit with SwiftUI's declarative approach
- Clear separation of concerns
- Testable business logic
- Reactive data binding via Combine

### 1.2 Layer Structure

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│         (SwiftUI Views)             │
└─────────────────────────────────────┘
                 ↓↑
┌─────────────────────────────────────┐
│        ViewModel Layer              │
│     (Business Logic + State)        │
└─────────────────────────────────────┘
                 ↓↑
┌─────────────────────────────────────┐
│         Service Layer               │
│      (API Abstraction)              │
└─────────────────────────────────────┘
                 ↓↑
┌─────────────────────────────────────┐
│         Network Layer               │
│      (HTTP Client)                  │
└─────────────────────────────────────┘
                 ↓↑
┌─────────────────────────────────────┐
│      Data/Storage Layer             │
│   (Keychain, UserDefaults, Cache)   │
└─────────────────────────────────────┘
```

## 2. Core Components Specification

### 2.1 Network Layer

#### APIClient.swift
```swift
/// Base HTTP client for all API requests
protocol APIClient {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
}

/// Concrete implementation
class SkylightAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let authManager: AuthenticationManager
    
    // Implementation details
}
```

**Requirements**:
- Async/await for all requests
- Automatic token injection via AuthenticationManager
- Request/response logging (debug builds only)
- Proper error propagation
- Timeout handling (30 seconds default)
- Retry logic for transient failures (3 attempts)

#### APIEndpoint.swift
```swift
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
```

**Endpoints to Implement**:
```swift
enum SkylightEndpoint: APIEndpoint {
    // Authentication
    case login(email: String, password: String)
    case refreshToken
    
    // Frames
    case getFrames
    case getFrameInfo(frameId: String)
    
    // Calendar
    case getCalendarEvents(frameId: String, startDate: Date, endDate: Date)
    case getSourceCalendars(frameId: String)
    
    // Chores
    case getChores(frameId: String, filters: ChoreFilters?)
    case createChore(frameId: String, chore: ChoreRequest)
    case updateChore(frameId: String, choreId: String, updates: ChoreUpdate)
    case deleteChore(frameId: String, choreId: String)
    
    // Lists
    case getLists(frameId: String)
    case getListItems(frameId: String, listId: String)
    case addListItem(frameId: String, listId: String, item: ListItemRequest)
    case updateListItem(frameId: String, listId: String, itemId: String, updates: ListItemUpdate)
    
    // Tasks
    case createTask(frameId: String, task: TaskRequest)
    case getTasks(frameId: String)
    
    // Family
    case getFamilyMembers(frameId: String)
    case getDevices(frameId: String)
    
    // Rewards (Plus subscription)
    case getRewards(frameId: String)
    case getRewardPoints(frameId: String)
}
```

#### APIError.swift
```swift
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case httpError(statusCode: Int, message: String?)
    case unauthorized
    case serverError
    case rateLimitExceeded
    case notFound
    case unknown
    
    var errorDescription: String? {
        // User-friendly error messages
    }
    
    var recoverySuggestion: String? {
        // Suggestions for resolving the error
    }
}
```

### 2.2 Authentication Layer

#### AuthenticationManager.swift
```swift
@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentFrameId: String?
    @Published var authState: AuthState = .notAuthenticated
    
    private let keychainManager: KeychainManager
    private let apiClient: APIClient
    
    enum AuthState {
        case notAuthenticated
        case authenticating
        case authenticated
        case frameSelectionRequired
        case error(Error)
    }
    
    func login(email: String, password: String) async throws {
        // 1. Call login endpoint
        // 2. Store credentials in keychain
        // 3. Retrieve and store auth token
        // 4. Get available frames
        // 5. If single frame, auto-select; otherwise show selection
    }
    
    func logout() async {
        // Clear keychain, reset state
    }
    
    func selectFrame(_ frameId: String) {
        // Store selected frame
    }
    
    func refreshAuthToken() async throws {
        // Token refresh logic
    }
    
    var authToken: String? {
        // Retrieve from keychain
    }
}
```

#### KeychainManager.swift
```swift
class KeychainManager {
    enum KeychainKey: String {
        case email
        case password
        case authToken
        case refreshToken
        case frameId
    }
    
    func save(_ value: String, for key: KeychainKey) throws
    func retrieve(key: KeychainKey) throws -> String?
    func delete(key: KeychainKey) throws
    func clearAll() throws
}
```

**Security Requirements**:
- Use kSecAttrAccessibleWhenUnlockedThisDeviceOnly
- Enable data protection
- No credentials in UserDefaults
- Clear sensitive data on logout

### 2.3 Data Models

#### Core Models
```swift
// Calendar
struct CalendarEvent: Codable, Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
    let location: String?
    let description: String?
    let source: CalendarSource?
    let attendees: [String]?
    let color: String?
}

struct CalendarSource: Codable {
    let id: String
    let name: String
    let type: SourceType // google, icloud, etc.
}

// Chores
struct Chore: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let assignedTo: String? // Family member ID
    let dueDate: Date?
    let isCompleted: Bool
    let completedDate: Date?
    let recurrence: RecurrenceRule?
    let points: Int?
    let createdAt: Date
    let updatedAt: Date
}

struct RecurrenceRule: Codable {
    let frequency: Frequency
    let interval: Int
    let daysOfWeek: [DayOfWeek]?
    let endDate: Date?
    let occurrences: Int?
    
    enum Frequency: String, Codable {
        case daily, weekly, monthly, yearly
    }
}

struct ChoreFilters: Codable {
    let assignedTo: String?
    let startDate: Date?
    let endDate: Date?
    let status: ChoreStatus?
    
    enum ChoreStatus: String, Codable {
        case pending, completed, overdue
    }
}

// Lists
struct ShoppingList: Codable, Identifiable {
    let id: String
    let name: String
    let type: ListType
    let items: [ListItem]
    let itemCount: Int
    let createdAt: Date
    
    enum ListType: String, Codable {
        case grocery, todo, custom
    }
}

struct ListItem: Codable, Identifiable {
    let id: String
    let title: String
    let isChecked: Bool
    let quantity: String?
    let notes: String?
    let addedBy: String? // Family member ID
    let addedAt: Date
}

// Tasks
struct Task: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let createdBy: String? // Family member ID
    let createdAt: Date
    let priority: Priority?
    
    enum Priority: String, Codable {
        case low, medium, high
    }
}

// Family
struct FamilyMember: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let role: Role
    let avatarURL: String?
    let rewardPoints: Int?
    let isAdmin: Bool
    
    enum Role: String, Codable {
        case parent, child, other
    }
}

struct Frame: Codable, Identifiable {
    let id: String
    let name: String
    let timezone: String
    let createdAt: Date
    let memberCount: Int
    let deviceCount: Int
}

struct Device: Codable, Identifiable {
    let id: String
    let name: String
    let type: DeviceType
    let status: DeviceStatus
    
    enum DeviceType: String, Codable {
        case calendar, frame
    }
    
    enum DeviceStatus: String, Codable {
        case online, offline
    }
}

// Rewards
struct Reward: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let pointCost: Int
    let imageURL: String?
    let isAvailable: Bool
}
```

### 2.4 Service Layer

#### CalendarService.swift
```swift
protocol CalendarServiceProtocol {
    func getEvents(frameId: String, from startDate: Date, to endDate: Date) async throws -> [CalendarEvent]
    func getSourceCalendars(frameId: String) async throws -> [CalendarSource]
}

class CalendarService: CalendarServiceProtocol {
    private let apiClient: APIClient
    
    // Implementation using APIClient
}
```

#### ChoresService.swift
```swift
protocol ChoresServiceProtocol {
    func getChores(frameId: String, filters: ChoreFilters?) async throws -> [Chore]
    func createChore(frameId: String, chore: ChoreRequest) async throws -> Chore
    func updateChore(frameId: String, choreId: String, updates: ChoreUpdate) async throws -> Chore
    func deleteChore(frameId: String, choreId: String) async throws
    func markComplete(frameId: String, choreId: String) async throws -> Chore
}

class ChoresService: ChoresServiceProtocol {
    private let apiClient: APIClient
    
    // Implementation
}
```

Similar service protocols for:
- ListsService
- TasksService
- FamilyService
- RewardsService

### 2.5 ViewModels

#### Base ViewModel
```swift
@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false
    
    func handleError(_ error: Error) {
        self.error = error
        self.showError = true
        // Log error
    }
}
```

#### CalendarViewModel.swift
```swift
@MainActor
class CalendarViewModel: BaseViewModel {
    @Published var events: [CalendarEvent] = []
    @Published var selectedDate: Date = Date()
    @Published var displayMode: DisplayMode = .month
    
    private let calendarService: CalendarServiceProtocol
    private let authManager: AuthenticationManager
    
    enum DisplayMode {
        case day, week, month
    }
    
    func loadEvents() async {
        guard let frameId = authManager.currentFrameId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (start, end) = dateRangeForMode()
            events = try await calendarService.getEvents(
                frameId: frameId,
                from: start,
                to: end
            )
        } catch {
            handleError(error)
        }
    }
    
    func changeDate(_ date: Date) {
        selectedDate = date
        Task { await loadEvents() }
    }
    
    private func dateRangeForMode() -> (Date, Date) {
        // Calculate based on displayMode and selectedDate
    }
}
```

#### ChoresViewModel.swift
```swift
@MainActor
class ChoresViewModel: BaseViewModel {
    @Published var chores: [Chore] = []
    @Published var filterAssignee: String?
    @Published var filterStatus: ChoreFilters.ChoreStatus?
    @Published var showCreateSheet: Bool = false
    
    private let choresService: ChoresServiceProtocol
    private let authManager: AuthenticationManager
    
    func loadChores() async {
        guard let frameId = authManager.currentFrameId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let filters = ChoreFilters(
                assignedTo: filterAssignee,
                startDate: nil,
                endDate: nil,
                status: filterStatus
            )
            chores = try await choresService.getChores(frameId: frameId, filters: filters)
        } catch {
            handleError(error)
        }
    }
    
    func createChore(_ chore: ChoreRequest) async {
        guard let frameId = authManager.currentFrameId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let newChore = try await choresService.createChore(frameId: frameId, chore: chore)
            chores.append(newChore)
            showCreateSheet = false
        } catch {
            handleError(error)
        }
    }
    
    func markComplete(choreId: String) async {
        guard let frameId = authManager.currentFrameId else { return }
        
        do {
            let updated = try await choresService.markComplete(frameId: frameId, choreId: choreId)
            if let index = chores.firstIndex(where: { $0.id == choreId }) {
                chores[index] = updated
            }
        } catch {
            handleError(error)
        }
    }
}
```

Similar ViewModels for:
- ListsViewModel
- TasksViewModel
- FamilyViewModel

## 3. Data Flow

### 3.1 Authentication Flow
```
1. User enters credentials
   ↓
2. LoginView → AuthenticationViewModel.login()
   ↓
3. AuthenticationViewModel → AuthenticationManager.login()
   ↓
4. AuthenticationManager → APIClient (login endpoint)
   ↓
5. Store token in Keychain
   ↓
6. Fetch available frames
   ↓
7. If single frame: auto-select and proceed
   If multiple: show FrameSelectionView
   ↓
8. Navigate to main app (TabView)
```

### 3.2 Data Loading Flow
```
1. View appears
   ↓
2. View calls ViewModel.load() in .task modifier
   ↓
3. ViewModel → Service.fetch()
   ↓
4. Service → APIClient.request()
   ↓
5. APIClient: Inject auth token from AuthManager
   ↓
6. Make HTTP request
   ↓
7. Parse response
   ↓
8. Return to Service → ViewModel
   ↓
9. ViewModel updates @Published property
   ↓
10. SwiftUI re-renders View
```

### 3.3 Error Handling Flow
```
1. Error occurs at any layer
   ↓
2. Throw as APIError
   ↓
3. Catch in ViewModel
   ↓
4. ViewModel.handleError()
   ↓
5. Set @Published error properties
   ↓
6. View shows alert/banner
   ↓
7. Special case: 401 Unauthorized
   → Trigger logout/reauth flow
```

## 4. State Management

### 4.1 App-Level State
Managed by `AuthenticationManager`:
- Authentication status
- Current user
- Selected frame ID
- Auth tokens

### 4.2 Feature-Level State
Managed by individual ViewModels:
- Data for that feature
- Loading states
- Error states
- UI state (selected items, filters, etc.)

### 4.3 View-Level State
Managed by SwiftUI @State:
- Local UI state
- Form inputs
- Sheet/navigation presentation

## 5. Networking Specifications

### 5.1 Base Configuration
```swift
let baseURL = "https://api.ourskylight.com"
let timeout: TimeInterval = 30
let retryAttempts = 3
```

### 5.2 Request Headers
```swift
let defaultHeaders = [
    "Content-Type": "application/json",
    "Accept": "application/json",
    "User-Agent": "SkyLight-iOS/1.0"
]

// Add for authenticated requests:
"Authorization": "Bearer \(token)"
```

### 5.3 Request/Response Format
All requests and responses use JSON.

Date format: ISO 8601
```swift
let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()
```

### 5.4 Error Response Format
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {}
  }
}
```

## 6. Caching Strategy

### 6.1 UserDefaults
Use for:
- Selected frame ID
- User preferences
- Last sync timestamp
- App settings

### 6.2 In-Memory Cache
Use for:
- Current session data
- Recently accessed items
- Family member info (rarely changes)

### 6.3 Disk Cache (Future)
Consider for offline support:
- CoreData or Realm
- Cache calendar events
- Cache chores
- Cache lists
- Sync strategy on relaunch

## 7. Testing Strategy

### 7.1 Unit Tests
- Test all ViewModels
- Test all Services
- Test APIClient
- Mock APIClient for ViewModel tests
- Mock Services for ViewModel tests

### 7.2 Integration Tests
- Test AuthenticationManager flow
- Test API request/response parsing
- Test error handling paths

### 7.3 UI Tests
- Test critical user flows
- Login flow
- Creating a chore
- Viewing calendar events

## 8. Performance Requirements

- App launch: < 3 seconds to first screen
- API response handling: < 100ms to update UI
- List scrolling: 60 FPS
- Memory usage: < 100MB during normal operation
- Network requests: Use URLSession's built-in caching

## 9. Accessibility Requirements

- Support VoiceOver
- Support Dynamic Type
- Minimum contrast ratios (WCAG AA)
- Meaningful accessibility labels
- Grouped related elements
- Support for reduced motion

## 10. Security Requirements

- HTTPS only (App Transport Security)
- Certificate pinning (optional)
- Keychain for sensitive data
- No hardcoded secrets
- Secure token refresh
- Automatic logout after 30 days inactive
- Clear sensitive data on logout

## 11. Build Configuration

### 11.1 Debug Build
- Enable verbose logging
- Use Charles/Proxyman for debugging
- Fast build times
- Crash reporting disabled

### 11.2 Release Build
- Disable all logging
- Enable optimizations
- Strip debug symbols
- Enable crash reporting
- Code signing for distribution

## 12. Dependencies

Prefer native frameworks when possible.

### Required
- Foundation
- SwiftUI
- Combine

### Optional (evaluate during development)
- Alamofire (if URLSession insufficient)
- KeychainAccess (wrapper for easier Keychain use)
- SwiftDate (date manipulation)

### Testing
- XCTest
- OCMock or similar for mocking

## 13. API Rate Limiting

Since rate limits are unknown:
- Implement exponential backoff on errors
- Cache aggressively
- Batch requests where possible
- Don't auto-refresh more than once per minute
- Detect 429 responses and back off

## 14. Logging Strategy

### 14.1 Debug Logging
```swift
#if DEBUG
print("🌐 API Request: \(request)")
print("✅ API Response: \(response)")
print("❌ Error: \(error)")
#endif
```

### 14.2 Production Logging
- Use OSLog for system integration
- Log errors only
- No sensitive data in logs
- Structured logging format

## 15. Code Style Guidelines

- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Document public APIs
- Use meaningful variable names
- Prefer composition over inheritance
- Keep functions small and focused
- Use extensions to organize code
- Prefer value types (struct) when possible
