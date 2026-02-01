import XCTest
@testable import SkylightApp

@MainActor
final class CalendarServiceTests: XCTestCase {

    var mockAPIClient: MockAPIClient!
    var sut: CalendarService!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = CalendarService(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        mockAPIClient = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - getEvents Tests

    func testGetEvents_ReturnsEventsFromAPI() async throws {
        // Given
        let expectedEvents = [
            TestDataFactory.makeCalendarEvent(id: "1", title: "Event 1"),
            TestDataFactory.makeCalendarEvent(id: "2", title: "Event 2")
        ]

        // Create a mock response matching the JSON:API structure
        let response = makeCalendarEventsResponse(events: expectedEvents)
        mockAPIClient.responseToReturn = response

        // When
        let events = try await sut.getEvents(
            frameId: "frame-123",
            from: Date(),
            to: Date().addingTimeInterval(86400),
            timezone: "America/New_York"
        )

        // Then
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].title, "Event 1")
        XCTAssertEqual(events[1].title, "Event 2")
    }

    func testGetEvents_WithEmptyResponse_ReturnsEmptyArray() async throws {
        // Given
        let response = makeCalendarEventsResponse(events: [])
        mockAPIClient.responseToReturn = response

        // When
        let events = try await sut.getEvents(
            frameId: "frame-123",
            from: Date(),
            to: Date().addingTimeInterval(86400),
            timezone: "America/New_York"
        )

        // Then
        XCTAssertTrue(events.isEmpty)
    }

    func testGetEvents_WhenAPIFails_ThrowsError() async {
        // Given
        mockAPIClient.errorToThrow = APIError.networkError(NSError(domain: "test", code: -1))

        // When/Then
        do {
            _ = try await sut.getEvents(
                frameId: "frame-123",
                from: Date(),
                to: Date().addingTimeInterval(86400),
                timezone: "America/New_York"
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }

    // MARK: - Helpers

    private func makeCalendarEventsResponse(events: [CalendarEvent]) -> CalendarEventsResponse {
        // Create CalendarEventData from CalendarEvent for the response
        let eventData = events.map { event in
            CalendarEventData(
                id: event.id,
                type: "calendar_event",
                attributes: CalendarEventAttributes(
                    summary: event.title,
                    description: event.description,
                    location: event.location,
                    allDay: event.isAllDay,
                    timezone: TimeZone.current.identifier,
                    startsAt: event.startDate,
                    endsAt: event.endDate,
                    recurring: event.isRecurring,
                    rrule: nil
                ),
                relationships: nil
            )
        }

        return CalendarEventsResponse(data: eventData, included: nil)
    }
}
