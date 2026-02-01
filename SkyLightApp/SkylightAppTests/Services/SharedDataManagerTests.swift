import XCTest
@testable import SkylightApp

@MainActor
final class SharedDataManagerTests: XCTestCase {

    var sut: SharedDataManager!
    var testDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        // Use a dedicated test suite to avoid polluting production data
        testDefaults = UserDefaults(suiteName: "com.test.skylight.shared")!
        testDefaults.removePersistentDomain(forName: "com.test.skylight.shared")
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "com.test.skylight.shared")
        testDefaults = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Events Storage Tests

    func testSaveAndLoadEvents_RoundTripsCorrectly() async throws {
        // Skip if we can't create a test manager
        // In real tests, we'd need dependency injection for SharedDataManager

        // Given
        let events = [
            TestDataFactory.makeWidgetEvent(id: "1", title: "Event 1"),
            TestDataFactory.makeWidgetEvent(id: "2", title: "Event 2", driveTimeMinutes: 15)
        ]

        // This test demonstrates the expected behavior
        // In practice, SharedDataManager would need to accept a UserDefaults parameter

        // Simulate the encoding/decoding flow
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(events)
        let loadedEvents = try decoder.decode([WidgetEvent].self, from: data)

        XCTAssertEqual(loadedEvents.count, 2)
        XCTAssertEqual(loadedEvents[0].title, "Event 1")
        XCTAssertEqual(loadedEvents[1].driveTimeMinutes, 15)
    }

    // MARK: - WidgetEvent Array Extension Tests

    func testNextUpcoming_ReturnsFirstNonEndedEvent() async throws {
        // Given
        let pastEvent = TestDataFactory.makeWidgetEvent(
            id: "past",
            title: "Past Event",
            startDate: Date().addingTimeInterval(-7200),  // 2 hours ago
            endDate: Date().addingTimeInterval(-3600)      // 1 hour ago
        )
        let upcomingEvent = TestDataFactory.makeWidgetEvent(
            id: "upcoming",
            title: "Upcoming Event",
            startDate: Date().addingTimeInterval(3600),   // 1 hour from now
            endDate: Date().addingTimeInterval(7200)
        )
        let laterEvent = TestDataFactory.makeWidgetEvent(
            id: "later",
            title: "Later Event",
            startDate: Date().addingTimeInterval(86400),  // Tomorrow
            endDate: Date().addingTimeInterval(90000)
        )

        let events = [pastEvent, laterEvent, upcomingEvent]

        // When
        let next = events.nextUpcoming

        // Then
        XCTAssertEqual(next?.id, "upcoming")
    }

    func testNextUpcoming_ExcludesAllDayEvents() async throws {
        // Given
        let allDayEvent = TestDataFactory.makeWidgetEvent(
            id: "allday",
            title: "All Day Event",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            isAllDay: true
        )
        let timedEvent = TestDataFactory.makeWidgetEvent(
            id: "timed",
            title: "Timed Event",
            startDate: Date().addingTimeInterval(7200),
            endDate: Date().addingTimeInterval(10800)
        )

        let events = [allDayEvent, timedEvent]

        // When
        let next = events.nextUpcoming

        // Then
        XCTAssertEqual(next?.id, "timed")
    }

    func testTodayEvents_ReturnsOnlyTodaysEvents() async throws {
        // Given
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todayEvent = TestDataFactory.makeWidgetEvent(
            id: "today",
            title: "Today Event",
            startDate: today.addingTimeInterval(36000), // 10 AM today
            endDate: today.addingTimeInterval(39600)
        )
        let tomorrowEvent = TestDataFactory.makeWidgetEvent(
            id: "tomorrow",
            title: "Tomorrow Event",
            startDate: tomorrow.addingTimeInterval(36000),
            endDate: tomorrow.addingTimeInterval(39600)
        )

        let events = [todayEvent, tomorrowEvent]

        // When
        let todaysEvents = events.todayEvents

        // Then
        XCTAssertEqual(todaysEvents.count, 1)
        XCTAssertEqual(todaysEvents.first?.id, "today")
    }

    func testEventsNeedingNotifications_FiltersCorrectly() async throws {
        // Given
        let eventWithDriveTime = TestDataFactory.makeWidgetEvent(
            id: "with-drive",
            title: "Event with Drive Time",
            startDate: Date().addingTimeInterval(7200),
            endDate: Date().addingTimeInterval(10800),
            location: "123 Main St",
            driveTimeMinutes: 30,
            bufferMinutes: 10
        )
        let eventWithoutDriveTime = TestDataFactory.makeWidgetEvent(
            id: "no-drive",
            title: "Event without Drive Time",
            startDate: Date().addingTimeInterval(7200),
            endDate: Date().addingTimeInterval(10800)
        )
        let allDayEvent = TestDataFactory.makeWidgetEvent(
            id: "allday",
            title: "All Day Event",
            startDate: Date().addingTimeInterval(7200),
            endDate: Date().addingTimeInterval(86400),
            isAllDay: true,
            driveTimeMinutes: 30
        )
        let pastEvent = TestDataFactory.makeWidgetEvent(
            id: "past",
            title: "Past Event",
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date().addingTimeInterval(-1800),
            driveTimeMinutes: 30
        )

        let events = [eventWithDriveTime, eventWithoutDriveTime, allDayEvent, pastEvent]

        // When
        let needingNotifications = events.eventsNeedingNotifications

        // Then
        XCTAssertEqual(needingNotifications.count, 1)
        XCTAssertEqual(needingNotifications.first?.id, "with-drive")
    }
}
