# Skylight Calendar API Resources

## Overview
This document contains detailed information about tools and resources for working with the Skylight Calendar API, including the unofficial MCP server and Python scraping tools.

---

## 1. Skylight MCP Server (@eaglebyte/skylight-mcp)

### Project Information
- **Repository**: https://github.com/TheEagleByte/skylight-mcp
- **NPM Package**: @eaglebyte/skylight-mcp
- **Version**: 1.1.7 (Latest as of Dec 30, 2025)
- **License**: MIT
- **Language**: TypeScript (99.9%)
- **Status**: Active development, 3 stars, 1 fork

### Description
An MCP (Model Context Protocol) server that enables AI assistants like Claude to interact with Skylight family calendar. This is the most feature-complete tool available for programmatic access to Skylight.

### Key Features
- **Calendar**: Query calendar events with date ranges
- **Chores**: View and create chores with optional recurrence
- **Lists**: View grocery and to-do lists
- **Tasks**: Add items to the task box
- **Family**: View family members and devices
- **Rewards**: Check reward points and available rewards
- **Source Calendars**: List connected calendar sources (Google, iCloud, etc.)

### Installation Options

#### Option 1: NPM Package (Recommended)
```json
{
  "mcpServers": {
    "skylight": {
      "command": "npx",
      "args": ["@eaglebyte/skylight-mcp"],
      "env": {
        "SKYLIGHT_EMAIL": "your_email@example.com",
        "SKYLIGHT_PASSWORD": "your_password",
        "SKYLIGHT_FRAME_ID": "your_frame_id"
      }
    }
  }
}
```

#### Option 2: Claude Code CLI
```bash
claude mcp add skylight npx @eaglebyte/skylight-mcp \
  -e SKYLIGHT_EMAIL=your_email@example.com \
  -e SKYLIGHT_PASSWORD=your_password \
  -e SKYLIGHT_FRAME_ID=your_frame_id
```

#### Option 3: From Source
```bash
git clone https://github.com/TheEagleByte/skylight-mcp.git
cd skylight-mcp && npm install && npm run build
```

### Authentication Methods

#### Method 1: Email/Password (Recommended)
The server automatically logs in and manages tokens:
```
SKYLIGHT_EMAIL=your_email@example.com
SKYLIGHT_PASSWORD=your_password
SKYLIGHT_FRAME_ID=your_frame_id
```

#### Method 2: Manual Token (Legacy)
Capture a token from the Skylight app using a proxy tool:
```
SKYLIGHT_TOKEN=your_token_here
SKYLIGHT_FRAME_ID=your_frame_id
SKYLIGHT_AUTH_TYPE=bearer
```

### Configuration Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `SKYLIGHT_EMAIL` | Option 1 | Your Skylight account email | - |
| `SKYLIGHT_PASSWORD` | Option 1 | Your Skylight account password | - |
| `SKYLIGHT_TOKEN` | Option 2 | Your API token | - |
| `SKYLIGHT_AUTH_TYPE` | No | `bearer` or `basic` | `bearer` |
| `SKYLIGHT_FRAME_ID` | Yes | Your household frame ID | - |
| `SKYLIGHT_TIMEZONE` | No | Default timezone | `America/New_York` |

### Finding Your Frame ID
1. Use a proxy tool (Proxyman, Charles, or mitmproxy)
2. Capture any API request from the Skylight app
3. Look at the URL path: `/api/frames/{frameId}/...`
4. Example: `/api/frames/abc123/chores` → frame ID is `abc123`

### Available Tools/Endpoints

#### Calendar Tools
- `get_calendar_events` - Get calendar events for a date range
- `get_source_calendars` - List connected calendar sources (Google, iCloud, etc.)

#### Chore Tools
- `get_chores` - Get chores with optional filters (date, assignee, status)
- `create_chore` - Create a new chore with optional recurrence

#### List Tools
- `get_lists` - Get all available lists
- `get_list_items` - Get items from a specific list

#### Task Tools
- `create_task` - Add a task to the task box

#### Family Tools
- `get_family_members` - Get family member profiles
- `get_frame_info` - Get household/frame information
- `get_devices` - List Skylight devices

#### Reward Tools
- `get_rewards` - Get available rewards
- `get_reward_points` - Get reward points balance

### Example Queries
Once configured with an AI assistant, you can make queries like:
- "What's on my calendar today?"
- "What chores do I need to do this week?"
- "Add 'take out trash' to my chores for tomorrow"
- "What's on the grocery list?"
- "Add milk to my task list"
- "Who are the family members on Skylight?"
- "How many reward points does each person have?"

### Development Commands
```bash
npm run dev       # Run in development mode with hot reload
npm run build     # Build the project
npm test          # Run tests
npm run typecheck # Type check
```

### API Documentation
The MCP server is built on reverse-engineered Skylight API:
- **Interactive API Docs (Swagger UI)**: https://theeaglebyte.github.io/skylight-api/swagger.html
- **API Reference (ReDoc)**: https://theeaglebyte.github.io/skylight-api/redoc.html
- **OpenAPI Specification**: https://theeaglebyte.github.io/skylight-api/openapi/openapi.yaml
- **Source Repository**: https://github.com/TheEagleByte/skylight-api

### Important Notes
- This is an **unofficial integration**
- The Skylight API is **reverse-engineered** and may change without notice
- Use at your own risk
- Some features require Skylight Plus subscription (rewards, meals, photos)

---

## 2. Python Skylight Scraper (ramseys1990/Skylight)

### Project Information
- **Repository**: https://github.com/ramseys1990/Skylight
- **Language**: Python (100%)
- **Status**: 5 commits, appears stable but not actively maintained
- **License**: Not specified

### Description
A Python script that extracts Skylight Calendar information and generates an iCalendar (.ics) file. This is a simpler, more focused tool compared to the MCP server, specifically for calendar extraction.

### Key Features
- Automatic login to Skylight API
- Retrieves User ID and User Token
- Generates proper Auth Token
- Lists available frames
- Extracts calendar information
- Generates iCalendar (.ics) file
- Displays extraction statistics

### How It Works
1. **User Input**: Prompts for email and password
2. **Authentication**: Logs into the Skylight API and generates auth token
3. **Frame Selection**: Retrieves list of available frames and prompts user to select one
4. **Data Extraction**: Extracts calendar information from selected frame
5. **Output**: Generates an iCalendar .ics file with the extracted data
6. **Statistics**: Displays information about what was extracted

### Files
- `skylight_scrape.py` - Main Python script
- `README.md` - Documentation

### Use Cases
- Exporting Skylight calendar events to other calendar applications
- Creating backups of calendar data
- Analyzing calendar event patterns
- Migrating calendar data to other systems

### Limitations
- Author notes: "I currently only have one Skylight Calendar so I do not know what the responses for multiple frames looks like, they may all produce the same data"
- Focused only on calendar extraction (no chores, lists, tasks, etc.)
- Requires manual execution (not designed for continuous synchronization)

### Implementation Notes
The script:
- Uses the Authorization header obtained after logging in
- Programmatically logs into the Skylight API
- Retrieves User ID and User Token for authentication
- Handles frame selection for accounts with multiple Skylight devices
- Outputs standard iCalendar format for broad compatibility

---

## Comparison: MCP Server vs Python Scraper

| Feature | MCP Server | Python Scraper |
|---------|------------|----------------|
| **Primary Use** | AI assistant integration | Calendar data extraction |
| **Language** | TypeScript | Python |
| **Maintenance** | Active (Dec 2025) | Stable but older |
| **Calendar Access** | ✅ Read events | ✅ Export to .ics |
| **Chores** | ✅ View & create | ❌ |
| **Lists** | ✅ View | ❌ |
| **Tasks** | ✅ Create | ❌ |
| **Family Info** | ✅ | ❌ |
| **Rewards** | ✅ | ❌ |
| **Authentication** | Email/password or token | Email/password |
| **Output Format** | API responses | iCalendar (.ics) |
| **Integration** | MCP protocol for AI | Standalone script |
| **Installation** | NPM package | Git clone |

---

## API Architecture Notes

### Base Information
- **Protocol**: GraphQL (official API)
- **Reverse-Engineered**: Yes (both tools use unofficial API)
- **Authentication**: Bearer token or basic auth
- **Rate Limiting**: Unknown, use responsibly

### Common Endpoints Pattern
Based on the tools' documentation:
- `/api/frames/{frameId}/chores` - Chore management
- `/api/frames/{frameId}/calendar` - Calendar events
- `/api/frames/{frameId}/lists` - List management
- `/api/frames/{frameId}/tasks` - Task management
- `/api/frames/{frameId}/family` - Family member info
- `/api/frames/{frameId}/rewards` - Reward system

### Frame ID
The "Frame ID" is essentially a household identifier in the Skylight system. Each Skylight device/household has a unique frame ID that's required for API access.

---

## Recommended Approach for Your Project

### For AI Integration
Use the **Skylight MCP Server** if you want:
- Integration with Claude or other AI assistants
- Access to multiple Skylight features (calendar, chores, lists, tasks)
- Ongoing, interactive access to your Skylight data
- TypeScript/Node.js environment

### For Calendar Backup/Export
Use the **Python Scraper** if you want:
- Simple calendar data extraction
- Standard .ics file output for import into other calendar apps
- One-time or scheduled exports
- Python environment
- Minimal dependencies

### For Custom Development
Consider:
1. Starting with the MCP server's TypeScript implementation as reference
2. Using the documented API endpoints from the swagger docs
3. Implementing proper authentication (email/password recommended)
4. Adding error handling for API changes
5. Respecting rate limits and terms of service

---

## Additional Resources

### Documentation
- **Official Skylight API Overview**: https://skylight.helpjuice.com/api-documentation/an-overview-of-the-skylight-api
- **MCP Server Support**: https://github.com/TheEagleByte/skylight-mcp/issues
- **Python Scraper Issues**: https://github.com/ramseys1990/Skylight/issues

### Tools Needed
- **For Frame ID Discovery**: Proxyman, Charles Proxy, or mitmproxy
- **For Testing**: Postman or curl for API testing
- **For Development**: Node.js 18+ (MCP) or Python 3.x (scraper)

### Community
- **MCP Server Issues**: 18 open issues as of Jan 2026
- **MCP Server Discussions**: Available on GitHub
- The MCP server is more actively maintained and has better community support

---

## Security Considerations

1. **Credentials**: Both tools require your Skylight account credentials
2. **Storage**: Never commit credentials to version control
3. **Environment Variables**: Use .env files (add to .gitignore)
4. **Token Security**: Tokens should be treated as sensitive as passwords
5. **Unofficial Status**: These are reverse-engineered implementations that could break if Skylight changes their API
6. **Rate Limiting**: Be mindful of API usage to avoid potential account issues

---

## Disclaimer

Both projects are **unofficial** and use **reverse-engineered** APIs. The Skylight API may change without notice, potentially breaking these tools. Use at your own risk and ensure you comply with Skylight's terms of service.
