# Skylight iOS App - Getting Started with Claude Code

## Quick Start Guide

This document provides a quick reference for getting started with the Skylight iOS app development using Claude Code. All detailed information is available in the supporting documents.

## 📚 Document Index

1. **project_overview.md** - High-level project goals, structure, and context
2. **technical_specification.md** - Detailed technical requirements and architecture
3. **api_integration_guide.md** - Complete API endpoint documentation with examples
4. **implementation_roadmap.md** - Step-by-step development plan
5. **skylight_api_resources.md** - Background on existing tools and API

## 🎯 Project Summary

**Goal**: Build a native iOS app that connects to Skylight Calendar API

**Key Features**:
- Calendar event viewing
- Chores management (view, create, complete)
- Shopping/to-do lists
- Task creation
- Family member viewing
- Reward tracking

**Tech Stack**:
- Swift 5.9+
- SwiftUI
- MVVM Architecture
- iOS 16.0+
- Native URLSession networking
- Keychain for secure storage

## 🚀 For Claude Code: Getting Started

### Step 1: Review Context
Before starting, review these documents in order:
1. Read `project_overview.md` for project context
2. Review `technical_specification.md` for architecture details
3. Reference `api_integration_guide.md` for API details
4. Follow `implementation_roadmap.md` for step-by-step plan

### Step 2: Initial Setup Commands

```bash
# Assuming you're starting in the project directory
# This should be an Xcode project created with these settings:
# - Name: SkyLightApp
# - Interface: SwiftUI
# - Language: Swift
# - Minimum iOS: 16.0

# Create the folder structure
mkdir -p SkyLightApp/App
mkdir -p SkyLightApp/Core/{Network,Authentication,Models}
mkdir -p SkyLightApp/Features/{Authentication,Calendar,Chores,Lists,Tasks,Family}/{Views,ViewModels}
mkdir -p SkyLightApp/Services
mkdir -p SkyLightApp/Utilities/Extensions
mkdir -p SkyLightApp/Resources
```

### Step 3: Start Implementation

Follow the implementation roadmap in this order:

**Week 1** (Foundation):
1. Project setup and structure
2. Network layer (APIClient, APIEndpoint, APIError)
3. Authentication infrastructure (KeychainManager, AuthenticationManager)
4. Login UI
5. Basic app navigation

**Week 2-3** (Core Features):
1. Calendar feature (service, models, UI)
2. Chores feature (service, models, UI)
3. Lists feature
4. Tasks feature
5. Family feature

**Week 4** (Polish):
1. Error handling improvements
2. Caching
3. Settings
4. UI polish
5. Bug fixes

## 🔑 Critical Implementation Points

### 1. API Base URL
```swift
static let baseURL = "https://api.ourskylight.com"
```

### 2. Authentication Flow
```
Login → Store Token in Keychain → Fetch Frames → Select Frame → Main App
```

### 3. Date Handling
Always use ISO8601 format:
```swift
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
```

### 4. Error Handling
Every async operation should have proper error handling:
```swift
do {
    let result = try await service.fetch()
    // Handle success
} catch {
    handleError(error)
}
```

### 5. State Management
- AuthenticationManager: App-level state (auth, frame selection)
- ViewModels: Feature-level state (data, loading, errors)
- @State: View-level state (local UI state)

## 🎨 Code Structure Template

### For Services:
```swift
protocol CalendarServiceProtocol {
    func getEvents(frameId: String, from: Date, to: Date) async throws -> [CalendarEvent]
}

class CalendarService: CalendarServiceProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func getEvents(frameId: String, from: Date, to: Date) async throws -> [CalendarEvent] {
        let endpoint = SkylightEndpoint.getCalendarEvents(
            frameId: frameId,
            startDate: from,
            endDate: to
        )
        let response: CalendarEventsResponse = try await apiClient.request(endpoint)
        return response.events
    }
}
```

### For ViewModels:
```swift
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    private let service: CalendarServiceProtocol
    private let authManager: AuthenticationManager
    
    init(service: CalendarServiceProtocol, authManager: AuthenticationManager) {
        self.service = service
        self.authManager = authManager
    }
    
    func loadEvents() async {
        guard let frameId = authManager.currentFrameId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            events = try await service.getEvents(
                frameId: frameId,
                from: startDate,
                to: endDate
            )
        } catch {
            self.error = error
            self.showError = true
        }
    }
}
```

### For Views:
```swift
struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    
    var body: some View {
        NavigationStack {
            List(viewModel.events) { event in
                EventRow(event: event)
            }
            .navigationTitle("Calendar")
            .refreshable {
                await viewModel.loadEvents()
            }
            .task {
                await viewModel.loadEvents()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}
```

## 📋 Implementation Checklist

Use this checklist as you implement:

### Phase 0: Setup
- [ ] Create Xcode project
- [ ] Set up folder structure
- [ ] Create Constants.swift
- [ ] Set up .gitignore
- [ ] Create JSONCoders

### Phase 1: Foundation
- [ ] Implement APIError
- [ ] Implement APIEndpoint protocol
- [ ] Implement APIClient
- [ ] Implement KeychainManager
- [ ] Create core models (User, Frame)
- [ ] Implement AuthenticationManager
- [ ] Create LoginView
- [ ] Create FrameSelectionView
- [ ] Create main app navigation

### Phase 2: Features
- [ ] Calendar service + models + UI
- [ ] Chores service + models + UI
- [ ] Lists service + models + UI
- [ ] Tasks service + models + UI
- [ ] Family service + models + UI

### Phase 3: Polish
- [ ] Improve error messages
- [ ] Add caching
- [ ] Create Settings view
- [ ] Polish UI/UX
- [ ] Fix bugs

### Phase 4: Testing
- [ ] Write unit tests
- [ ] Manual testing
- [ ] Performance testing
- [ ] Bug fixes

## 🐛 Common Issues & Solutions

### Issue: "Cannot find type 'X' in scope"
**Solution**: Make sure you've imported the file into your Xcode project and the target is checked.

### Issue: Keychain operations failing
**Solution**: Ensure you're testing on a real device or simulator, not Previews. Keychain doesn't work in Previews.

### Issue: "Publishing changes from background threads"
**Solution**: Add `@MainActor` to ViewModel class or use `Task { @MainActor in ... }`

### Issue: API requests failing with 401
**Solution**: Check that the token is being retrieved from Keychain and added to request headers correctly.

### Issue: Dates parsing incorrectly
**Solution**: Verify ISO8601DateFormatter configuration matches API format exactly.

## 🧪 Testing Strategy

### Unit Tests
Focus on:
- ViewModels (business logic)
- Services (API integration)
- Utility functions
- Models (if complex logic)

Mock dependencies:
```swift
class MockAPIClient: APIClient {
    var mockResponse: Any?
    var mockError: Error?
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        if let error = mockError {
            throw error
        }
        return mockResponse as! T
    }
}
```

### Manual Testing
Test each feature:
1. Happy path (everything works)
2. Error cases (network failure, invalid data)
3. Edge cases (empty lists, long text)
4. Different screen sizes

## 📱 Build Configurations

### Debug
- Verbose logging enabled
- API requests/responses logged
- Fast build times

### Release
- No logging
- Optimizations enabled
- Code signing for distribution

## 🔐 Security Checklist

- [ ] All credentials stored in Keychain, never UserDefaults
- [ ] No sensitive data in logs
- [ ] HTTPS only (App Transport Security configured)
- [ ] Tokens cleared on logout
- [ ] No hardcoded API keys or secrets

## 📊 Success Criteria

Before considering a feature complete:
- [ ] Feature works as expected
- [ ] Error handling in place
- [ ] Loading states shown
- [ ] Empty states handled
- [ ] Pull-to-refresh works
- [ ] Unit tests written
- [ ] No compiler warnings
- [ ] Manual testing completed

## 🎓 Learning Resources

If you're new to any of these concepts:

**SwiftUI**: 
- Apple's SwiftUI Tutorials
- SwiftUI by Example (hackingwithswift.com)

**Combine**:
- Apple's Combine Framework documentation
- Using Combine (heckingwithswift.com)

**MVVM**:
- Understand the pattern first
- Focus on separation of concerns
- ViewModels should be UI-independent

**Async/Await**:
- Apple's Concurrency documentation
- Understand Task, async, await
- Use @MainActor for UI updates

## 🚦 When to Ask for Help

Ask for help if:
- Stuck on the same issue for >2 hours
- Not sure about architecture decisions
- API documentation unclear
- Unsure about best practices
- Need code review

## 🎯 Quick Reference: API Endpoints

All endpoints require authentication header:
```
Authorization: Bearer {token}
```

**Authentication**:
- POST `/api/v1/auth/login` - Login with email/password
- POST `/api/v1/auth/refresh` - Refresh token

**Frames**:
- GET `/api/v1/frames` - Get available frames
- GET `/api/v1/frames/{frameId}` - Get frame info

**Calendar**:
- GET `/api/v1/frames/{frameId}/calendar/events` - Get events
- GET `/api/v1/frames/{frameId}/calendar/sources` - Get calendar sources

**Chores**:
- GET `/api/v1/frames/{frameId}/chores` - Get chores
- POST `/api/v1/frames/{frameId}/chores` - Create chore
- PATCH `/api/v1/frames/{frameId}/chores/{choreId}` - Update chore
- DELETE `/api/v1/frames/{frameId}/chores/{choreId}` - Delete chore

**Lists**:
- GET `/api/v1/frames/{frameId}/lists` - Get all lists
- GET `/api/v1/frames/{frameId}/lists/{listId}/items` - Get list items
- POST `/api/v1/frames/{frameId}/lists/{listId}/items` - Add item

**Tasks**:
- POST `/api/v1/frames/{frameId}/tasks` - Create task
- GET `/api/v1/frames/{frameId}/tasks` - Get tasks

**Family**:
- GET `/api/v1/frames/{frameId}/family/members` - Get family members
- GET `/api/v1/frames/{frameId}/devices` - Get devices

For complete API documentation, see `api_integration_guide.md`.

## 🎬 Next Steps

1. **Review all documents** to understand the full scope
2. **Start with Phase 0** from the implementation roadmap
3. **Build incrementally** - get each piece working before moving on
4. **Test frequently** - don't wait until the end
5. **Commit often** - small, focused commits
6. **Ask questions** - when unclear or stuck

## ⚠️ Important Reminders

1. **This API is unofficial** - it's reverse-engineered and may change
2. **No official support** - we're on our own if issues arise
3. **Use responsibly** - don't abuse the API with excessive requests
4. **Respect ToS** - ensure we're not violating Skylight's terms
5. **Quality matters** - build something we'd want to use ourselves

## 🎉 Let's Build Something Great!

You have everything you need:
- ✅ Detailed technical specifications
- ✅ Complete API documentation
- ✅ Step-by-step implementation plan
- ✅ Code examples and templates
- ✅ Testing strategy
- ✅ Security guidelines

Now it's time to start coding. Follow the roadmap, refer to the docs when needed, and build an awesome app!

Good luck! 🚀
