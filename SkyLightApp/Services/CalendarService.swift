import Foundation

protocol CalendarServiceProtocol {
    func getEvents(frameId: String, from startDate: Date, to endDate: Date) async throws -> [CalendarEvent]
    func getSources(frameId: String) async throws -> [CalendarSource]
}

final class CalendarService: CalendarServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getEvents(frameId: String, from startDate: Date, to endDate: Date) async throws -> [CalendarEvent] {
        let endpoint = SkylightEndpoint.getCalendarEvents(
            frameId: frameId,
            startDate: startDate,
            endDate: endDate
        )
        let response: CalendarEventsResponse = try await apiClient.request(endpoint)
        return response.events
    }

    func getSources(frameId: String) async throws -> [CalendarSource] {
        let endpoint = SkylightEndpoint.getCalendarSources(frameId: frameId)
        let response: CalendarSourcesResponse = try await apiClient.request(endpoint)
        return response.sources
    }
}
