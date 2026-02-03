# Manual Testing Guide for Calendar Intents

## Prerequisites
1. Build and run the app
2. Log in with your Skylight credentials
3. Select a frame (household)
4. Ensure you have some calendar events

## Test Steps

### Test 1: Basic Shortcuts Integration
1. Open **Shortcuts** app on your simulator/device
2. Tap **+** to create new shortcut
3. Search for "Skylight"
4. You should see multiple Skylight actions:
   - Get Today's Skylight Events
   - Get Skylight Events for Date
   - Get Upcoming Skylight Events
   - Get Next Skylight Event
   - Get Skylight Events Starting Soon
   - Check If Skylight Event Starting Soon
   - Get Minutes Until Next Skylight Event

### Test 2: Get Today's Events (Basic functionality)
1. Add "Get Today's Skylight Events" action
2. Add "Show Result" action below it
3. Run the shortcut
4. **Expected**: List of today's events with titles and times

### Test 3: Test Entity Query (This tests our new implementation!)
1. Create a new shortcut
2. Add "Get Today's Skylight Events"
3. Add "Repeat with Each" and select the events from step 2
4. Inside the repeat:
   - Add "Get Details of [Repeat Item]"
   - Add "Show [Details]"
5. Run the shortcut

**What happens**: When Shortcuts tries to "Get Details of" each event, it calls our new `entities(for identifiers:)` function to resolve the event by its ID.

6. **Check Xcode Console** for logs:
```
CalendarEventQuery: Fetching entities for 1 identifier(s): ["event-abc123"]
CalendarEventQuery: Fetched 47 events from API
CalendarEventQuery: Found 1 matching event(s)
```

### Test 4: Event Not Found
1. This is harder to test manually, but the function should return empty array for invalid IDs
2. The function handles this gracefully - no crash, just empty results

### Test 5: Not Logged In
1. Log out of the app
2. Try running any Skylight shortcut
3. **Expected**: Error message "Please open Skylight and log in first."

### Test 6: Voice Testing (Siri)
1. Say "Hey Siri, what's next on Skylight?"
2. **Expected**: Siri tells you about your next event

## What to Verify

✅ All 7 Shortcut actions appear in Shortcuts app
✅ Actions return data (not empty/error)
✅ Event details can be accessed (tests entity query)
✅ Debug logs appear in Xcode console
✅ Error handling works (when not logged in)

## Debugging

If something doesn't work:
1. Check Xcode console for errors
2. Make sure you're logged in
3. Make sure you have events in your calendar
4. Try rebuilding the app
5. Check Console.app for additional logs (filter by "Skylight")

## Expected Console Output

```
CalendarEventQuery: Fetching entities for 2 identifier(s): ["event-1", "event-2"]
CalendarEventQuery: Fetched 87 events from API
CalendarEventQuery: Found 2 matching event(s)
```

This confirms:
- Function was called
- Date range was correct (fetched events)
- Filtering worked (found the right events)
- Return value was correct
