import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false

    private let calendarService: CalendarServiceProtocol
    private let authManager: AuthenticationManager

    // Cache: stores events keyed by "startDate-endDate" string
    private var eventsCache: [String: CachedEvents] = [:]
    private let cacheExpiration: TimeInterval = 60 * 60 // 60 minutes

    private struct CachedEvents {
        let events: [CalendarEvent]
        let timestamp: Date

        func isExpired(after interval: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) > interval
        }
    }

    enum DisplayMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }

    @Published var displayMode: DisplayMode = .week

    init(
        calendarService: CalendarServiceProtocol = CalendarService(),
        authManager: AuthenticationManager = .shared
    ) {
        self.calendarService = calendarService
        self.authManager = authManager
    }

    func loadEvents(forceRefresh: Bool = false) async {
        guard let frameId = authManager.currentFrameId else { return }

        let (startDate, endDate) = dateRangeForMode()
        let cacheKey = cacheKey(for: startDate, end: endDate)

        // Check cache first (unless force refresh)
        if !forceRefresh, let cached = eventsCache[cacheKey], !cached.isExpired(after: cacheExpiration) {
            events = cached.events
            return
        }

        // Check if we can filter from a larger cached range
        if !forceRefresh, let cached = findCachedEventsContaining(start: startDate, end: endDate) {
            events = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        let timezone = TimeZone.current.identifier

        do {
            let fetchedEvents = try await calendarService.getEvents(
                frameId: frameId,
                from: startDate,
                to: endDate,
                timezone: timezone
            )
            // Store in cache
            eventsCache[cacheKey] = CachedEvents(events: fetchedEvents, timestamp: Date())
            events = fetchedEvents
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func eventsForDate(_ date: Date) -> [CalendarEvent] {
        events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: date)
        }.sorted { $0.startDate < $1.startDate }
    }

    func changeDate(_ date: Date) {
        selectedDate = date
        Task {
            await loadEvents()
        }
    }

    func changeDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
        Task {
            await loadEvents()
        }
    }

    func goToToday() {
        changeDate(Date())
    }

    func goToPrevious() {
        switch displayMode {
        case .day:
            changeDate(selectedDate.adding(days: -1))
        case .week:
            changeDate(selectedDate.adding(weeks: -1))
        case .month:
            changeDate(selectedDate.adding(months: -1))
        }
    }

    func goToNext() {
        switch displayMode {
        case .day:
            changeDate(selectedDate.adding(days: 1))
        case .week:
            changeDate(selectedDate.adding(weeks: 1))
        case .month:
            changeDate(selectedDate.adding(months: 1))
        }
    }

    func clearCache() {
        eventsCache.removeAll()
    }

    // MARK: - Private Helpers

    private func cacheKey(for start: Date, end: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return "\(formatter.string(from: start))_\(formatter.string(from: end))"
    }

    private func findCachedEventsContaining(start: Date, end: Date) -> [CalendarEvent]? {
        // Check if any cached range fully contains the requested range
        for (key, cached) in eventsCache {
            // Skip expired cache entries
            guard !cached.isExpired(after: cacheExpiration) else { continue }

            let parts = key.split(separator: "_")
            guard parts.count == 2,
                  let cachedStart = ISO8601DateFormatter().date(from: String(parts[0])),
                  let cachedEnd = ISO8601DateFormatter().date(from: String(parts[1])) else {
                continue
            }

            // If cached range contains requested range, filter and return
            if cachedStart <= start && cachedEnd >= end {
                return cached.events.filter { event in
                    event.startDate >= start && event.startDate < end
                }
            }
        }
        return nil
    }

    private func dateRangeForMode() -> (Date, Date) {
        // API uses date_min (inclusive) and date_max (exclusive), so add 1 day to end dates
        let calendar = Calendar.current
        switch displayMode {
        case .day:
            let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate.startOfDay) ?? selectedDate
            return (selectedDate.startOfDay, nextDay)
        case .week:
            let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate.endOfWeek) ?? selectedDate.endOfWeek
            return (selectedDate.startOfWeek, nextDay)
        case .month:
            let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate.endOfMonth) ?? selectedDate.endOfMonth
            return (selectedDate.startOfMonth, nextDay)
        }
    }
}
