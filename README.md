# Skylight iOS App

An unofficial native iOS app for [Skylight Calendar](https://www.ourskylight.com/), built with SwiftUI.

> **Disclaimer**: This is an unofficial app that uses a reverse-engineered API. It is not affiliated with, endorsed by, or connected to Skylight in any way. Use at your own risk.

## Features

- **Calendar Views**: View your synced calendar events with day, week, and month views
- **Event Creation**: Create new calendar events with location, attendees, and recurrence
- **Drive Time Calculations**: Automatic calculation of travel time to event locations
- **Time-to-Leave Notifications**: Get notified when it's time to leave for your events
- **Search & Filtering**: Search events by title, location, description, or attendees
- **Home Screen Widget**: View upcoming events and "Leave Now" alerts on your home screen
- **Shortcuts Automation**: 7 App Intents for automating tasks (e.g., start car climate control before events)
- **Background Sync**: Automatic calendar refresh in the background
- **Multi-household Support**: Support for accounts with multiple Skylight frames

## Screenshots

*Coming soon*

## Requirements

- **macOS**: 13.0 or later (for Xcode 15)
- **Xcode**: 15.0 or later
- **iOS**: 18.0 or later
- **Apple Developer Account**: Free account works for personal device testing
- **Skylight Account**: An existing account at [ourskylight.com](https://www.ourskylight.com/)

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/logich/Skylight-swift.git
cd Skylight-swift
```

### Step 2: Prepare for Xcode Project

First, temporarily rename the source folder to avoid conflicts:

```bash
cd Skylight-swift
mv SkyLightApp SkyLightApp-source
```

### Step 3: Create Xcode Project

1. **Open Xcode** and select **File → New → Project**

2. **Choose template**:
   - Select **iOS** → **App**
   - Click **Next**

3. **Configure project**:
   - **Product Name**: `SkyLightApp`
   - **Organization Identifier**: `com.yourname.skylightapp` (use your own)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Uncheck** "Include Tests" (optional, for simplicity)
   - Click **Next**

4. **Save location**:
   - Navigate to and select the `Skylight-swift` folder
   - Click **Create**

### Step 4: Replace Generated Files with Source Code

1. **In Finder**, open the `Skylight-swift` folder

2. **Delete Xcode's auto-generated files** inside `SkyLightApp/`:
   - Delete `ContentView.swift`
   - Delete `SkyLightAppApp.swift`
   - Keep the `Assets.xcassets` folder

3. **Copy our source code** into the Xcode project folder:
   ```bash
   cd Skylight-swift
   cp -R SkyLightApp-source/* SkyLightApp/
   rm -rf SkyLightApp-source
   ```

### Step 5: Add Source Files to Xcode

1. In Xcode, **right-click** on the `SkyLightApp` folder in the Project Navigator (left sidebar)

2. Select **Add Files to "SkyLightApp"...**

3. Navigate into the `SkyLightApp/` folder and select **all subfolders**:
   - `App/`
   - `Core/`
   - `Features/`
   - `Services/`
   - `Utilities/`

4. In the dialog:
   - **Uncheck** "Copy items if needed" (files are already in place)
   - Check **"Create groups"**
   - Ensure your target `SkyLightApp` is checked
   - Click **Add**

### Step 6: Configure Signing

1. Select the **project** in the Navigator (blue icon at top)

2. Select the **SkyLightApp** target

3. Go to **Signing & Capabilities** tab

4. Check **"Automatically manage signing"**

5. Select your **Team**:
   - If you don't have one, click **Add Account** and sign in with your Apple ID
   - Select your Personal Team (free) or Developer account

6. Xcode will create a provisioning profile automatically

7. **Repeat for SkylightWidgetExtension target** (needed for the home screen widget)

**Note**: The app uses App Groups (`group.com.rosetrace.SkylightApp`) for data sharing. You may need to update this identifier in `SharedConstants.swift` if you encounter signing issues.

### Step 7: Build and Run

#### On Simulator

1. Select a simulator from the device dropdown (e.g., "iPhone 15 Pro")
2. Press **Cmd + R** or click the **Play** button
3. The app will build and launch in the simulator

#### On Physical Device

1. **Connect your iPhone** to your Mac with a USB cable

2. **Trust the computer** on your iPhone if prompted

3. Select your **iPhone** from the device dropdown in Xcode

4. Press **Cmd + R** to build and run

5. **First time only**: On your iPhone:
   - Go to **Settings → General → VPN & Device Management**
   - Find your developer certificate and tap **Trust**

6. Re-run the app from Xcode

## Usage

1. **Launch the app** on your device or simulator

2. **Sign in** with your Skylight account credentials (email and password)

3. **Select a household** if you have multiple Skylight frames

4. **View and manage your calendar**:
   - Switch between day, week, and month views
   - Search events using the search bar
   - Tap events to view details
   - Create new events with the + button
   - Access settings from the toolbar (buffer time, notifications)

5. **Use Shortcuts automation**:
   - Open the Shortcuts app on iOS
   - Add Skylight actions like "Get Today's Events" or "Check If Event Starting Soon"
   - Create automations (e.g., "Start car climate control if event in 30 minutes")

6. **Add the home screen widget**:
   - Long-press your home screen → tap the + button
   - Search for "Skylight" and select the widget
   - View upcoming events and "Leave Now" alerts at a glance

## Shortcuts Automation Examples

The app provides 7 App Intents that can be used in the Shortcuts app:

**Available Intents:**
- Get Today's Events
- Get Events for Date
- Get Upcoming Events (next N days)
- Get Next Event
- Get Events Starting Soon (within N minutes)
- Check If Event Starting Soon (returns true/false)
- Get Minutes Until Next Event

**Example Automations:**
- **Pre-heat car**: "IF event starting in 30 minutes THEN start car climate control"
- **Set home scene**: "Get next event → IF event has location THEN set 'Leaving Home' scene"
- **Morning briefing**: "Get today's events → Show notification with event list"
- **Voice queries**: Ask Siri "What's next on Skylight?"

To create automations:
1. Open the **Shortcuts** app
2. Tap **+** to create new shortcut
3. Search for "Skylight" actions
4. Combine with other actions (HomeKit, notifications, etc.)

## Project Structure

```
SkylightApp/
├── SkylightApp/                  # Main iOS app target
│   ├── App/                      # App entry point and navigation
│   │   ├── SkyLightApp.swift     # @main app struct
│   │   ├── ContentView.swift     # Root view with auth routing
│   │   ├── BackgroundTaskManager.swift
│   │   ├── DeepLinkManager.swift
│   │   └── AppIntents/           # Shortcuts integration
│   │       └── CalendarIntents.swift
│   ├── Core/
│   │   ├── Network/              # API layer
│   │   │   ├── APIClient.swift   # HTTP client
│   │   │   ├── APIEndpoint.swift # Endpoint protocol
│   │   │   └── SkylightEndpoint.swift # All API endpoints
│   │   ├── Authentication/       # Auth management
│   │   │   ├── AuthenticationManager.swift
│   │   │   └── KeychainManager.swift
│   │   └── Models/               # Data models (CalendarEvent, User, Frame, etc.)
│   ├── Features/                 # Feature modules
│   │   ├── Authentication/       # Login, frame selection
│   │   ├── Calendar/             # Calendar views, event creation, location search
│   │   └── Settings/             # App settings
│   ├── Services/                 # Business logic layer
│   │   ├── CalendarService.swift
│   │   ├── LocationService.swift
│   │   ├── DriveTimeManager.swift
│   │   ├── NotificationService.swift
│   │   ├── FamilyService.swift
│   │   └── SharedDataManager.swift
│   └── Utilities/                # Extensions & helpers
├── SkylightAppTests/             # Unit and integration tests
└── SkylightWidget/               # Home screen widget extension
```

## Troubleshooting

### "No such module" errors

Make sure all source files are added to your target:
1. Select a file in the Navigator
2. Open the **File Inspector** (right sidebar)
3. Under **Target Membership**, ensure your app target is checked

### "Signing requires a development team"

1. Go to **Project → Signing & Capabilities**
2. Select a team (add your Apple ID if needed)

### "Unable to install app" on device

1. Ensure your device is trusted (**Settings → General → VPN & Device Management**)
2. Check that your device is running iOS 18.0 or later

### Build fails with "Cannot find type X in scope"

Ensure files are organized in groups (yellow folders), not folder references (blue folders):
1. Remove the folder reference
2. Re-add using **Add Files** with **"Create groups"** selected

### API errors or "Unauthorized"

- Verify your Skylight credentials are correct
- The API may have changed; check the issues page for updates

### Widget not updating

1. Ensure you're logged in and have selected a frame
2. Check that Background App Refresh is enabled (**Settings → General → Background App Refresh**)
3. Widget updates when app syncs in background (every 15+ minutes)

### Notifications not appearing

1. Grant notification permissions when prompted on first launch
2. Enable alerts in Settings view (in-app, accessible from toolbar)
3. Check iOS notification settings: **Settings → Notifications → Skylight**

## Architecture

The app follows the **MVVM** (Model-View-ViewModel) architecture pattern:

- **Models**: Data structures matching the API responses (Codable)
- **Views**: SwiftUI views for the UI
- **ViewModels**: `@MainActor ObservableObject` classes managing view state and business logic
- **Services**: Protocol-based API communication layer for testability

Key technologies:
- **SwiftUI** for declarative UI
- **Async/await** for networking
- **Combine** for reactive state management (@Published properties)
- **Keychain** for secure credential storage
- **WidgetKit** for home screen widget
- **App Intents** for Shortcuts automation
- **BackgroundTasks** for periodic calendar sync
- **App Groups** for data sharing between app and widget
- **CoreLocation & MapKit** for drive time calculations

Key features:
- Smart caching (60-min for events, 30-min for drive times)
- Protocol-based dependency injection for testing
- Background refresh every 15 minutes
- Time-to-leave notifications based on location
- JSON:API format handling for Skylight API

## Acknowledgments

This project builds upon the work of others who reverse-engineered the Skylight API:

### [skylight-mcp](https://github.com/TheEagleByte/skylight-mcp)
By [@TheEagleByte](https://github.com/TheEagleByte)

An MCP (Model Context Protocol) server for Skylight that provided the foundation for understanding the API structure, authentication flow, and available endpoints. This project's API implementation is heavily based on the patterns discovered in skylight-mcp.

### [skylight-api](https://github.com/TheEagleByte/skylight-api)
By [@TheEagleByte](https://github.com/TheEagleByte)

OpenAPI documentation for the reverse-engineered Skylight API, including:
- [Swagger UI Documentation](https://theeaglebyte.github.io/skylight-api/swagger.html)
- [ReDoc Documentation](https://theeaglebyte.github.io/skylight-api/redoc.html)

### [Skylight Python Scraper](https://github.com/ramseys1990/Skylight)
By [@ramseys1990](https://github.com/ramseys1990)

A Python script for extracting Skylight calendar data, which helped validate the authentication flow and API responses.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Legal

### Disclaimer

This software is provided "as is", without warranty of any kind. The developers are not responsible for any issues arising from the use of this application, including but not limited to:

- Account suspension or termination by Skylight
- Data loss or corruption
- Privacy or security issues
- Service interruptions

### API Status

This app uses an **unofficial, reverse-engineered API** that may:
- Change without notice, breaking functionality
- Have undocumented rate limits
- Be discontinued or blocked at any time

### Trademarks

"Skylight" is a trademark of Skylight Frame Inc. This project is not affiliated with, endorsed by, or connected to Skylight Frame Inc.

## License

This project is released into the public domain under the [CC0 1.0 Universal](LICENSE) license. You can copy, modify, distribute, and use the code for any purpose, including commercial, without asking permission or providing attribution.

---

**Note**: If you find this project useful, please consider starring the repositories that made it possible:
- [TheEagleByte/skylight-mcp](https://github.com/TheEagleByte/skylight-mcp)
- [TheEagleByte/skylight-api](https://github.com/TheEagleByte/skylight-api)
