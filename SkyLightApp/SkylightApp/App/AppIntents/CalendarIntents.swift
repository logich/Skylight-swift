import AppIntents
import Foundation

// MARK: - Calendar Event Entity

struct CalendarEventEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Calendar Event"
    static var defaultQuery = CalendarEventQuery()

    var id: String

    @Property(title: "Title")
    var title: String

    @Property(title: "Start Date")
    var startDate: Date

    @Property(title: "End Date")
    var endDate: Date

    @Property(title: "Location")
    var location: String

    @Property(title: "Is All Day")
    var isAllDay: Bool

    @Property(title: "Attendees")
    var attendees: String

    @Property(title: "Duration (Minutes)")
    var durationMinutes: Int

    var displayRepresentation: DisplayRepresentation {
        let subtitle = isAllDay ? "All day" : startDate.formatted(date: .omitted, time: .shortened)
        return DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }

    init(from event: CalendarEvent) {
        self.id = event.id
        self.title = event.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.location = event.location ?? ""
        self.isAllDay = event.isAllDay
        self.attendees = event.attendees.map { $0.name }.joined(separator: ", ")
        self.durationMinutes = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
    }
}

struct CalendarEventQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CalendarEventEntity] {
        guard let frameId = await AuthenticationManager.shared.currentFrameId else {
            throw IntentError.notLoggedIn
        }

        #if DEBUG
        print("CalendarEventQuery: Fetching entities for \(identifiers.count) identifier(s): \(identifiers)")
        #endif

        // Fetch events from a 3-month window (1 month back, 2 months forward)
        // This matches the approach used in CalendarViewModel.fetchEvent(byId:)
        let service = CalendarService()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .month, value: 2, to: Date()) ?? Date()

        let allEvents = try await service.getEvents(
            frameId: frameId,
            from: startDate,
            to: endDate,
            timezone: TimeZone.current.identifier
        )

        #if DEBUG
        print("CalendarEventQuery: Fetched \(allEvents.count) events from API")
        #endif

        // Filter to only requested event IDs
        let matchingEvents = allEvents.filter { identifiers.contains($0.id) }

        #if DEBUG
        print("CalendarEventQuery: Found \(matchingEvents.count) matching event(s)")
        #endif

        return matchingEvents.map { CalendarEventEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [CalendarEventEntity] {
        let events = try await IntentCalendarHelper.fetchTodayEvents()
        return events.map { CalendarEventEntity(from: $0) }
    }
}

// MARK: - Intent Calendar Helper

@MainActor
enum IntentCalendarHelper {
    static func fetchTodayEvents() async throws -> [CalendarEvent] {
        guard let frameId = AuthenticationManager.shared.currentFrameId else {
            throw IntentError.notLoggedIn
        }

        let service = CalendarService()
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? today

        return try await service.getEvents(
            frameId: frameId,
            from: startOfDay,
            to: tomorrow,
            timezone: TimeZone.current.identifier
        )
    }

    static func fetchEventsForDate(_ date: Date) async throws -> [CalendarEvent] {
        guard let frameId = AuthenticationManager.shared.currentFrameId else {
            throw IntentError.notLoggedIn
        }

        let service = CalendarService()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        return try await service.getEvents(
            frameId: frameId,
            from: startOfDay,
            to: endOfDay,
            timezone: TimeZone.current.identifier
        )
    }

    static func fetchUpcomingEvents(days: Int) async throws -> [CalendarEvent] {
        guard let frameId = AuthenticationManager.shared.currentFrameId else {
            throw IntentError.notLoggedIn
        }

        let service = CalendarService()
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        return try await service.getEvents(
            frameId: frameId,
            from: today,
            to: endDate,
            timezone: TimeZone.current.identifier
        )
    }

    /// Fetches events starting within the specified number of minutes from now
    /// Excludes all-day events by default since they don't have specific start times
    static func fetchEventsStartingWithin(minutes: Int, includeAllDay: Bool = false) async throws -> [CalendarEvent] {
        guard let frameId = AuthenticationManager.shared.currentFrameId else {
            throw IntentError.notLoggedIn
        }

        let service = CalendarService()
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now

        // Fetch events for today and tomorrow to handle edge cases near midnight
        let startOfDay = Calendar.current.startOfDay(for: now)
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: startOfDay) ?? now

        let allEvents = try await service.getEvents(
            frameId: frameId,
            from: startOfDay,
            to: dayAfterTomorrow,
            timezone: TimeZone.current.identifier
        )

        // Filter to events starting between now and the end time
        return allEvents.filter { event in
            // Skip all-day events unless explicitly included
            if event.isAllDay && !includeAllDay {
                return false
            }
            // Event must start after now and within the time window
            return event.startDate > now && event.startDate <= endTime
        }.sorted { $0.startDate < $1.startDate }
    }

    /// Gets the next upcoming event (non-all-day) that hasn't started yet
    static func fetchNextEvent(includeAllDay: Bool = false) async throws -> CalendarEvent? {
        guard let frameId = AuthenticationManager.shared.currentFrameId else {
            throw IntentError.notLoggedIn
        }

        let service = CalendarService()
        let now = Date()

        // Look ahead 7 days to find the next event
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now

        let allEvents = try await service.getEvents(
            frameId: frameId,
            from: now,
            to: endDate,
            timezone: TimeZone.current.identifier
        )

        // Find the first event that starts after now
        return allEvents
            .filter { event in
                if event.isAllDay && !includeAllDay {
                    return false
                }
                return event.startDate > now
            }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
}

// MARK: - Get Today's Events Intent

struct GetTodayEventsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Skylight Events"
    static var description = IntentDescription("Returns all calendar events scheduled for today from your Skylight.")

    static var parameterSummary: some ParameterSummary {
        Summary("Get today's Skylight events")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[CalendarEventEntity]> {
        let events = try await IntentCalendarHelper.fetchTodayEvents()
        let entities = events.map { CalendarEventEntity(from: $0) }
        return .result(value: entities)
    }
}

// MARK: - Get Events for Date Intent

struct GetEventsForDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Skylight Events for Date"
    static var description = IntentDescription("Returns all calendar events for a specific date from your Skylight.")

    @Parameter(title: "Date")
    var date: Date

    static var parameterSummary: some ParameterSummary {
        Summary("Get Skylight events for \(\.$date)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[CalendarEventEntity]> {
        let events = try await IntentCalendarHelper.fetchEventsForDate(date)
        let entities = events.map { CalendarEventEntity(from: $0) }
        return .result(value: entities)
    }
}

// MARK: - Get Upcoming Events Intent

struct GetUpcomingEventsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Upcoming Skylight Events"
    static var description = IntentDescription("Returns calendar events for the next several days from your Skylight.")

    @Parameter(title: "Number of Days", default: 7)
    var days: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Get Skylight events for the next \(\.$days) days")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[CalendarEventEntity]> {
        let events = try await IntentCalendarHelper.fetchUpcomingEvents(days: days)
        let entities = events.map { CalendarEventEntity(from: $0) }
        return .result(value: entities)
    }
}

// MARK: - Get Next Event Intent

struct GetNextEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Next Skylight Event"
    static var description = IntentDescription("Returns the next upcoming calendar event from your Skylight. Useful for checking what's coming up next.")

    @Parameter(title: "Include All-Day Events", default: false)
    var includeAllDay: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Get next Skylight event") {
            \.$includeAllDay
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<CalendarEventEntity?> {
        guard let event = try await IntentCalendarHelper.fetchNextEvent(includeAllDay: includeAllDay) else {
            return .result(value: nil)
        }
        return .result(value: CalendarEventEntity(from: event))
    }
}

// MARK: - Get Events Starting Within Intent

struct GetEventsStartingWithinIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Skylight Events Starting Soon"
    static var description = IntentDescription("Returns calendar events starting within the specified number of minutes. Perfect for automation triggers like 'start car climate control if I have an event in 30 minutes'.")

    @Parameter(title: "Minutes", default: 30)
    var minutes: Int

    @Parameter(title: "Include All-Day Events", default: false)
    var includeAllDay: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Get Skylight events starting within \(\.$minutes) minutes") {
            \.$includeAllDay
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[CalendarEventEntity]> {
        let events = try await IntentCalendarHelper.fetchEventsStartingWithin(
            minutes: minutes,
            includeAllDay: includeAllDay
        )
        let entities = events.map { CalendarEventEntity(from: $0) }
        return .result(value: entities)
    }
}

// MARK: - Has Upcoming Event Intent

struct HasUpcomingEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Check If Skylight Event Starting Soon"
    static var description = IntentDescription("Returns true if there's a calendar event starting within the specified minutes. Ideal for conditional automations like 'IF event starting soon THEN start car climate'.")

    @Parameter(title: "Minutes", default: 30)
    var minutes: Int

    @Parameter(title: "Include All-Day Events", default: false)
    var includeAllDay: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Check if Skylight event starting within \(\.$minutes) minutes") {
            \.$includeAllDay
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let events = try await IntentCalendarHelper.fetchEventsStartingWithin(
            minutes: minutes,
            includeAllDay: includeAllDay
        )
        return .result(value: !events.isEmpty)
    }
}

// MARK: - Get Minutes Until Next Event Intent

struct GetMinutesUntilNextEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Minutes Until Next Skylight Event"
    static var description = IntentDescription("Returns the number of minutes until the next calendar event starts. Returns -1 if no upcoming events. Useful for conditional logic in Shortcuts.")

    @Parameter(title: "Include All-Day Events", default: false)
    var includeAllDay: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Get minutes until next Skylight event") {
            \.$includeAllDay
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        guard let event = try await IntentCalendarHelper.fetchNextEvent(includeAllDay: includeAllDay) else {
            return .result(value: -1)
        }

        let now = Date()
        let minutes = Int(event.startDate.timeIntervalSince(now) / 60)
        return .result(value: max(0, minutes))
    }
}

// MARK: - Intent Errors

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notLoggedIn
    case noFrameSelected

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notLoggedIn:
            return "Please open Skylight and log in first."
        case .noFrameSelected:
            return "Please open Skylight and select a frame first."
        }
    }
}

// MARK: - App Shortcuts Provider

struct SkylightShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTodayEventsIntent(),
            phrases: [
                "Get today's \(.applicationName) events",
                "What's on my \(.applicationName) today",
                "Show \(.applicationName) calendar for today"
            ],
            shortTitle: "Today's Events",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: GetUpcomingEventsIntent(),
            phrases: [
                "Get upcoming \(.applicationName) events",
                "What's coming up on \(.applicationName)",
                "Show \(.applicationName) schedule"
            ],
            shortTitle: "Upcoming Events",
            systemImageName: "calendar.badge.clock"
        )

        AppShortcut(
            intent: GetNextEventIntent(),
            phrases: [
                "Get my next \(.applicationName) event",
                "What's next on \(.applicationName)",
                "When is my next \(.applicationName) event"
            ],
            shortTitle: "Next Event",
            systemImageName: "calendar.badge.exclamationmark"
        )

        AppShortcut(
            intent: GetEventsStartingWithinIntent(),
            phrases: [
                "Get \(.applicationName) events starting soon",
                "Any \(.applicationName) events coming up soon",
                "Check \(.applicationName) for events starting soon"
            ],
            shortTitle: "Events Starting Soon",
            systemImageName: "clock.badge.exclamationmark"
        )

        AppShortcut(
            intent: HasUpcomingEventIntent(),
            phrases: [
                "Do I have a \(.applicationName) event soon",
                "Check if \(.applicationName) event starting soon",
                "Is there a \(.applicationName) event coming up"
            ],
            shortTitle: "Event Starting Soon?",
            systemImageName: "questionmark.circle"
        )

        AppShortcut(
            intent: GetMinutesUntilNextEventIntent(),
            phrases: [
                "How long until my next \(.applicationName) event",
                "Minutes until next \(.applicationName) event",
                "Time until next \(.applicationName) event"
            ],
            shortTitle: "Time Until Next Event",
            systemImageName: "timer"
        )
    }
}
