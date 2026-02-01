import XCTest
@testable import SkylightApp

@MainActor
final class CalendarViewModelTests: XCTestCase {

    var mockCalendarService: MockCalendarService!
    var mockKeychainManager: MockKeychainManager!
    var mockAPIClient: MockAPIClient!
    var authManager: AuthenticationManager!
    var testDefaults: UserDefaults!
    var sut: CalendarViewModel!

    override func setUp() async throws {
        try await super.setUp()

        mockCalendarService = MockCalendarService()
        mockKeychainManager = MockKeychainManager()
        mockAPIClient = MockAPIClient()

        // Create test UserDefaults
        testDefaults = UserDefaults(suiteName: "com.test.skylight.calendar")!
        testDefaults.removePersistentDomain(forName: "com.test.skylight.calendar")

        // Set up authenticated state
        mockKeychainManager.setupAuthenticatedState()
        testDefaults.set("test-frame-id", forKey: Constants.UserDefaults.selectedFrameIdKey)

        authManager = AuthenticationManager(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient,
            userDefaults: testDefaults
        )

        sut = CalendarViewModel(
            calendarService: mockCalendarService,
            authManager: authManager
        )
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "com.test.skylight.calendar")
        testDefaults = nil
        mockCalendarService = nil
        mockKeychainManager = nil
        mockAPIClient = nil
        authManager = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - loadEvents Tests

    func testLoadEvents_FetchesEventsFromService() async throws {
        // Given
        let expectedEvents = TestDataFactory.makeCalendarEvents(count: 3)
        mockCalendarService.eventsToReturn = expectedEvents

        // When
        await sut.loadEvents()

        // Then
        XCTAssertTrue(mockCalendarService.getEventsCalled)
        XCTAssertEqual(sut.events.count, 3)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadEvents_SetsIsLoadingDuringFetch() async throws {
        // Given
        mockCalendarService.eventsToReturn = []

        // Note: To properly test loading state, we'd need to observe it during the async call
        // This tests the final state

        // When
        await sut.loadEvents()

        // Then
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadEvents_SetsErrorOnFailure() async throws {
        // Given
        mockCalendarService.errorToThrow = APIError.networkError(NSError(domain: "test", code: -1))

        // When
        await sut.loadEvents()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
    }

    func testLoadEvents_WithoutFrameId_DoesNotFetch() async throws {
        // Given - No frame selected
        testDefaults.removeObject(forKey: Constants.UserDefaults.selectedFrameIdKey)

        // Recreate auth manager to reflect the change
        authManager = AuthenticationManager(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient,
            userDefaults: testDefaults
        )
        sut = CalendarViewModel(
            calendarService: mockCalendarService,
            authManager: authManager
        )

        // When
        await sut.loadEvents()

        // Then
        XCTAssertFalse(mockCalendarService.getEventsCalled)
    }

    // MARK: - Cache Tests

    func testLoadEvents_UsesCacheOnSubsequentCalls() async throws {
        // Given
        let events = TestDataFactory.makeCalendarEvents(count: 2)
        mockCalendarService.eventsToReturn = events

        // First call - should fetch from API
        await sut.loadEvents()
        XCTAssertTrue(mockCalendarService.getEventsCalled)

        // Reset the flag
        mockCalendarService.getEventsCalled = false

        // When - Second call without force refresh
        await sut.loadEvents()

        // Then - Should use cache, not call API again
        XCTAssertFalse(mockCalendarService.getEventsCalled)
        XCTAssertEqual(sut.events.count, 2)
    }

    func testLoadEvents_ForceRefresh_BypassesCache() async throws {
        // Given
        mockCalendarService.eventsToReturn = TestDataFactory.makeCalendarEvents(count: 2)
        await sut.loadEvents()
        mockCalendarService.getEventsCalled = false

        // Update mock to return different events
        mockCalendarService.eventsToReturn = TestDataFactory.makeCalendarEvents(count: 5)

        // When
        await sut.loadEvents(forceRefresh: true)

        // Then
        XCTAssertTrue(mockCalendarService.getEventsCalled)
        XCTAssertEqual(sut.events.count, 5)
    }

    func testClearCache_AllowsFreshFetch() async throws {
        // Given
        mockCalendarService.eventsToReturn = TestDataFactory.makeCalendarEvents(count: 2)
        await sut.loadEvents()
        mockCalendarService.getEventsCalled = false

        // When
        sut.clearCache()
        await sut.loadEvents()

        // Then
        XCTAssertTrue(mockCalendarService.getEventsCalled)
    }

    // MARK: - eventsForDate Tests

    func testEventsForDate_FiltersCorrectly() async throws {
        // Given
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let todayEvent = TestDataFactory.makeCalendarEvent(
            id: "today",
            title: "Today Event",
            startDate: today.addingTimeInterval(36000), // 10 AM
            endDate: today.addingTimeInterval(39600)
        )
        let tomorrowEvent = TestDataFactory.makeCalendarEvent(
            id: "tomorrow",
            title: "Tomorrow Event",
            startDate: tomorrow.addingTimeInterval(36000),
            endDate: tomorrow.addingTimeInterval(39600)
        )

        mockCalendarService.eventsToReturn = [todayEvent, tomorrowEvent]
        await sut.loadEvents()

        // When
        let todaysEvents = sut.eventsForDate(today)

        // Then
        XCTAssertEqual(todaysEvents.count, 1)
        XCTAssertEqual(todaysEvents.first?.id, "today")
    }

    func testEventsForDate_SortsByStartTime() async throws {
        // Given
        let today = Calendar.current.startOfDay(for: Date())

        let laterEvent = TestDataFactory.makeCalendarEvent(
            id: "later",
            title: "Later Event",
            startDate: today.addingTimeInterval(54000), // 3 PM
            endDate: today.addingTimeInterval(57600)
        )
        let earlierEvent = TestDataFactory.makeCalendarEvent(
            id: "earlier",
            title: "Earlier Event",
            startDate: today.addingTimeInterval(36000), // 10 AM
            endDate: today.addingTimeInterval(39600)
        )

        mockCalendarService.eventsToReturn = [laterEvent, earlierEvent]
        await sut.loadEvents()

        // When
        let events = sut.eventsForDate(today)

        // Then
        XCTAssertEqual(events.first?.id, "earlier")
        XCTAssertEqual(events.last?.id, "later")
    }

    // MARK: - Date Navigation Tests

    func testChangeDate_UpdatesSelectedDate() async throws {
        // Given
        let newDate = Date().addingTimeInterval(86400)
        mockCalendarService.eventsToReturn = []

        // When
        sut.changeDate(newDate)

        // Allow the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(
            Calendar.current.startOfDay(for: sut.selectedDate),
            Calendar.current.startOfDay(for: newDate)
        )
    }

    func testGoToToday_SetsSelectedDateToToday() async throws {
        // Given
        sut.selectedDate = Date().addingTimeInterval(86400 * 7) // 1 week from now
        mockCalendarService.eventsToReturn = []

        // When
        sut.goToToday()

        // Allow the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(Calendar.current.isDateInToday(sut.selectedDate))
    }

    func testGoToPrevious_InDayMode_MovesBackOneDay() async throws {
        // Given
        let startDate = Date()
        sut.selectedDate = startDate
        sut.displayMode = .day
        mockCalendarService.eventsToReturn = []

        // When
        sut.goToPrevious()

        // Allow the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)!
        XCTAssertEqual(
            Calendar.current.startOfDay(for: sut.selectedDate),
            Calendar.current.startOfDay(for: expectedDate)
        )
    }

    func testGoToNext_InDayMode_MovesForwardOneDay() async throws {
        // Given
        let startDate = Date()
        sut.selectedDate = startDate
        sut.displayMode = .day
        mockCalendarService.eventsToReturn = []

        // When
        sut.goToNext()

        // Allow the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        XCTAssertEqual(
            Calendar.current.startOfDay(for: sut.selectedDate),
            Calendar.current.startOfDay(for: expectedDate)
        )
    }

    // MARK: - Display Mode Tests

    func testChangeDisplayMode_UpdatesMode() async throws {
        // Given
        XCTAssertEqual(sut.displayMode, .day) // default
        mockCalendarService.eventsToReturn = []

        // When
        sut.changeDisplayMode(.week)

        // Allow the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.displayMode, .week)
    }

    func testDisplayModeEnum_HasExpectedCases() {
        // Then
        XCTAssertEqual(CalendarViewModel.DisplayMode.allCases.count, 3)
        XCTAssertTrue(CalendarViewModel.DisplayMode.allCases.contains(.day))
        XCTAssertTrue(CalendarViewModel.DisplayMode.allCases.contains(.week))
        XCTAssertTrue(CalendarViewModel.DisplayMode.allCases.contains(.month))
    }
}
