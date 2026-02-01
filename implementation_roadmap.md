# Skylight iOS App - Implementation Roadmap

## Overview
This document tracks the implementation progress for the Skylight iOS app.

---

## Current Status: Feature Complete ✅

The app has completed all planned phases and includes additional advanced features.

---

## Phase 0: Project Setup ✅ COMPLETED

- [x] Create Xcode project (SwiftUI, iOS 17+)
- [x] Set up folder structure (App, Core, Features, Services, Utilities)
- [x] Configure Info.plist (location permissions)
- [x] Set up Git repository
- [x] Create Constants file
- [x] Set up Date formatting extensions
- [x] Set up JSON Coders with custom date handling

---

## Phase 1: Core Infrastructure ✅ COMPLETED

### Network Layer
- [x] `APIError.swift` - Error types and handling
- [x] `APIEndpoint.swift` - Endpoint protocol
- [x] `SkylightEndpoint.swift` - 40+ API endpoints
- [x] `APIClient.swift` - HTTP client with logging

### Authentication
- [x] `KeychainManager.swift` - Secure credential storage
- [x] `AuthenticationManager.swift` - Auth state, login, logout, frame selection
- [x] Login models and responses

### Core Models
- [x] `User.swift`
- [x] `Frame.swift`
- [x] `AuthResponse.swift`

### Authentication UI
- [x] `LoginView.swift` - Email/password login
- [x] `FrameSelectionView.swift` - Household selection
- [x] `LoginViewModel.swift`
- [x] `ContentView.swift` - Auth flow router
- [x] `SkyLightApp.swift` - App entry point

---

## Phase 2: Core Features ✅ COMPLETED

### Calendar Feature
- [x] `CalendarEvent.swift` - Event model with JSON:API parsing
- [x] `CalendarService.swift` - Fetch events by date range
- [x] `CalendarViewModel.swift` - Smart caching (60-min expiration)
- [x] `CalendarView.swift` - Day/Week/Month views
- [x] `EventRow.swift` - Event list item
- [x] `EventDetailView.swift` - Full event details
- [x] `DriveTimeBadge.swift` - Drive time display
- [x] `DriveTimeRow.swift` - Interactive drive time

### Chores Feature
- [x] `Chore.swift` - Chore model
- [x] `ChoresService.swift` - CRUD operations
- [x] `ChoresViewModel.swift`
- [x] `ChoresView.swift` - Chores list with filtering

### Lists Feature
- [x] `ShoppingList.swift`, `Task.swift` - List models
- [x] `ListsService.swift`, `TasksService.swift`
- [x] `ListsViewModel.swift`
- [x] `ListsView.swift` - Lists display

### Family Feature
- [x] `FamilyMember.swift`, `Device.swift` - Models
- [x] `FamilyService.swift`
- [x] `FamilyViewModel.swift`
- [x] `FamilyView.swift` - Family member display

### Tab Navigation
- [x] `MainTabView.swift` - Calendar, Chores, Lists, Family, Settings tabs

---

## Phase 3: Enhancement ✅ COMPLETED

### Settings
- [x] `SettingsView.swift`
  - [x] Current household display
  - [x] Switch household
  - [x] Account info
  - [x] Sign out with confirmation
  - [x] Drive time alerts toggle
  - [x] Buffer time picker (5/10/15/20/30 min)

### Location & Drive Time
- [x] `LocationService.swift`
  - [x] Current location with permission handling
  - [x] Address geocoding
  - [x] Driving time calculation via MapKit

### Shortcuts Integration
- [x] `CalendarIntents.swift` - 6 App Intents:
  - [x] `GetTodayEventsIntent`
  - [x] `GetEventsForDateIntent`
  - [x] `GetUpcomingEventsIntent`
  - [x] `GetEventsStartingWithinIntent`
  - [x] `HasUpcomingEventIntent`
  - [x] `GetMinutesUntilNextEventIntent`

---

## Phase 4: Time to Leave Feature ✅ COMPLETED

### Foundation
- [x] `SharedConstants.swift` - App Group ID, UserDefaults keys, notification IDs, URL scheme
- [x] `WidgetEvent.swift` - Lightweight Codable model with `leaveByDate` computed property
- [x] `SharedDataManager.swift` - Read/write App Group UserDefaults
- [x] App Groups capability (`group.com.skylightapp.shared`)

### Notifications
- [x] `NotificationService.swift`
  - [x] `requestAuthorization()` - Request permission
  - [x] `registerCategories()` - Notification actions
  - [x] `scheduleTimeToLeaveNotification(for:)` - Schedule at leave time
  - [x] `cancelAllTimeToLeaveNotifications()` - Clear outdated
- [x] Notification categories in `SkyLightApp.swift`

### Widget Extension
- [x] New target: `SkylightWidgetExtension`
- [x] `SkylightWidget.swift`
  - [x] `TimelineProvider` with state transitions
  - [x] `SmallWidgetView` - Title, time, leave countdown
  - [x] `MediumWidgetView` - Full info with location
  - [x] `AccessoryCircularView` - Lock screen circular
  - [x] `AccessoryRectangularView` - Lock screen rectangular
  - [x] Deep link via `widgetURL`
- [x] Widget shared files (WidgetEvent, SharedConstants)
- [x] App Group entitlement

### Orchestration
- [x] `DriveTimeManager.swift`
  - [x] `processEvents([CalendarEvent])` - Calculate drive times
  - [x] Cache drive times (30-min expiration)
  - [x] Save events to shared storage
  - [x] Schedule notifications
  - [x] Trigger widget refresh
  - [x] `onSettingsChanged()` - Handle settings updates
- [x] Integration with `CalendarViewModel.loadEvents()`

### Background Refresh
- [x] `BackgroundTaskManager.swift`
  - [x] Register background task
  - [x] Schedule periodic refresh (15-min minimum)
  - [x] Fetch events and process drive times
- [x] Background task ID in build settings

### Deep Linking
- [x] URL scheme: `skylight://event/{id}`
- [x] Handle in `SkyLightApp.swift`
- [x] Widget tap navigation

---

## Phase 5: Testing & Refinement 🔄 IN PROGRESS

### Testing
- [ ] Unit tests for ViewModels
- [ ] Unit tests for Services
- [ ] Integration tests for auth flow
- [ ] UI tests for critical paths
- [ ] Test widget on real device

### Bug Fixes
- [ ] Address Swift 6 concurrency warnings
- [ ] Update deprecated CLGeocoder usage

### Performance
- [ ] Profile memory usage
- [ ] Test with large event datasets
- [ ] Optimize widget timeline generation

---

## Future Enhancements (Post-Launch)

### Version 1.1
- [ ] Apple Watch companion app
- [ ] iPad layout optimization
- [ ] Event creation/editing
- [ ] Chore completion
- [ ] List item management

### Version 1.2
- [ ] Search functionality
- [ ] Advanced filtering
- [ ] Multiple frame quick-switch
- [ ] Export to Apple Calendar
- [ ] Share lists with non-Skylight users

### Version 2.0
- [ ] Offline-first with CoreData
- [ ] Conflict resolution
- [ ] Photo attachments
- [ ] Meal planning integration
- [ ] Advanced rewards tracking

---

## File Summary

### Files Created in Time to Leave Implementation

| File | Purpose |
|------|---------|
| `Utilities/SharedConstants.swift` | App Group ID, UserDefaults keys, notification IDs, URL scheme |
| `Core/Models/WidgetEvent.swift` | Lightweight event model with `leaveByDate` |
| `Services/SharedDataManager.swift` | App Group data sharing |
| `Services/NotificationService.swift` | Local notification management |
| `Services/DriveTimeManager.swift` | Time to Leave orchestration |
| `App/BackgroundTaskManager.swift` | Background refresh handling |
| `SkylightWidget/SkylightWidget.swift` | Widget views and timeline |
| `SkylightWidget/WidgetEvent.swift` | Widget event model |
| `SkylightWidget/SharedConstants.swift` | Widget shared constants |
| `SkylightApp.entitlements` | App Group entitlement |
| `SkylightWidgetExtension.entitlements` | Widget App Group entitlement |

### Files Modified in Time to Leave Implementation

| File | Changes |
|------|---------|
| `App/SkyLightApp.swift` | Notification setup, background tasks, deep linking |
| `Features/Settings/Views/SettingsView.swift` | Drive time alerts toggle, buffer picker |
| `Features/Calendar/ViewModels/CalendarViewModel.swift` | Trigger DriveTimeManager |
| `project.pbxproj` | Widget target, build settings |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Main App                                 │
├─────────────────────────────────────────────────────────────────┤
│  CalendarViewModel                                               │
│       │                                                          │
│       ▼                                                          │
│  CalendarService  ───────────────────────────────────────────►  API
│       │                                                          │
│       ▼                                                          │
│  DriveTimeManager                                                │
│       │                                                          │
│       ├──► LocationService (drive time calculation)             │
│       │                                                          │
│       ├──► NotificationService (schedule alerts)                │
│       │                                                          │
│       └──► SharedDataManager (save to App Group)                │
│                    │                                             │
│                    ▼                                             │
│            App Group UserDefaults                                │
│                    │                                             │
└────────────────────┼─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Widget Extension                            │
├─────────────────────────────────────────────────────────────────┤
│  SkylightWidgetProvider (TimelineProvider)                       │
│       │                                                          │
│       └──► Reads from App Group UserDefaults                    │
│       │                                                          │
│       ▼                                                          │
│  Widget Views (Small, Medium, Lock Screen)                       │
│       │                                                          │
│       └──► widgetURL for deep linking                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Success Metrics

### Completed ✅
- [x] App builds successfully
- [x] All core features functional
- [x] Widget displays correctly
- [x] Notifications schedule at correct times
- [x] Settings persist correctly
- [x] Background refresh works

### To Verify
- [ ] Crash-free rate > 99%
- [ ] App launch time < 3 seconds
- [ ] Widget updates within 15 minutes
- [ ] Drive time accuracy within 5 minutes

---

## Development Notes

### Key Patterns Used
- **Singleton managers**: `AuthenticationManager.shared`, `DriveTimeManager.shared`
- **@MainActor**: Thread-safe UI updates
- **async/await**: Modern concurrency
- **App Groups**: Cross-process data sharing
- **Codable**: JSON serialization

### Common Issues & Solutions
- **Widget not updating**: Call `WidgetCenter.shared.reloadAllTimelines()`
- **Notifications not firing**: Check authorization status
- **Drive time failing**: Ensure location permission granted
- **Background task not running**: Minimum 15-minute interval enforced by iOS

---

## Changelog

### January 2025
- Initial project setup
- Core infrastructure (network, auth, keychain)
- All main features (Calendar, Chores, Lists, Family, Settings)
- Location service with drive time
- Shortcuts integration (6 intents)
- **Time to Leave feature**:
  - Home screen widgets (small, medium)
  - Lock screen widgets (circular, rectangular)
  - Local notifications at leave time
  - Settings for alerts and buffer time
  - Background refresh
  - Deep linking for widget taps
