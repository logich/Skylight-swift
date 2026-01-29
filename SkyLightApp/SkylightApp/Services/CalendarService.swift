import Foundation

protocol CalendarServiceProtocol {
    func getEvents(frameId: String, from startDate: Date, to endDate: Date, timezone: String) async throws -> [CalendarEvent]
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
}
