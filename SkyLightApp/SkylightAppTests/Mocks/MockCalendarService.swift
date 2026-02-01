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

    func reset() {
        eventsToReturn = []
        errorToThrow = nil
        getEventsCalled = false
        lastFrameId = nil
        lastStartDate = nil
        lastEndDate = nil
        lastTimezone = nil
    }
}
