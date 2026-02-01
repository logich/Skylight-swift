# Skylight iOS App - Project Overview

## Project Goal
Create a native iOS application that integrates with the Skylight Calendar API to provide users with access to their Skylight family calendar, chores, lists, tasks, and other features directly from their iPhone or iPad.

## Project Status
**Phase**: Feature Complete - Polish & Enhancement
**Target Platform**: iOS 17.0+
**Language**: Swift 5.9+
**Architecture**: SwiftUI + MVVM

## Completed Features

### Core Features ✅
- [x] User authentication with Skylight credentials
- [x] Frame (household) selection
- [x] View calendar events (day/week/month views)
- [x] View and manage chores
- [x] View shopping and to-do lists
- [x] View family members
- [x] Secure credential storage (Keychain)
- [x] Pull-to-refresh on all lists
- [x] Smart caching with 60-minute expiration

### Advanced Features ✅
- [x] **Drive Time Calculation** - Shows driving time to events with locations
- [x] **Time to Leave Widget** - Home screen and lock screen widgets showing next event with leave countdown
- [x] **Time to Leave Notifications** - Local alerts when it's time to leave for events
- [x] **Siri Shortcuts Integration** - 6 app intents for calendar automation
- [x] **Background Refresh** - Periodic data updates via iOS background tasks
- [x] **Deep Linking** - `skylight://event/{id}` URL scheme for widget navigation

### Settings ✅
- [x] Current household display
- [x] Switch household option
- [x] Account information
- [x] Drive time alerts toggle
- [x] Buffer time configuration (5/10/15/20/30 min)
- [x] Sign out with confirmation

## Project Structure

```
SkylightApp/
├── SkylightApp/
│   ├── App/
│   │   ├── SkyLightApp.swift              # App entry point with notifications & background tasks
│   │   ├── ContentView.swift              # Auth flow router
│   │   ├── MainTabView.swift              # Tab navigation (Calendar, Chores, Lists, Family, Settings)
│   │   ├── BackgroundTaskManager.swift    # Background refresh handling
│   │   └── AppIntents/
│   │       └── CalendarIntents.swift      # 6 Shortcuts intents
│   ├── Core/
│   │   ├── Authentication/
│   │   │   ├── AuthenticationManager.swift # Auth state & frame selection
│   │   │   └── KeychainManager.swift       # Secure credential storage
│   │   ├── Models/
│   │   │   ├── CalendarEvent.swift         # Main event model with JSON:API parsing
│   │   │   ├── WidgetEvent.swift           # Lightweight model for widget/notifications
│   │   │   ├── User.swift
│   │   │   ├── Frame.swift
│   │   │   ├── Chore.swift
│   │   │   ├── ShoppingList.swift
│   │   │   ├── Task.swift
│   │   │   ├── FamilyMember.swift
│   │   │   └── AuthResponse.swift
│   │   └── Network/
│   │       ├── APIClient.swift             # HTTP client with logging
│   │       ├── APIEndpoint.swift           # Endpoint protocol
│   │       ├── SkylightEndpoint.swift      # 40+ API endpoints
│   │       └── APIError.swift              # Error handling
│   ├── Features/
│   │   ├── Authentication/
│   │   │   ├── Views/ (LoginView, FrameSelectionView)
│   │   │   └── ViewModels/ (LoginViewModel)
│   │   ├── Calendar/
│   │   │   ├── Views/ (CalendarView with 7 components, EventDetailView, DriveTimeBadge)
│   │   │   └── ViewModels/ (CalendarViewModel with caching)
│   │   ├── Chores/
│   │   │   ├── Views/ (ChoresView)
│   │   │   └── ViewModels/ (ChoresViewModel)
│   │   ├── Lists/
│   │   │   ├── Views/ (ListsView)
│   │   │   └── ViewModels/ (ListsViewModel)
│   │   ├── Family/
│   │   │   ├── Views/ (FamilyView)
│   │   │   └── ViewModels/ (FamilyViewModel)
│   │   └── Settings/
│   │       └── Views/ (SettingsView with Time to Leave section)
│   ├── Services/
│   │   ├── CalendarService.swift           # Calendar API calls
│   │   ├── LocationService.swift           # Geocoding & driving directions
│   │   ├── DriveTimeManager.swift          # Time to Leave orchestration
│   │   ├── NotificationService.swift       # Local notification scheduling
│   │   ├── SharedDataManager.swift         # App Group data sharing
│   │   ├── ChoresService.swift
│   │   ├── ListsService.swift
│   │   ├── TasksService.swift
│   │   └── FamilyService.swift
│   └── Utilities/
│       ├── Constants.swift                 # API URLs, Keychain keys
│       ├── SharedConstants.swift           # App Group ID, notification IDs, URL scheme
│       ├── JSONCoders.swift                # Custom date handling
│       └── Extensions/
│           ├── Date+Extensions.swift       # 15+ date helpers
│           ├── Color+Extensions.swift      # Hex color parsing
│           └── View+Extensions.swift
├── SkylightWidget/                         # Widget Extension
│   ├── SkylightWidget.swift                # Widget views & TimelineProvider
│   ├── WidgetEvent.swift                   # Event model for widget
│   ├── SharedConstants.swift               # Shared constants copy
│   └── SkylightWidgetExtension.entitlements
└── SkylightApp.xcodeproj/
```

## Technology Stack

### Core Technologies
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS Version**: iOS 17.0 (iOS 26.2 SDK)
- **Concurrency**: Swift async/await

### Frameworks Used
- **Foundation**: Core utilities
- **SwiftUI**: User interface
- **WidgetKit**: Home screen & lock screen widgets
- **UserNotifications**: Local "Time to Leave" alerts
- **CoreLocation**: Current location access
- **MapKit**: Driving directions & time calculation
- **BackgroundTasks**: Periodic background refresh
- **App Intents**: Siri Shortcuts integration
- **App Groups**: Data sharing between app and widget

## Targets

| Target | Bundle ID | Description |
|--------|-----------|-------------|
| SkylightApp | com.rosetrace.SkylightApp | Main iOS app |
| SkylightWidgetExtension | com.rosetrace.SkylightApp.SkylightWidget | Widget extension |

## App Groups
- **ID**: `group.com.skylightapp.shared`
- **Purpose**: Share calendar events and settings between main app and widget

## URL Scheme
- **Scheme**: `skylight://`
- **Event Deep Link**: `skylight://event/{eventId}`

## API Integration
- **Base URL**: `https://app.ourskylight.com`
- **Format**: JSON:API with `data` and `included` arrays
- **Authentication**: Basic Auth (Base64 `userId:token`)
- **Reference**: [Skylight API Swagger](https://theeaglebyte.github.io/skylight-api/swagger.html)

## Security
- Credentials stored in iOS Keychain
- HTTPS-only API communication
- Token-based authentication
- No sensitive data logging in production

## Known Limitations
- Unofficial/reverse-engineered API (may change without notice)
- Drive time requires location permission
- Widget updates limited by iOS WidgetKit policies
- Background refresh minimum interval is 15 minutes

## Resources for Development

### Internal Documentation
- `technical_specification.md` - Detailed technical specs
- `api_integration_guide.md` - API usage patterns
- `implementation_roadmap.md` - Development phases and progress
- `skylight_api_resources.md` - Original API research

### External Resources
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)

## Disclaimer
This app is built on a reverse-engineered API and is **unofficial**. It is not affiliated with or endorsed by Skylight. The API may change without notice. Use at your own risk.
