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

    // Update event mock properties
    var updateEventCalled = false
    var updateEventRequest: UpdateCalendarEventRequest?
    var lastEventId: String?

    // Delete event mock properties
    var deleteEventCalled = false

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

    func updateEvent(frameId: String, eventId: String, event: UpdateCalendarEventRequest) async throws -> CalendarEvent {
        updateEventCalled = true
        updateEventRequest = event
        lastFrameId = frameId
        lastEventId = eventId

        if let error = errorToThrow {
            throw error
        }

        // Return a mock updated event
        return CalendarEvent(
            id: eventId,
            title: event.summary ?? "Updated Event",
            description: event.description,
            startDate: event.startsAt ?? Date(),
            endDate: event.endsAt ?? Date(),
            isAllDay: event.allDay ?? false,
            location: event.location,
            isRecurring: false,
            categoryId: event.categoryIds?.first,
            categoryColor: nil,
            attendees: []
        )
    }

    func deleteEvent(frameId: String, eventId: String) async throws {
        deleteEventCalled = true
        lastFrameId = frameId
        lastEventId = eventId

        if let error = errorToThrow {
            throw error
        }
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
        updateEventCalled = false
        updateEventRequest = nil
        lastEventId = nil
        deleteEventCalled = false
    }
}
