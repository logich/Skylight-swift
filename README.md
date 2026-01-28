# Skylight iOS App

An unofficial native iOS app for [Skylight Calendar](https://www.ourskylight.com/), built with SwiftUI.

> **Disclaimer**: This is an unofficial app that uses a reverse-engineered API. It is not affiliated with, endorsed by, or connected to Skylight in any way. Use at your own risk.

## Features

- **Calendar**: View your synced calendar events with day, week, and month views
- **Chores**: Create, assign, and complete chores with optional recurrence
- **Lists**: Manage shopping and to-do lists with your family
- **Family**: View family members and connected Skylight devices
- **Multi-household**: Support for accounts with multiple Skylight frames

## Screenshots

*Coming soon*

## Requirements

- **macOS**: 13.0 or later (for Xcode 15)
- **Xcode**: 15.0 or later
- **iOS**: 16.0 or later
- **Apple Developer Account**: Free account works for personal device testing
- **Skylight Account**: An existing account at [ourskylight.com](https://www.ourskylight.com/)

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/logich/Skylight-swift.git
cd Skylight-swift
```

### Step 2: Create Xcode Project

Since this repository contains only source files, you need to create an Xcode project:

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
   - Save the project **inside** the cloned `Skylight-swift` folder
   - This will create `SkyLightApp.xcodeproj` alongside the `SkyLightApp/` source folder

### Step 3: Add Source Files to Project

1. In Xcode, **right-click** on the `SkyLightApp` folder in the Project Navigator (left sidebar)

2. Select **Add Files to "SkyLightApp"...**

3. Navigate to the `SkyLightApp/` source folder and select **all subfolders**:
   - `App/`
   - `Core/`
   - `Features/`
   - `Services/`
   - `Utilities/`

4. In the dialog:
   - Check **"Copy items if needed"** (uncheck if files are already in place)
   - Check **"Create groups"**
   - Ensure your target is selected
   - Click **Add**

5. **Delete the auto-generated files** that Xcode created (if they conflict):
   - `ContentView.swift` (we have our own)
   - `SkyLightAppApp.swift` (we have `SkyLightApp.swift`)

### Step 4: Configure Signing

1. Select the **project** in the Navigator (blue icon at top)

2. Select the **SkyLightApp** target

3. Go to **Signing & Capabilities** tab

4. Check **"Automatically manage signing"**

5. Select your **Team**:
   - If you don't have one, click **Add Account** and sign in with your Apple ID
   - Select your Personal Team (free) or Developer account

6. Xcode will create a provisioning profile automatically

### Step 5: Build and Run

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

4. **Navigate** using the bottom tab bar:
   - **Calendar**: View upcoming events
   - **Chores**: Manage family chores
   - **Lists**: Shopping and to-do lists
   - **Family**: View family members
   - **Settings**: Account and app settings

## Project Structure

```
SkyLightApp/
├── App/                          # App entry point and navigation
│   ├── SkyLightApp.swift         # @main app struct
│   ├── ContentView.swift         # Root view with auth routing
│   └── MainTabView.swift         # Tab bar navigation
├── Core/
│   ├── Network/                  # API layer
│   │   ├── APIClient.swift       # HTTP client
│   │   ├── APIEndpoint.swift     # Endpoint protocol
│   │   ├── APIError.swift        # Error types
│   │   └── SkylightEndpoint.swift # All API endpoints
│   ├── Authentication/           # Auth management
│   │   ├── AuthenticationManager.swift
│   │   └── KeychainManager.swift
│   └── Models/                   # Data models
├── Features/                     # Feature modules
│   ├── Authentication/           # Login, frame selection
│   ├── Calendar/                 # Calendar views
│   ├── Chores/                   # Chores management
│   ├── Lists/                    # Lists management
│   ├── Family/                   # Family & devices
│   └── Settings/                 # App settings
├── Services/                     # Business logic layer
└── Utilities/                    # Extensions & helpers
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
2. Check that your device is running iOS 16.0 or later

### Build fails with "Cannot find type X in scope"

Ensure files are organized in groups (yellow folders), not folder references (blue folders):
1. Remove the folder reference
2. Re-add using **Add Files** with **"Create groups"** selected

### API errors or "Unauthorized"

- Verify your Skylight credentials are correct
- The API may have changed; check the issues page for updates

## Architecture

The app follows the **MVVM** (Model-View-ViewModel) architecture pattern:

- **Models**: Data structures matching the API responses
- **Views**: SwiftUI views for the UI
- **ViewModels**: `@Observable` classes managing view state and business logic
- **Services**: Protocol-based API communication layer

Key technologies:
- **SwiftUI** for declarative UI
- **Async/await** for networking
- **Keychain** for secure credential storage

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: If you find this project useful, please consider starring the repositories that made it possible:
- [TheEagleByte/skylight-mcp](https://github.com/TheEagleByte/skylight-mcp)
- [TheEagleByte/skylight-api](https://github.com/TheEagleByte/skylight-api)
