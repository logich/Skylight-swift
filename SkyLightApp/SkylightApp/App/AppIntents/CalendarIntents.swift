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
        []
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
    }
}
