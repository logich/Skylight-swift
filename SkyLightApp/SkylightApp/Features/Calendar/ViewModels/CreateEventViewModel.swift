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
    @Published var error: Error?
    @Published var showError: Bool = false

    private let calendarService: CalendarServiceProtocol
    private let familyService: FamilyServiceProtocol
    private let authManager: AuthenticationManager

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (isAllDay || endDate >= startDate)
    }

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
        self.calendarService = calendarService
        self.familyService = familyService
        self.authManager = authManager
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

    func createEvent() async -> Bool {
        guard isFormValid, let frameId = authManager.currentFrameId else { return false }

        isLoading = true
        defer { isLoading = false }

        // For all-day events, use the start of the day for both start and end
        let effectiveStartDate: Date
        let effectiveEndDate: Date

        if isAllDay {
            effectiveStartDate = startDate.startOfDay
            effectiveEndDate = endDate.startOfDay
        } else {
            effectiveStartDate = startDate
            effectiveEndDate = endDate
        }

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

        do {
            _ = try await calendarService.createEvent(frameId: frameId, event: request)
            return true
        } catch {
            self.error = error
            self.showError = true
            return false
        }
    }
}
