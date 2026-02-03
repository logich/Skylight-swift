# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Skylight-swift is an unofficial native iOS app for Skylight Calendar, built with SwiftUI. This uses a reverse-engineered API and is not affiliated with Skylight. The app focuses on calendar viewing with drive time calculations, time-to-leave notifications, and a home screen widget.

**Requirements:**
- iOS 18.0+
- Xcode 15.0+
- macOS 13.0+ (for development)

**Key Technologies:**
- SwiftUI for UI
- MVVM architecture pattern
- Async/await for networking
- WidgetKit for home screen widget
- App Intents for Shortcuts automation
- BackgroundTasks framework for periodic sync
- Keychain for secure credential storage
- App Groups (`group.com.rosetrace.SkylightApp`) for data sharing between app and widget

## Xcode MCP Tools (Preferred)

This project has Xcode MCP (Model Context Protocol) tools available. **Always prefer using MCP tools over xcodebuild commands** as they provide better integration, error handling, and feedback.

### Available MCP Tools
- **xcode_build** - Build the project (preferred over `xcodebuild build`)
- **xcode_test** - Run tests (preferred over `xcodebuild test`)
- **xcode_clean** - Clean build folder (preferred over `xcodebuild clean`)
- **xcode_get_build_settings** - Retrieve build settings
- **xcode_get_build_errors** - Get current build errors and warnings
- **xcode_run_app** - Build and run the app in simulator
- **xcode_stop_app** - Stop a running app
- **xcode_list_simulators** - List available iOS simulators
- **xcode_boot_simulator** - Boot a specific simulator
- **xcode_open_file** - Open a file in Xcode at a specific line

### When to Use MCP Tools
- Building the app: Use `xcode_build` instead of xcodebuild
- Running tests: Use `xcode_test` instead of xcodebuild test
- Checking errors: Use `xcode_get_build_errors` for quick diagnostics
- Running app: Use `xcode_run_app` for build + launch in one step

## Build Commands (Fallback)

Use these xcodebuild commands only if MCP tools are unavailable.

### Building the App
```bash
# Build for simulator
xcodebuild -project SkylightApp/SkylightApp.xcodeproj -scheme SkylightApp -sdk iphonesimulator -configuration Debug build

# Build for device
xcodebuild -project SkylightApp/SkylightApp.xcodeproj -scheme SkylightApp -sdk iphoneos -configuration Debug build

# Clean build folder
xcodebuild -project SkylightApp/SkylightApp.xcodeproj -scheme SkylightApp clean
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project SkylightApp/SkylightApp.xcodeproj -scheme SkylightApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test class
xcodebuild test -project SkylightApp/SkylightApp.xcodeproj -scheme SkylightApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:SkylightAppTests/CalendarViewModelTests

# Run single test method
xcodebuild test -project SkylightApp/SkylightApp.xcodeproj -scheme SkylightApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:SkylightAppTests/CalendarViewModelTests/testLoadEventsSuccessfully
```

**Note:** Tests can also be run in Xcode with Cmd+U or by clicking the diamond icons next to test functions.

## Architecture

### MVVM Pattern
The codebase follows strict MVVM separation:
- **Views (SwiftUI)**: Pure presentation, no business logic
- **ViewModels (@MainActor ObservableObject)**: State management, orchestration, published properties
- **Services (Protocol-based)**: API calls and business logic
- **Models (Codable)**: Data structures matching API responses

Example flow:
```
View → ViewModel → Service → APIClient → Skylight API
                      ↓
                   Models
```

### Key Architectural Components

**Authentication Flow:**
1. User logs in via `LoginViewModel`
2. `AuthenticationManager` (singleton) stores token in Keychain and manages auth state
3. Auth state machine: `.unauthenticated` → `.authenticated` → `.frameSelected`
4. `ContentView` conditionally renders: LoginView → FrameSelectionView → CalendarView (main app)

**Calendar & Drive Time Feature:**
1. `CalendarViewModel` loads events from `CalendarService`
2. Events cached with 60-minute expiration
3. `DriveTimeManager` processes upcoming events to calculate "time to leave"
4. Drive times cached for 30 minutes per location
5. Results saved to `SharedDataManager` (App Groups) for widget access
6. `NotificationService` schedules time-to-leave alerts
7. Widget automatically refreshes to show "Leave Now" state

**Background Sync:**
- `BackgroundTaskManager` registers `BGAppRefreshTask`
- Scheduled when app backgrounds (15-minute minimum interval)
- Fetches 7 days of calendar events in background
- Updates widget data and schedules notifications

**Widget Architecture:**
- Separate target: `SkylightWidgetExtension`
- Reads shared data from App Groups (UserDefaults suite)
- Shows upcoming events and "Leave Now" alerts
- Refreshed by `SharedDataManager` after calendar updates

**App Intents / Shortcuts Integration:**
- `CalendarIntents.swift` provides 7 App Intents for Shortcuts automation
- Intents include: Get Today's Events, Get Events for Date, Get Upcoming Events, Get Next Event, Get Events Starting Soon, Check If Event Starting Soon, Get Minutes Until Next Event
- Enables automations like "Start car climate control if event starting in 30 minutes"
- Voice phrases registered for Siri integration
- All intents use `IntentCalendarHelper` to fetch data via `CalendarService`

### Dependency Injection Pattern

All services use protocol-based injection for testability:

```swift
// Service protocol
protocol CalendarServiceProtocol {
    func getEvents(from: Date, to: Date) async throws -> [CalendarEvent]
}

// ViewModel with injected dependency
class CalendarViewModel: ObservableObject {
    private let calendarService: CalendarServiceProtocol

    init(calendarService: CalendarServiceProtocol = CalendarService()) {
        self.calendarService = calendarService
    }
}
```

This allows mocking in tests: `CalendarViewModel(calendarService: MockCalendarService())`

### Caching Strategy

**CalendarViewModel Event Cache:**
- Stores events by date range with 60-minute expiration
- Smart range containment: if requesting Jan 1-3 and cache has Jan 1-7, reuse cached data
- Reduces API calls when navigating calendar views

**DriveTimeManager Location Cache:**
- Caches drive time calculations per location for 30 minutes
- Avoids redundant routing API calls for same destination
- Cleared when location changes significantly

### API Structure

**Skylight API uses JSON:API format:**
- All endpoints defined in `SkylightEndpoint.swift`
- Responses include `data` and `included` relationships
- `CalendarEvent` model handles parsing relationships (categories → attendees)
- Authentication via Bearer token (stored in Keychain)

Base URL: `https://api.ourskylight.com`

Key endpoints:
- `POST /auth/login` - Authentication
- `GET /frames/:id/calendar-events` - Fetch calendar events
- `POST /frames/:id/calendar-events` - Create event
- `GET /frames/:id/family-categories` - Get family members
- `GET /frames` - List user's frames (households)

## File Organization

```
SkylightApp/
├── SkylightApp/                    # Main iOS app target
│   ├── App/                        # Entry point, app lifecycle, navigation
│   │   ├── SkyLightApp.swift       # @main, background task registration
│   │   ├── ContentView.swift       # Root view with auth routing
│   │   ├── BackgroundTaskManager.swift
│   │   ├── DeepLinkManager.swift
│   │   └── AppIntents/             # Shortcuts integration
│   │       └── CalendarIntents.swift
│   │
│   ├── Core/                       # Foundation layers
│   │   ├── Network/                # HTTP client, endpoints, errors
│   │   ├── Authentication/         # AuthenticationManager, KeychainManager
│   │   └── Models/                 # CalendarEvent, User, Frame, etc.
│   │
│   ├── Features/                   # Feature modules (MVVM organized)
│   │   ├── Authentication/         # LoginViewModel, LoginView, FrameSelectionView
│   │   ├── Calendar/               # CalendarViewModel, CalendarView, CreateEventView, LocationSearchView
│   │   └── Settings/               # SettingsView (buffer time, notifications toggle)
│   │
│   ├── Services/                   # Business logic services
│   │   ├── CalendarService.swift
│   │   ├── LocationService.swift
│   │   ├── DriveTimeManager.swift
│   │   ├── NotificationService.swift
│   │   ├── FamilyService.swift
│   │   └── SharedDataManager.swift # App Group data bridge
│   │
│   └── Utilities/                  # Extensions, helpers, constants
│
├── SkylightAppTests/               # Unit and integration tests
│   ├── Mocks/                      # Mock implementations of protocols
│   │   ├── MockAPIClient.swift
│   │   ├── MockCalendarService.swift
│   │   └── TestDataFactory.swift   # Test data builders
│   ├── ViewModels/                 # ViewModel tests
│   ├── Services/                   # Service tests
│   └── Integration/                # Integration tests
│
└── SkylightWidget/                 # Home screen widget target
    └── SkylightWidget.swift        # Widget entry point
```

## Important Patterns & Conventions

### State Management
- ViewModels use `@Published` properties for reactive updates
- All ViewModels marked with `@MainActor` for thread safety
- Singleton `AuthenticationManager` for app-wide auth state
- No global state beyond AuthenticationManager

### Error Handling
- `APIError` enum for typed API errors
- ViewModels expose `@Published var error: Error?` for UI display
- Async/await with try-catch throughout
- User-facing error messages via `localizedDescription`

### Testing Approach
- Protocol-based mocks (MockAPIClient, MockCalendarService)
- `TestDataFactory` for reusable test data
- Isolated UserDefaults suite for state testing
- @MainActor test functions for async ViewModel tests

### Date Handling
- All dates use ISO8601 format for API communication
- Custom `JSONCoders.swift` configures DateFormatter
- `Date+Extensions.swift` provides calendar utilities (startOfDay, endOfDay, etc.)

### Widget Data Sharing
- App Groups identifier: `group.com.rosetrace.SkylightApp` (defined in `SharedConstants.swift`)
- `SharedDataManager` manages UserDefaults suite with shared container
- `WidgetEvent` model: simplified version of `CalendarEvent` for widget
- Widget refresh triggered via `WidgetCenter.shared.reloadAllTimelines()`
- Shared data includes: upcoming events, drive times, buffer time settings, alert toggles

## Common Development Workflows

### Adding a New API Endpoint
1. Add endpoint case to `SkylightEndpoint` enum in `Core/Network/SkylightEndpoint.swift`
2. Implement `path`, `method`, `body`, `queryItems` for the endpoint
3. Create/update model in `Core/Models/` to match JSON:API response
4. Add service method in appropriate service (e.g., `Services/CalendarService.swift`)
5. Call service method from ViewModel
6. Add tests in `SkylightAppTests/Services/`

### Adding a New Feature
1. Create feature folder in `Features/` with `ViewModels/` and `Views/` subdirectories
2. Create ViewModel conforming to `ObservableObject`, marked with `@MainActor`
3. Inject dependencies via initializer with default implementations
4. Create SwiftUI views that observe ViewModel
5. Add service protocol if new API interactions needed
6. Add mock implementations in `SkylightAppTests/Mocks/`
7. Write ViewModel tests

### Modifying Calendar Functionality
- Calendar is the primary feature; changes likely affect multiple components
- Update `CalendarEvent` model if API response structure changes
- `CalendarViewModel` handles event loading, caching, and search
- `DriveTimeManager` processes events for "time to leave" feature
- Changes may require updating widget via `SharedDataManager`
- Test caching behavior to avoid regressions

### Working with Background Tasks
- Background refresh handled by `BackgroundTaskManager`
- Registered in `SkyLightApp.swift` on app launch
- Must complete within ~30 seconds
- Updates calendar data and widget
- Test using `xcode_run_app` MCP tool then Xcode debug menu: Debug → Simulate Background Fetch

### Adding or Modifying App Intents (Shortcuts)
- All intents defined in `App/AppIntents/CalendarIntents.swift`
- Create new `AppIntent` struct conforming to `AppIntent` protocol
- Use `IntentCalendarHelper` static methods to fetch calendar data
- Add `AppShortcut` to `SkylightShortcuts.appShortcuts` array for Siri phrases
- Test intents in Shortcuts app or by asking Siri
- Intents run in app process and require user to be logged in

## Special Considerations

**Calendar-Focused App:**
The app is currently focused solely on calendar functionality. Previous features (Chores, Lists, Family management) have been removed. The main flow is: Login → Frame Selection → Calendar View with Settings accessible from toolbar.

**API Rate Limiting:**
The unofficial Skylight API may have undocumented rate limits. Caching strategies are critical to minimize API calls.

**Multi-Household Support:**
Users can have multiple Skylight frames (households). Frame selection persisted via UserDefaults. All API calls include selected frame ID.

**JSON:API Parsing:**
Skylight uses JSON:API format with `data` and `included` sections. Models must parse relationships correctly (see `CalendarEvent.init(from:)` for example).

**Thread Safety:**
All ViewModels must be marked `@MainActor` since they update UI-bound properties. Service calls use `async/await` and are thread-safe.

**Keychain Access:**
`KeychainManager` handles all Keychain operations. Never store tokens in UserDefaults. Use protocols for testing (MockKeychainManager).

**Widget Limitations:**
Widgets have memory and execution time limits. `WidgetEvent` is a simplified model. Complex processing done in main app, not widget.

**Shortcuts Automation Use Cases:**
The App Intents enable powerful automations:
- Trigger car climate control when event starts in 30 minutes
- Set home scene based on upcoming events
- Voice queries like "What's next on Skylight?"
- Conditional logic: "IF event starting soon THEN run automation"
- All intents require user to be logged in with frame selected

## Testing Notes

- Run tests before committing changes using `xcode_test` MCP tool (preferred) or xcodebuild
- Use `xcode_get_build_errors` to quickly check for build issues
- Mock all network dependencies in tests
- Use `TestDataFactory` for consistent test data
- Test ViewModel state transitions (loading → success/error)
- Test caching behavior and expiration
- Integration tests in `SkylightAppTests/Integration/`
- Performance tests for expensive operations (caching, parsing)

## Disclaimer Context

This app uses a reverse-engineered API. When modifying API interactions:
- Changes may break without notice if Skylight updates their API
- Always handle errors gracefully for better user experience
- Consider backward compatibility where possible
- Document API assumptions in code comments
