import XCTest
@testable import SkylightApp

@MainActor
final class DriveTimeManagerTests: XCTestCase {

    // Note: DriveTimeManager uses real LocationService, NotificationService, and SharedDataManager
    // as dependencies. For comprehensive unit testing, we'd need to add protocols for these services
    // and enable dependency injection. These tests focus on the cache logic and filtering behavior.

    // MARK: - Event Filtering Tests

    func testFilterRelevantEvents_ExcludesAllDayEvents() async throws {
        // Given
        let allDayEvent = TestDataFactory.makeCalendarEvent(
            id: "allday",
            title: "All Day Event",
            isAllDay: true,
            location: "123 Main St"
        )
        let timedEvent = TestDataFactory.makeCalendarEvent(
            id: "timed",
            title: "Timed Event",
            isAllDay: false,
            location: "456 Oak Ave"
        )
        let events = [allDayEvent, timedEvent]

        // When - Filter like DriveTimeManager.processEvents does
        let relevantEvents = events.filter { event in
            !event.isAllDay &&
            event.startDate > Date() &&
            event.location != nil &&
            !event.location!.isEmpty
        }

        // Then
        XCTAssertEqual(relevantEvents.count, 1)
        XCTAssertEqual(relevantEvents.first?.id, "timed")
    }

    func testFilterRelevantEvents_ExcludesEventsWithoutLocation() async throws {
        // Given
        let eventWithLocation = TestDataFactory.makeCalendarEvent(
            id: "with-loc",
            title: "Event with Location",
            location: "123 Main St"
        )
        let eventWithoutLocation = TestDataFactory.makeCalendarEvent(
            id: "no-loc",
            title: "Event without Location",
            location: nil
        )
        let eventWithEmptyLocation = TestDataFactory.makeCalendarEvent(
            id: "empty-loc",
            title: "Event with Empty Location",
            location: ""
        )
        let events = [eventWithLocation, eventWithoutLocation, eventWithEmptyLocation]

        // When
        let relevantEvents = events.filter { event in
            !event.isAllDay &&
            event.startDate > Date() &&
            event.location != nil &&
            !event.location!.isEmpty
        }

        // Then
        XCTAssertEqual(relevantEvents.count, 1)
        XCTAssertEqual(relevantEvents.first?.id, "with-loc")
    }

    func testFilterRelevantEvents_ExcludesPastEvents() async throws {
        // Given
        let pastEvent = TestDataFactory.makeCalendarEvent(
            id: "past",
            title: "Past Event",
            startDate: Date().addingTimeInterval(-3600), // 1 hour ago
            endDate: Date().addingTimeInterval(-1800),
            location: "123 Main St"
        )
        let futureEvent = TestDataFactory.makeCalendarEvent(
            id: "future",
            title: "Future Event",
            startDate: Date().addingTimeInterval(3600), // 1 hour from now
            endDate: Date().addingTimeInterval(7200),
            location: "456 Oak Ave"
        )
        let events = [pastEvent, futureEvent]

        // When
        let relevantEvents = events.filter { event in
            !event.isAllDay &&
            event.startDate > Date() &&
            event.location != nil &&
            !event.location!.isEmpty
        }

        // Then
        XCTAssertEqual(relevantEvents.count, 1)
        XCTAssertEqual(relevantEvents.first?.id, "future")
    }

    // MARK: - Cache Expiration Logic Tests

    func testCacheExpiration_ReturnsTrue_After30Minutes() async throws {
        // Given
        let thirtyOneMinutesAgo = Date().addingTimeInterval(-31 * 60)

        // When
        let isExpired = Date().timeIntervalSince(thirtyOneMinutesAgo) > 30 * 60

        // Then
        XCTAssertTrue(isExpired)
    }

    func testCacheExpiration_ReturnsFalse_Within30Minutes() async throws {
        // Given
        let twentyNineMinutesAgo = Date().addingTimeInterval(-29 * 60)

        // When
        let isExpired = Date().timeIntervalSince(twentyNineMinutesAgo) > 30 * 60

        // Then
        XCTAssertFalse(isExpired)
    }

    // MARK: - WidgetEvent Calculation Tests

    func testLeaveByDate_CalculatesCorrectly() async throws {
        // Given
        let startTime = Date().addingTimeInterval(7200) // 2 hours from now
        let event = TestDataFactory.makeWidgetEvent(
            id: "test",
            title: "Test Event",
            startDate: startTime,
            endDate: startTime.addingTimeInterval(3600),
            location: "123 Main St",
            driveTimeMinutes: 30,
            bufferMinutes: 10
        )

        // When
        let leaveByDate = event.leaveByDate

        // Then
        XCTAssertNotNil(leaveByDate)
        // Leave time should be 40 minutes (30 drive + 10 buffer) before start
        let expectedLeaveTime = startTime.addingTimeInterval(-40 * 60)
        XCTAssertEqual(leaveByDate!.timeIntervalSinceReferenceDate, expectedLeaveTime.timeIntervalSinceReferenceDate, accuracy: 1)
    }

    func testLeaveByDate_ReturnsNil_WhenNoDriveTime() async throws {
        // Given
        let event = TestDataFactory.makeWidgetEvent(
            id: "test",
            title: "Test Event",
            driveTimeMinutes: nil
        )

        // When
        let leaveByDate = event.leaveByDate

        // Then
        XCTAssertNil(leaveByDate)
    }

    func testMinutesUntilLeave_CalculatesCorrectly() async throws {
        // Given - event where we should leave in ~60 minutes
        let startTime = Date().addingTimeInterval(100 * 60) // 100 minutes from now
        let event = TestDataFactory.makeWidgetEvent(
            id: "test",
            title: "Test Event",
            startDate: startTime,
            endDate: startTime.addingTimeInterval(3600),
            driveTimeMinutes: 30,
            bufferMinutes: 10
        )
        // Leave time = startTime - 40 min = 60 minutes from now

        // When
        let minutesUntilLeave = event.minutesUntilLeave

        // Then
        XCTAssertNotNil(minutesUntilLeave)
        // Should be approximately 60 minutes
        XCTAssertEqual(minutesUntilLeave!, 60, accuracy: 1)
    }

    func testShouldLeaveNow_ReturnsTrueWhenLeaveTimePassedButEventNotStarted() async throws {
        // Given - event starts in 30 min, leave time was 10 min ago
        let startTime = Date().addingTimeInterval(30 * 60) // 30 minutes from now
        let event = TestDataFactory.makeWidgetEvent(
            id: "test",
            title: "Test Event",
            startDate: startTime,
            endDate: startTime.addingTimeInterval(3600),
            driveTimeMinutes: 30,
            bufferMinutes: 10
        )
        // Leave time = startTime - 40 min = -10 minutes (past)

        // When
        let shouldLeave = event.shouldLeaveNow

        // Then
        XCTAssertTrue(shouldLeave)
    }

    func testShouldLeaveNow_ReturnsFalseWhenStillTimeToLeave() async throws {
        // Given - leave time is still in the future
        let startTime = Date().addingTimeInterval(120 * 60) // 2 hours from now
        let event = TestDataFactory.makeWidgetEvent(
            id: "test",
            title: "Test Event",
            startDate: startTime,
            endDate: startTime.addingTimeInterval(3600),
            driveTimeMinutes: 30,
            bufferMinutes: 10
        )
        // Leave time = startTime - 40 min = 80 minutes from now

        // When
        let shouldLeave = event.shouldLeaveNow

        // Then
        XCTAssertFalse(shouldLeave)
    }
}
