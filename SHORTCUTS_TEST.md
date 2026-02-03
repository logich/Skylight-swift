# Correct Shortcuts Testing Guide

## Understanding Entity Query

The `entities(for identifiers:)` function is called by iOS when it needs to "resolve" or "re-hydrate" an event entity by its ID. This happens in specific scenarios:

1. **Cross-shortcut references** - When you pass an entity to another shortcut
2. **Persistence** - When Shortcuts restores a saved entity
3. **Parameter resolution** - When an action parameter expects a specific entity

## Practical Tests

### Test 1: Basic Event List ✅ Easy to verify

**Shortcut:**
```
Get Today's Skylight Events
→ Show Result
```

**What this tests:** The `suggestedEntities()` function (already working)

**Expected:** List of today's events with titles and times

---

### Test 2: Access Event Properties ✅ Tests entity structure

**Shortcut:**
```
Get Today's Skylight Events
→ Repeat with Each [item]
  → Get "Title" from [Repeat Item]
  → Get "Start Date" from [Repeat Item]
  → Show Result: "[Title] at [Start Date]"
```

**What this tests:** Entity properties are accessible

**Expected:** Each event shows "Meeting at 2:00 PM" format

---

### Test 3: Conditional Logic ✅ Tests entity values

**Shortcut:**
```
Get Next Skylight Event
→ If [Next Event] has any value
  → Get "Title" from [Next Event]
  → Get "Location" from [Next Event]
  → Show Notification: "Next: [Title] at [Location]"
→ Otherwise
  → Show Notification: "No upcoming events"
```

**What this tests:** Single entity resolution and property access

**Expected:** Notification with next event details or "no events" message

---

### Test 4: Multiple Intents Chained ✅ Tests entity passing

**Shortcut:**
```
Get Upcoming Skylight Events (days: 7)
→ Repeat with Each [item]
  → Get "Title" from [Repeat Item]
  → Get "Duration Minutes" from [Repeat Item]
  → Text: "[Title] - [Duration Minutes] minutes"
  → Add to variable "Event List"
→ Show Result: [Event List]
```

**What this tests:** Multiple entity resolutions in a loop

**Expected:** List like "Meeting - 60 minutes\nLunch - 30 minutes"

---

### Test 5: Advanced - Entity Filtering ✅ Real-world usage

**Shortcut:**
```
Get Upcoming Skylight Events (days: 7)
→ Repeat with Each [item]
  → Get "Location" from [Repeat Item]
  → If [Location] has any value
    → Get "Title" from [Repeat Item]
    → Add to variable "Events with Location"
→ Show Result: [Events with Location]
```

**What this tests:** Filtering based on entity properties

**Expected:** Only events that have a location

---

### Test 6: Voice Integration ✅ Siri testing

**Just ask Siri:**
- "What's next on Skylight?"
- "Get today's Skylight events"
- "How long until my next Skylight event?"

**What this tests:** Voice phrases and entity resolution through Siri

**Expected:** Siri speaks the event information

---

## When `entities(for identifiers:)` is Actually Called

The function you implemented is called in these scenarios:

### Scenario A: Entity Persistence
```
Day 1: Get Today's Events → Save event ID somewhere
Day 2: Shortcuts tries to restore that event → calls entities(for identifiers:)
```

### Scenario B: Cross-Shortcut Communication
```
Shortcut A: Get Next Event → Return to Shortcut B
Shortcut B: Receives event → calls entities(for identifiers:) to resolve it
```

### Scenario C: Parameter Resolution (Future)
If you create custom intents that take CalendarEventEntity as a parameter:
```swift
struct CustomIntent: AppIntent {
    @Parameter(title: "Event")
    var event: CalendarEventEntity

    // When user selects an event, entities(for identifiers:) is called
}
```

---

## How to Verify It's Working

### Option 1: Check Console Logs ✅

While running shortcuts, watch for:
```bash
./watch_intent_logs.sh
```

Look for:
```
CalendarEventQuery: Fetching entities for X identifier(s): [...]
CalendarEventQuery: Fetched X events from API
CalendarEventQuery: Found X matching event(s)
```

**Note:** You might NOT see these logs for basic shortcuts because `suggestedEntities()` provides the entities directly. The `entities(for identifiers:)` is more of a fallback/resolution mechanism.

### Option 2: Add More Logging

The function IS working correctly if:
1. ✅ Shortcuts show your events
2. ✅ You can access event properties (title, date, location, etc.)
3. ✅ No errors occur when using events in shortcuts
4. ✅ Siri can read event information

### Option 3: Force Entity Resolution (Advanced)

To force `entities(for identifiers:)` to be called, you'd need to:

1. Create a custom intent that accepts `CalendarEventEntity` as parameter
2. Or test cross-shortcut entity passing (complex setup)
3. Or wait for iOS to need to re-hydrate saved entities

---

## Recommended Test Sequence

Run these in order:

1. ✅ **Test 1** - Verify basic event fetching works
2. ✅ **Test 2** - Verify all event properties are accessible
3. ✅ **Test 3** - Verify single event (Next Event) works
4. ✅ **Test 6** - Test Siri voice integration
5. ✅ **Test 4** - Test multiple events with filtering

If all these work, your implementation is correct! The `entities(for identifiers:)` function will be called automatically when iOS needs it.

---

## What Success Looks Like

### ✅ All properties work:
- id ✓
- title ✓
- startDate ✓
- endDate ✓
- location ✓
- attendees ✓
- isAllDay ✓
- durationMinutes ✓

### ✅ All intents work:
- Get Today's Events ✓
- Get Events for Date ✓
- Get Upcoming Events ✓
- Get Next Event ✓
- Get Events Starting Soon ✓
- Check If Event Starting Soon ✓
- Get Minutes Until Next Event ✓

### ✅ No errors:
- Logged in → works ✓
- Not logged in → proper error message ✓
- No events → returns empty gracefully ✓

If all above work, **your implementation is complete and correct!**
