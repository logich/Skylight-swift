# Skylight API Integration Guide

## Overview

This guide provides detailed information about integrating with the Skylight Calendar API. The API is **reverse-engineered** and **unofficial**, so implementation details may change without notice.

## Base URL
```
https://api.ourskylight.com
```

## Authentication

### Method 1: Email/Password Login (Recommended)

#### Endpoint
```
POST /api/v1/auth/login
```

#### Request
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Response
```json
{
  "userId": "user_abc123",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_xyz789",
  "expiresIn": 3600,
  "user": {
    "id": "user_abc123",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

#### Swift Implementation
```swift
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let userId: String
    let token: String
    let refreshToken: String
    let expiresIn: Int
    let user: User
}

struct User: Decodable {
    let id: String
    let email: String
    let name: String
}

func login(email: String, password: String) async throws -> LoginResponse {
    let endpoint = SkylightEndpoint.login(email: email, password: password)
    let response: LoginResponse = try await apiClient.request(endpoint)
    
    // Store token in Keychain
    try keychainManager.save(response.token, for: .authToken)
    try keychainManager.save(response.refreshToken, for: .refreshToken)
    
    return response
}
```

### Method 2: Token Refresh

#### Endpoint
```
POST /api/v1/auth/refresh
```

#### Request Headers
```
Authorization: Bearer {refreshToken}
```

#### Response
```json
{
  "token": "new_access_token",
  "expiresIn": 3600
}
```

### Authentication Headers

All authenticated requests must include:
```
Authorization: Bearer {accessToken}
```

## Frames (Households)

### Get Available Frames

#### Endpoint
```
GET /api/v1/frames
```

#### Response
```json
{
  "frames": [
    {
      "id": "frame_abc123",
      "name": "Smith Family",
      "timezone": "America/New_York",
      "createdAt": "2024-01-15T10:30:00Z",
      "memberCount": 4,
      "deviceCount": 2
    }
  ]
}
```

#### Swift Implementation
```swift
struct Frame: Decodable, Identifiable {
    let id: String
    let name: String
    let timezone: String
    let createdAt: Date
    let memberCount: Int
    let deviceCount: Int
}

struct FramesResponse: Decodable {
    let frames: [Frame]
}

func getFrames() async throws -> [Frame] {
    let response: FramesResponse = try await apiClient.request(.getFrames)
    return response.frames
}
```

### Get Frame Info

#### Endpoint
```
GET /api/v1/frames/{frameId}
```

#### Response
```json
{
  "id": "frame_abc123",
  "name": "Smith Family",
  "timezone": "America/New_York",
  "createdAt": "2024-01-15T10:30:00Z",
  "settings": {
    "timeFormat": "12h",
    "firstDayOfWeek": "sunday"
  }
}
```

## Calendar

### Get Calendar Events

#### Endpoint
```
GET /api/v1/frames/{frameId}/calendar/events
```

#### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| startDate | ISO8601 | Yes | Start date for events |
| endDate | ISO8601 | Yes | End date for events |
| calendarIds | String[] | No | Filter by specific calendar sources |

#### Example Request
```
GET /api/v1/frames/frame_abc123/calendar/events?startDate=2024-01-01T00:00:00Z&endDate=2024-01-31T23:59:59Z
```

#### Response
```json
{
  "events": [
    {
      "id": "event_123",
      "title": "Doctor Appointment",
      "startDate": "2024-01-15T14:00:00Z",
      "endDate": "2024-01-15T15:00:00Z",
      "isAllDay": false,
      "location": "Main Street Clinic",
      "description": "Annual checkup",
      "color": "#FF5733",
      "source": {
        "id": "cal_google_1",
        "name": "John's Calendar",
        "type": "google"
      },
      "attendees": ["john@example.com", "jane@example.com"],
      "recurrence": null
    },
    {
      "id": "event_124",
      "title": "Birthday Party",
      "startDate": "2024-01-20T00:00:00Z",
      "endDate": "2024-01-20T23:59:59Z",
      "isAllDay": true,
      "location": null,
      "description": "Emma's 10th birthday",
      "color": "#3498DB",
      "source": {
        "id": "cal_icloud_1",
        "name": "Family Calendar",
        "type": "icloud"
      },
      "attendees": [],
      "recurrence": null
    }
  ]
}
```

#### Swift Implementation
```swift
struct CalendarEvent: Decodable, Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
    let location: String?
    let description: String?
    let color: String?
    let source: CalendarSource?
    let attendees: [String]?
    let recurrence: RecurrenceRule?
}

struct CalendarSource: Decodable {
    let id: String
    let name: String
    let type: String
}

struct CalendarEventsResponse: Decodable {
    let events: [CalendarEvent]
}

func getCalendarEvents(
    frameId: String,
    from startDate: Date,
    to endDate: Date
) async throws -> [CalendarEvent] {
    let endpoint = SkylightEndpoint.getCalendarEvents(
        frameId: frameId,
        startDate: startDate,
        endDate: endDate
    )
    let response: CalendarEventsResponse = try await apiClient.request(endpoint)
    return response.events
}
```

### Get Source Calendars

#### Endpoint
```
GET /api/v1/frames/{frameId}/calendar/sources
```

#### Response
```json
{
  "sources": [
    {
      "id": "cal_google_1",
      "name": "John's Google Calendar",
      "type": "google",
      "email": "john@gmail.com",
      "color": "#4285F4",
      "isEnabled": true,
      "lastSyncedAt": "2024-01-27T10:30:00Z"
    },
    {
      "id": "cal_icloud_1",
      "name": "Family iCloud Calendar",
      "type": "icloud",
      "email": "family@icloud.com",
      "color": "#000000",
      "isEnabled": true,
      "lastSyncedAt": "2024-01-27T10:25:00Z"
    }
  ]
}
```

## Chores

### Get Chores

#### Endpoint
```
GET /api/v1/frames/{frameId}/chores
```

#### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| assignedTo | String | No | Filter by family member ID |
| startDate | ISO8601 | No | Filter chores after this date |
| endDate | ISO8601 | No | Filter chores before this date |
| status | String | No | Filter by status: pending, completed, overdue |

#### Example Request
```
GET /api/v1/frames/frame_abc123/chores?status=pending&assignedTo=member_456
```

#### Response
```json
{
  "chores": [
    {
      "id": "chore_789",
      "title": "Take out trash",
      "description": "Empty all trash cans and take to curb",
      "assignedTo": "member_456",
      "assignedToName": "Emma",
      "dueDate": "2024-01-28T20:00:00Z",
      "isCompleted": false,
      "completedDate": null,
      "completedBy": null,
      "recurrence": {
        "frequency": "weekly",
        "interval": 1,
        "daysOfWeek": ["wednesday", "saturday"],
        "endDate": null,
        "occurrences": null
      },
      "points": 10,
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### Swift Implementation
```swift
struct Chore: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let assignedTo: String?
    let assignedToName: String?
    let dueDate: Date?
    let isCompleted: Bool
    let completedDate: Date?
    let completedBy: String?
    let recurrence: RecurrenceRule?
    let points: Int?
    let createdAt: Date
    let updatedAt: Date
}

struct RecurrenceRule: Decodable {
    let frequency: String
    let interval: Int
    let daysOfWeek: [String]?
    let endDate: Date?
    let occurrences: Int?
}

struct ChoresResponse: Decodable {
    let chores: [Chore]
}

func getChores(
    frameId: String,
    filters: ChoreFilters?
) async throws -> [Chore] {
    let endpoint = SkylightEndpoint.getChores(frameId: frameId, filters: filters)
    let response: ChoresResponse = try await apiClient.request(endpoint)
    return response.chores
}
```

### Create Chore

#### Endpoint
```
POST /api/v1/frames/{frameId}/chores
```

#### Request Body
```json
{
  "title": "Water plants",
  "description": "Water all indoor plants",
  "assignedTo": "member_456",
  "dueDate": "2024-01-30T18:00:00Z",
  "recurrence": {
    "frequency": "weekly",
    "interval": 1,
    "daysOfWeek": ["monday", "thursday"]
  },
  "points": 5
}
```

#### Response
Returns the created chore object (same structure as Get Chores).

#### Swift Implementation
```swift
struct ChoreRequest: Encodable {
    let title: String
    let description: String?
    let assignedTo: String?
    let dueDate: Date?
    let recurrence: RecurrenceRule?
    let points: Int?
}

func createChore(
    frameId: String,
    chore: ChoreRequest
) async throws -> Chore {
    let endpoint = SkylightEndpoint.createChore(frameId: frameId, chore: chore)
    return try await apiClient.request(endpoint)
}
```

### Update Chore

#### Endpoint
```
PATCH /api/v1/frames/{frameId}/chores/{choreId}
```

#### Request Body
```json
{
  "isCompleted": true,
  "completedDate": "2024-01-27T15:30:00Z"
}
```

#### Response
Returns the updated chore object.

### Delete Chore

#### Endpoint
```
DELETE /api/v1/frames/{frameId}/chores/{choreId}
```

#### Response
```json
{
  "success": true,
  "message": "Chore deleted successfully"
}
```

## Lists

### Get All Lists

#### Endpoint
```
GET /api/v1/frames/{frameId}/lists
```

#### Response
```json
{
  "lists": [
    {
      "id": "list_123",
      "name": "Grocery List",
      "type": "grocery",
      "itemCount": 12,
      "checkedCount": 5,
      "createdAt": "2024-01-15T10:00:00Z"
    },
    {
      "id": "list_124",
      "name": "To Do",
      "type": "todo",
      "itemCount": 8,
      "checkedCount": 3,
      "createdAt": "2024-01-10T08:00:00Z"
    }
  ]
}
```

### Get List Items

#### Endpoint
```
GET /api/v1/frames/{frameId}/lists/{listId}/items
```

#### Response
```json
{
  "list": {
    "id": "list_123",
    "name": "Grocery List",
    "type": "grocery"
  },
  "items": [
    {
      "id": "item_456",
      "title": "Milk",
      "isChecked": false,
      "quantity": "1 gallon",
      "notes": "2% or whole milk",
      "addedBy": "member_789",
      "addedByName": "John",
      "addedAt": "2024-01-25T14:20:00Z"
    },
    {
      "id": "item_457",
      "title": "Bread",
      "isChecked": true,
      "quantity": "2 loaves",
      "notes": null,
      "addedBy": "member_456",
      "addedByName": "Emma",
      "addedAt": "2024-01-24T09:15:00Z"
    }
  ]
}
```

#### Swift Implementation
```swift
struct ShoppingList: Decodable, Identifiable {
    let id: String
    let name: String
    let type: String
    let itemCount: Int
    let checkedCount: Int
    let createdAt: Date
}

struct ListItem: Decodable, Identifiable {
    let id: String
    let title: String
    let isChecked: Bool
    let quantity: String?
    let notes: String?
    let addedBy: String?
    let addedByName: String?
    let addedAt: Date
}

struct ListItemsResponse: Decodable {
    let list: ShoppingList
    let items: [ListItem]
}

func getListItems(
    frameId: String,
    listId: String
) async throws -> ListItemsResponse {
    let endpoint = SkylightEndpoint.getListItems(frameId: frameId, listId: listId)
    return try await apiClient.request(endpoint)
}
```

### Add List Item

#### Endpoint
```
POST /api/v1/frames/{frameId}/lists/{listId}/items
```

#### Request Body
```json
{
  "title": "Eggs",
  "quantity": "1 dozen",
  "notes": "Free range if available"
}
```

#### Response
Returns the created list item object.

### Update List Item

#### Endpoint
```
PATCH /api/v1/frames/{frameId}/lists/{listId}/items/{itemId}
```

#### Request Body
```json
{
  "isChecked": true
}
```

#### Response
Returns the updated list item object.

## Tasks

### Create Task

#### Endpoint
```
POST /api/v1/frames/{frameId}/tasks
```

#### Request Body
```json
{
  "title": "Call plumber about leak",
  "description": "Kitchen sink is leaking under the cabinet",
  "priority": "high"
}
```

#### Response
```json
{
  "id": "task_101",
  "title": "Call plumber about leak",
  "description": "Kitchen sink is leaking under the cabinet",
  "priority": "high",
  "createdBy": "member_789",
  "createdByName": "John",
  "createdAt": "2024-01-27T10:30:00Z",
  "status": "pending"
}
```

#### Swift Implementation
```swift
struct Task: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let priority: String?
    let createdBy: String?
    let createdByName: String?
    let createdAt: Date
    let status: String
}

struct TaskRequest: Encodable {
    let title: String
    let description: String?
    let priority: String?
}

func createTask(
    frameId: String,
    task: TaskRequest
) async throws -> Task {
    let endpoint = SkylightEndpoint.createTask(frameId: frameId, task: task)
    return try await apiClient.request(endpoint)
}
```

### Get Tasks

#### Endpoint
```
GET /api/v1/frames/{frameId}/tasks
```

#### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | String | No | Filter by status: pending, completed |
| limit | Int | No | Limit number of results (default: 50) |

#### Response
```json
{
  "tasks": [
    {
      "id": "task_101",
      "title": "Call plumber about leak",
      "description": "Kitchen sink is leaking",
      "priority": "high",
      "createdBy": "member_789",
      "createdByName": "John",
      "createdAt": "2024-01-27T10:30:00Z",
      "status": "pending"
    }
  ]
}
```

## Family

### Get Family Members

#### Endpoint
```
GET /api/v1/frames/{frameId}/family/members
```

#### Response
```json
{
  "members": [
    {
      "id": "member_789",
      "name": "John Smith",
      "email": "john@example.com",
      "role": "parent",
      "avatarURL": "https://cdn.ourskylight.com/avatars/member_789.jpg",
      "rewardPoints": 150,
      "isAdmin": true,
      "joinedAt": "2024-01-01T00:00:00Z"
    },
    {
      "id": "member_456",
      "name": "Emma Smith",
      "email": null,
      "role": "child",
      "avatarURL": "https://cdn.ourskylight.com/avatars/member_456.jpg",
      "rewardPoints": 85,
      "isAdmin": false,
      "joinedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### Swift Implementation
```swift
struct FamilyMember: Decodable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let role: String
    let avatarURL: String?
    let rewardPoints: Int?
    let isAdmin: Bool
    let joinedAt: Date
}

struct FamilyMembersResponse: Decodable {
    let members: [FamilyMember]
}

func getFamilyMembers(frameId: String) async throws -> [FamilyMember] {
    let endpoint = SkylightEndpoint.getFamilyMembers(frameId: frameId)
    let response: FamilyMembersResponse = try await apiClient.request(endpoint)
    return response.members
}
```

### Get Devices

#### Endpoint
```
GET /api/v1/frames/{frameId}/devices
```

#### Response
```json
{
  "devices": [
    {
      "id": "device_abc",
      "name": "Kitchen Calendar",
      "type": "calendar",
      "status": "online",
      "lastSeenAt": "2024-01-27T11:45:00Z",
      "firmwareVersion": "2.1.5"
    },
    {
      "id": "device_def",
      "name": "Living Room Frame",
      "type": "frame",
      "status": "online",
      "lastSeenAt": "2024-01-27T11:50:00Z",
      "firmwareVersion": "2.1.5"
    }
  ]
}
```

## Rewards (Skylight Plus Feature)

### Get Rewards

#### Endpoint
```
GET /api/v1/frames/{frameId}/rewards
```

#### Response
```json
{
  "rewards": [
    {
      "id": "reward_111",
      "title": "30 minutes extra screen time",
      "description": "Redeem for additional screen time",
      "pointCost": 50,
      "imageURL": "https://cdn.ourskylight.com/rewards/screen_time.jpg",
      "isAvailable": true,
      "category": "privileges"
    },
    {
      "id": "reward_112",
      "title": "Ice cream outing",
      "description": "Trip to favorite ice cream shop",
      "pointCost": 100,
      "imageURL": "https://cdn.ourskylight.com/rewards/ice_cream.jpg",
      "isAvailable": true,
      "category": "treats"
    }
  ]
}
```

### Get Reward Points

#### Endpoint
```
GET /api/v1/frames/{frameId}/rewards/points
```

#### Response
```json
{
  "memberPoints": [
    {
      "memberId": "member_456",
      "memberName": "Emma",
      "totalPoints": 85,
      "earnedThisWeek": 25,
      "earnedThisMonth": 85
    },
    {
      "memberId": "member_457",
      "memberName": "Jack",
      "totalPoints": 62,
      "earnedThisWeek": 15,
      "earnedThisMonth": 62
    }
  ]
}
```

## Error Responses

All error responses follow this format:

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired authentication token",
    "details": {
      "timestamp": "2024-01-27T12:00:00Z"
    }
  }
}
```

### Common Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | INVALID_REQUEST | Malformed request body or parameters |
| 401 | UNAUTHORIZED | Missing or invalid authentication token |
| 403 | FORBIDDEN | Insufficient permissions |
| 404 | NOT_FOUND | Resource not found |
| 409 | CONFLICT | Resource conflict (e.g., duplicate) |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests |
| 500 | INTERNAL_ERROR | Server error |
| 503 | SERVICE_UNAVAILABLE | Service temporarily unavailable |

## Rate Limiting

Rate limits are not officially documented. Best practices:

- Cache responses aggressively
- Implement exponential backoff on errors
- Don't poll more frequently than once per minute
- Watch for 429 responses
- Implement request queuing

## Date Formatting

All dates use ISO 8601 format with timezone:
```
2024-01-27T14:30:00Z          // UTC
2024-01-27T09:30:00-05:00     // EST
```

### Swift Date Handling
```swift
let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

// Encoding
let jsonEncoder = JSONEncoder()
jsonEncoder.dateEncodingStrategy = .iso8601

// Decoding
let jsonDecoder = JSONDecoder()
jsonDecoder.dateDecodingStrategy = .iso8601
```

## Testing Endpoints

Use tools like:
- **Postman**: Import OpenAPI spec for easy testing
- **Charles Proxy**: Inspect actual app traffic
- **Proxyman**: macOS-specific alternative
- **curl**: Command-line testing

Example curl request:
```bash
curl -X GET \
  'https://api.ourskylight.com/api/v1/frames/frame_abc123/chores' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json'
```

## API Versioning

The API uses URL path versioning:
```
/api/v1/...
```

Currently, only v1 is available. Watch for version changes.

## Best Practices

1. **Always handle errors gracefully**
   - Network errors
   - Authentication errors
   - Parsing errors
   - Business logic errors

2. **Cache appropriately**
   - Family members (changes rarely)
   - Frame info (changes rarely)
   - Calendar events (cache for session)
   - Chores (cache for session)

3. **Refresh tokens proactively**
   - Refresh before expiration
   - Handle 401 responses gracefully
   - Store refresh tokens securely

4. **Respect the API**
   - Don't hammer endpoints
   - Implement backoff strategies
   - Cache when possible
   - Batch requests if API supports it

5. **Log strategically**
   - Log all API errors in production
   - Log requests/responses in debug
   - Never log sensitive data (tokens, passwords)
   - Use structured logging

## Important Reminders

- This API is **unofficial** and **reverse-engineered**
- May change without notice
- No official support
- Use at your own risk
- Respect Skylight's terms of service
- Consider reaching out to Skylight for official API access
