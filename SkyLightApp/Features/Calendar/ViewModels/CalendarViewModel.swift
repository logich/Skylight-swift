import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false

    private let calendarService: CalendarServiceProtocol
    private let authManager: AuthenticationManager

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

    func loadEvents() async {
        guard let frameId = authManager.currentFrameId else { return }

        isLoading = true
        defer { isLoading = false }

        let (startDate, endDate) = dateRangeForMode()

        do {
            events = try await calendarService.getEvents(
                frameId: frameId,
                from: startDate,
                to: endDate
            )
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

    private func dateRangeForMode() -> (Date, Date) {
        switch displayMode {
        case .day:
            return (selectedDate.startOfDay, selectedDate.endOfDay)
        case .week:
            return (selectedDate.startOfWeek, selectedDate.endOfWeek)
        case .month:
            return (selectedDate.startOfMonth, selectedDate.endOfMonth)
        }
    }
}
