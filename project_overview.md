# Skylight iOS App - Project Overview

## Project Goal
Create a native iOS application that integrates with the Skylight Calendar API to provide users with access to their Skylight family calendar, chores, lists, tasks, and other features directly from their iPhone or iPad.

## Project Status
**Phase**: Planning & Architecture
**Target Platform**: iOS 16.0+
**Language**: Swift
**Architecture**: SwiftUI + MVVM

## Key Objectives

1. **Core Features**
   - View calendar events
   - Manage chores (view, create, mark complete)
   - Access shopping and to-do lists
   - Create and manage tasks
   - View family members and their profiles
   - Track reward points (if Skylight Plus subscription)

2. **User Experience**
   - Native iOS design following Apple Human Interface Guidelines
   - Smooth, responsive interface
   - Offline capability with local caching
   - Background sync for up-to-date data
   - Secure credential storage

3. **Technical Goals**
   - Clean, maintainable code architecture
   - Comprehensive error handling
   - Unit and integration tests
   - Secure API communication
   - Efficient data management

## Project Structure

```
SkyLightApp/
├── SkyLightApp/
│   ├── App/
│   │   ├── SkyLightApp.swift              # App entry point
│   │   └── AppDelegate.swift              # App lifecycle management
│   ├── Core/
│   │   ├── Network/
│   │   │   ├── APIClient.swift            # Base networking layer
│   │   │   ├── APIEndpoint.swift          # API endpoint definitions
│   │   │   └── APIError.swift             # Error handling
│   │   ├── Authentication/
│   │   │   ├── AuthenticationManager.swift # Auth flow management
│   │   │   └── KeychainManager.swift      # Secure storage
│   │   └── Models/
│   │       ├── CalendarEvent.swift
│   │       ├── Chore.swift
│   │       ├── List.swift
│   │       ├── Task.swift
│   │       ├── FamilyMember.swift
│   │       └── Frame.swift
│   ├── Features/
│   │   ├── Authentication/
│   │   │   ├── Views/
│   │   │   │   ├── LoginView.swift
│   │   │   │   └── FrameSelectionView.swift
│   │   │   └── ViewModels/
│   │   │       └── AuthenticationViewModel.swift
│   │   ├── Calendar/
│   │   │   ├── Views/
│   │   │   │   ├── CalendarView.swift
│   │   │   │   └── EventDetailView.swift
│   │   │   └── ViewModels/
│   │   │       └── CalendarViewModel.swift
│   │   ├── Chores/
│   │   │   ├── Views/
│   │   │   │   ├── ChoresListView.swift
│   │   │   │   ├── ChoreDetailView.swift
│   │   │   │   └── CreateChoreView.swift
│   │   │   └── ViewModels/
│   │   │       └── ChoresViewModel.swift
│   │   ├── Lists/
│   │   │   ├── Views/
│   │   │   │   ├── ListsView.swift
│   │   │   │   └── ListDetailView.swift
│   │   │   └── ViewModels/
│   │   │       └── ListsViewModel.swift
│   │   ├── Tasks/
│   │   │   ├── Views/
│   │   │   │   └── CreateTaskView.swift
│   │   │   └── ViewModels/
│   │   │       └── TasksViewModel.swift
│   │   └── Family/
│   │       ├── Views/
│   │       │   └── FamilyView.swift
│   │       └── ViewModels/
│   │           └── FamilyViewModel.swift
│   ├── Services/
│   │   ├── CalendarService.swift          # Calendar API calls
│   │   ├── ChoresService.swift            # Chores API calls
│   │   ├── ListsService.swift             # Lists API calls
│   │   ├── TasksService.swift             # Tasks API calls
│   │   └── FamilyService.swift            # Family API calls
│   ├── Utilities/
│   │   ├── Extensions/
│   │   │   ├── Date+Extensions.swift
│   │   │   ├── String+Extensions.swift
│   │   │   └── View+Extensions.swift
│   │   ├── Constants.swift
│   │   └── Logger.swift
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Localizable.strings
│       └── Info.plist
├── SkyLightAppTests/
│   ├── Network/
│   ├── Services/
│   └── ViewModels/
└── SkyLightAppUITests/
    └── E2ETests/

```

## Technology Stack

### Core Technologies
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS Version**: iOS 16.0

### Key Libraries & Frameworks
- **Foundation**: Core utilities
- **Combine**: Reactive programming for data flow
- **URLSession**: Native HTTP networking
- **KeychainAccess** (or native Keychain): Secure credential storage
- **SwiftUI**: User interface
- **XCTest**: Unit and UI testing

### Optional Libraries (to be evaluated)
- **Alamofire**: Alternative to URLSession for more convenience
- **SwiftyJSON**: JSON parsing (if not using Codable)
- **Realm** or **CoreData**: Local database for offline support

## Reference Materials

### API Documentation
Based on the reverse-engineered Skylight API:
- **Swagger UI**: https://theeaglebyte.github.io/skylight-api/swagger.html
- **ReDoc**: https://theeaglebyte.github.io/skylight-api/redoc.html
- **OpenAPI Spec**: https://theeaglebyte.github.io/skylight-api/openapi/openapi.yaml

### Reference Implementation
- **MCP Server (TypeScript)**: https://github.com/TheEagleByte/skylight-mcp
  - Use as reference for API request/response formats
  - Authentication flow implementation
  - Error handling patterns

### Design Guidelines
- **Apple HIG**: https://developer.apple.com/design/human-interface-guidelines/
- **SwiftUI Tutorials**: https://developer.apple.com/tutorials/swiftui

## Development Phases

### Phase 1: Foundation (Weeks 1-2)
- Set up Xcode project structure
- Implement base networking layer
- Create authentication flow
- Implement secure credential storage
- Basic error handling

### Phase 2: Core Features (Weeks 3-5)
- Calendar view and event display
- Chores list and creation
- Lists viewing
- Task creation
- Family member display

### Phase 3: Enhancement (Weeks 6-7)
- Offline support with local caching
- Background sync
- Push notifications (if API supports)
- Settings and preferences
- Polish UI/UX

### Phase 4: Testing & Refinement (Week 8)
- Comprehensive testing
- Bug fixes
- Performance optimization
- App Store preparation

## Success Criteria

### Must Have (MVP)
- [ ] User can log in with Skylight credentials
- [ ] User can select their frame (household)
- [ ] User can view calendar events
- [ ] User can view chores list
- [ ] User can create new chores
- [ ] User can view shopping/to-do lists
- [ ] User can add tasks
- [ ] User can view family members
- [ ] Credentials stored securely
- [ ] Proper error handling and user feedback

### Should Have
- [ ] Chores can be marked complete
- [ ] Chores can be filtered by assignee/date
- [ ] Calendar events can be filtered
- [ ] List items can be checked off
- [ ] Offline viewing of cached data
- [ ] Background data refresh
- [ ] Pull-to-refresh on all lists

### Nice to Have
- [ ] Rewards tracking
- [ ] Widgets for home screen
- [ ] Siri shortcuts
- [ ] Apple Watch companion app
- [ ] Dark mode support
- [ ] Multiple frame support
- [ ] Local notifications for upcoming chores
- [ ] Export calendar to Apple Calendar

## Risks & Mitigations

### Risk 1: Unofficial API Changes
**Risk**: Skylight could change their API without notice, breaking the app
**Mitigation**: 
- Implement robust error handling
- Version API requests
- Monitor API changes via community
- Have fallback/graceful degradation

### Risk 2: Authentication Complexity
**Risk**: Auth flow may be complex or change
**Mitigation**:
- Follow MCP server's proven implementation
- Add comprehensive logging
- Support both email/password and token methods

### Risk 3: Frame ID Discovery
**Risk**: Users need to find their Frame ID manually
**Mitigation**:
- Implement automatic frame discovery after login
- Show list of available frames to user
- Provide clear instructions if manual input needed

### Risk 4: Rate Limiting
**Risk**: API may have undocumented rate limits
**Mitigation**:
- Implement request throttling
- Cache data locally
- Batch requests where possible
- Monitor for rate limit errors

## Security Considerations

1. **Credential Storage**
   - Use iOS Keychain for username/password
   - Secure token storage
   - Never log sensitive data
   - Clear credentials on logout

2. **Network Security**
   - HTTPS only
   - Certificate pinning (optional but recommended)
   - Validate all API responses
   - Handle man-in-the-middle scenarios

3. **Data Privacy**
   - Minimize data stored locally
   - Clear cache on logout
   - Follow iOS privacy best practices
   - No analytics without consent

## Open Questions

1. Does the Skylight API support push notifications or webhooks?
2. What are the actual rate limits?
3. Are there any terms of service restrictions on third-party apps?
4. How should we handle users with multiple frames?
5. Should we support landscape orientation on iPad?
6. What's the data retention policy for cached information?

## Resources for Claude Code

When working with Claude Code on this project, refer to:
1. **Technical Specification**: `technical_specification.md`
2. **API Integration Guide**: `api_integration_guide.md`
3. **Implementation Roadmap**: `implementation_roadmap.md`
4. **Architecture Guide**: `architecture_guide.md`
5. **Original API Resources**: `skylight_api_resources.md`

## Contact & Collaboration

This is a reverse-engineered integration with an unofficial API. The project should:
- Follow Apple's guidelines for App Store submission
- Respect Skylight's intellectual property
- Not misrepresent affiliation with Skylight
- Include appropriate disclaimers about unofficial status

## Notes

- This app is built on reverse-engineered API and is unofficial
- API may change without notice
- Use at your own risk
- Ensure compliance with Skylight terms of service
- Consider reaching out to Skylight for official API access or partnership
