import Foundation
import Combine

@MainActor
final class CreateEventViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var isAllDay: Bool = false
    @Published var location: String = ""
    @Published var eventDescription: String = ""
    @Published var selectedProfileIds: Set<String> = []
    @Published var availableProfiles: [FamilyMember] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingProfiles: Bool = false
    @Published var isDeleting: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false
    @Published var showDeleteConfirmation: Bool = false

    private let calendarService: CalendarServiceProtocol
    private let familyService: FamilyServiceProtocol
    private let authManager: AuthenticationManager

    /// The event being edited, nil if creating a new event
    let editingEvent: CalendarEvent?

    var isEditMode: Bool { editingEvent != nil }

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (isAllDay || endDate >= startDate)
    }

    /// Initialize for creating a new event
    init(
        initialDate: Date = Date(),
        calendarService: CalendarServiceProtocol = CalendarService(),
        familyService: FamilyServiceProtocol = FamilyService(),
        authManager: AuthenticationManager = .shared
    ) {
        let calendar = Calendar.current
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: initialDate) ?? initialDate
        let roundedStart = calendar.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
        self.startDate = roundedStart
        self.endDate = calendar.date(byAdding: .hour, value: 1, to: roundedStart) ?? roundedStart
        self.editingEvent = nil
        self.calendarService = calendarService
        self.familyService = familyService
        self.authManager = authManager
    }

    /// Initialize for editing an existing event
    init(
        event: CalendarEvent,
        calendarService: CalendarServiceProtocol = CalendarService(),
        familyService: FamilyServiceProtocol = FamilyService(),
        authManager: AuthenticationManager = .shared
    ) {
        self.editingEvent = event
        self.title = event.title
        self.isAllDay = event.isAllDay
        self.location = event.location ?? ""
        self.eventDescription = event.description ?? ""
        self.selectedProfileIds = Set(event.attendees.map { $0.id })
        self.calendarService = calendarService
        self.familyService = familyService
        self.authManager = authManager

        // For all-day events, the API uses exclusive end dates (ends at midnight of next day)
        // Convert back to inclusive display dates
        if event.isAllDay {
            self.startDate = event.startDate.startOfDay
            // Subtract one day from end date to show inclusive end
            self.endDate = event.endDate.adding(days: -1).startOfDay
        } else {
            self.startDate = event.startDate
            self.endDate = event.endDate
        }
    }

    func loadProfiles() async {
        guard let frameId = authManager.currentFrameId else { return }

        isLoadingProfiles = true
        defer { isLoadingProfiles = false }

        do {
            availableProfiles = try await familyService.getFamilyMembers(frameId: frameId)
        } catch {
            #if DEBUG
            print("CreateEventViewModel: Failed to load profiles: \(error)")
            #endif
        }
    }

    func toggleProfile(_ profileId: String) {
        if selectedProfileIds.contains(profileId) {
            selectedProfileIds.remove(profileId)
        } else {
            selectedProfileIds.insert(profileId)
        }
    }

    func saveEvent() async -> Bool {
        guard isFormValid, let frameId = authManager.currentFrameId else { return false }

        isLoading = true
        defer { isLoading = false }

        // For all-day events, use calendar standard with exclusive end dates
        // Single-day event: March 15 → starts March 15 00:00, ends March 16 00:00
        // Multi-day event: March 15-17 → starts March 15 00:00, ends March 18 00:00
        let effectiveStartDate: Date
        let effectiveEndDate: Date

        if isAllDay {
            effectiveStartDate = startDate.startOfDay
            effectiveEndDate = endDate.startOfDay.adding(days: 1)
        } else {
            effectiveStartDate = startDate
            effectiveEndDate = endDate
        }

        do {
            if let event = editingEvent {
                // Update existing event
                let request = UpdateCalendarEventRequest(
                    summary: title.trimmingCharacters(in: .whitespaces),
                    startsAt: effectiveStartDate,
                    endsAt: effectiveEndDate,
                    allDay: isAllDay,
                    location: location.isEmpty ? nil : location,
                    description: eventDescription.isEmpty ? nil : eventDescription,
                    categoryIds: selectedProfileIds.isEmpty ? nil : Array(selectedProfileIds),
                    timezone: TimeZone.current.identifier
                )
                _ = try await calendarService.updateEvent(frameId: frameId, eventId: event.id, event: request)
            } else {
                // Create new event
                let request = CreateCalendarEventRequest(
                    summary: title.trimmingCharacters(in: .whitespaces),
                    startsAt: effectiveStartDate,
                    endsAt: effectiveEndDate,
                    allDay: isAllDay,
                    location: location.isEmpty ? nil : location,
                    description: eventDescription.isEmpty ? nil : eventDescription,
                    categoryIds: selectedProfileIds.isEmpty ? nil : Array(selectedProfileIds),
                    timezone: TimeZone.current.identifier
                )
                _ = try await calendarService.createEvent(frameId: frameId, event: request)
            }
            return true
        } catch {
            self.error = error
            self.showError = true
            return false
        }
    }

    func deleteEvent() async -> Bool {
        guard let event = editingEvent, let frameId = authManager.currentFrameId else { return false }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await calendarService.deleteEvent(frameId: frameId, eventId: event.id)
            return true
        } catch {
            self.error = error
            self.showError = true
            return false
        }
    }
}
