import Foundation
@testable import SkylightApp

final class MockCalendarService: CalendarServiceProtocol {
    var eventsToReturn: [CalendarEvent] = []
    var errorToThrow: Error?
    var getEventsCalled = false
    var lastFrameId: String?
    var lastStartDate: Date?
    var lastEndDate: Date?
    var lastTimezone: String?

    // Create event mock properties
    var createEventCalled = false
    var createEventRequest: CreateCalendarEventRequest?
    var createEventResult: Result<CalendarEvent, Error>?

    func getEvents(frameId: String, from startDate: Date, to endDate: Date, timezone: String) async throws -> [CalendarEvent] {
        getEventsCalled = true
        lastFrameId = frameId
        lastStartDate = startDate
        lastEndDate = endDate
        lastTimezone = timezone

        if let error = errorToThrow {
            throw error
        }
        return eventsToReturn
    }

    func createEvent(frameId: String, event: CreateCalendarEventRequest) async throws -> CalendarEvent {
        createEventCalled = true
        createEventRequest = event
        lastFrameId = frameId

        if let result = createEventResult {
            return try result.get()
        }

        // Return a default mock event
        return CalendarEvent(
            id: "mock-event-id",
            title: event.summary,
            description: event.description,
            startDate: event.startsAt,
            endDate: event.endsAt,
            isAllDay: event.allDay,
            location: event.location,
            isRecurring: false,
            categoryId: event.categoryIds?.first,
            categoryColor: nil,
            attendees: []
        )
    }

    func reset() {
        eventsToReturn = []
        errorToThrow = nil
        getEventsCalled = false
        lastFrameId = nil
        lastStartDate = nil
        lastEndDate = nil
        lastTimezone = nil
        createEventCalled = false
        createEventRequest = nil
        createEventResult = nil
    }
}
