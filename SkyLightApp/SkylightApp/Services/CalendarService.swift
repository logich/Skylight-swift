import Foundation

protocol CalendarServiceProtocol {
    func getEvents(frameId: String, from startDate: Date, to endDate: Date, timezone: String) async throws -> [CalendarEvent]
    func createEvent(frameId: String, event: CreateCalendarEventRequest) async throws -> CalendarEvent
    func updateEvent(frameId: String, eventId: String, event: UpdateCalendarEventRequest) async throws -> CalendarEvent
    func deleteEvent(frameId: String, eventId: String) async throws
}

final class CalendarService: CalendarServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getEvents(frameId: String, from startDate: Date, to endDate: Date, timezone: String) async throws -> [CalendarEvent] {
        let endpoint = SkylightEndpoint.getCalendarEvents(
            frameId: frameId,
            dateMin: startDate,
            dateMax: endDate,
            timezone: timezone
        )
        let response: CalendarEventsResponse = try await apiClient.request(endpoint)
        let events = response.events
        #if DEBUG
        print("CalendarService: Received \(response.data.count) raw events, parsed \(events.count) events")
        if events.isEmpty && !response.data.isEmpty {
            print("CalendarService: Events parsing failed - check date parsing")
        }
        #endif
        return events
    }

    func createEvent(frameId: String, event: CreateCalendarEventRequest) async throws -> CalendarEvent {
        let endpoint = SkylightEndpoint.createCalendarEvent(frameId: frameId, event: event)
        let response: CalendarEventResponse = try await apiClient.request(endpoint)
        return response.event
    }

    func updateEvent(frameId: String, eventId: String, event: UpdateCalendarEventRequest) async throws -> CalendarEvent {
        let endpoint = SkylightEndpoint.updateCalendarEvent(frameId: frameId, eventId: eventId, event: event)
        let response: CalendarEventResponse = try await apiClient.request(endpoint)
        return response.event
    }

    func deleteEvent(frameId: String, eventId: String) async throws {
        let endpoint = SkylightEndpoint.deleteCalendarEvent(frameId: frameId, eventId: eventId)
        try await apiClient.requestWithoutResponse(endpoint)
    }
}
