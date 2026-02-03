import Foundation
import UserNotifications

/// Service for automatically triggering Rivian climate control based on calendar events
@MainActor
final class ClimateAutomationService {
    static let shared = ClimateAutomationService()

    private let sharedDataManager: SharedDataManager
    private var checkTimer: Timer?

    private init(sharedDataManager: SharedDataManager = .shared) {
        self.sharedDataManager = sharedDataManager
    }

    // MARK: - Auto Climate Control

    /// Starts monitoring for events that need climate control
    /// Checks every 5 minutes for events starting within the climate start window
    func startMonitoring(climateStartMinutes: Int = 30) {
        stopMonitoring()

        #if DEBUG
        print("ClimateAutomationService: Starting monitoring (climate starts \(climateStartMinutes) min before leave time)")
        #endif

        // Check immediately
        Task {
            await checkAndStartClimate(climateStartMinutes: climateStartMinutes)
        }

        // Then check every 5 minutes
        checkTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndStartClimate(climateStartMinutes: climateStartMinutes)
            }
        }
    }

    /// Stops monitoring
    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil

        #if DEBUG
        print("ClimateAutomationService: Stopped monitoring")
        #endif
    }

    // MARK: - Private Methods

    private func checkAndStartClimate(climateStartMinutes: Int) async {
        let events = sharedDataManager.loadEvents()
        let now = Date()

        // Find events that need climate started
        for event in events {
            guard let leaveByDate = event.leaveByDate else { continue }

            // Calculate when to start climate (X minutes before leave time)
            let climateStartTime = leaveByDate.addingTimeInterval(-Double(climateStartMinutes * 60))

            // Check if we should start climate now
            // Give a 2-minute window to account for check frequency
            let isTimeToStartClimate = now >= climateStartTime && now <= climateStartTime.addingTimeInterval(120)

            if isTimeToStartClimate {
                #if DEBUG
                print("ClimateAutomationService: Time to start climate for '\(event.title)'")
                #endif

                await triggerClimateControl(for: event)
            }
        }
    }

    private func triggerClimateControl(for event: WidgetEvent) async {
        // Use NotificationService to trigger climate control
        await NotificationService.shared.startRivianClimate(eventTitle: event.title)

        #if DEBUG
        print("ClimateAutomationService: Successfully triggered climate control for '\(event.title)'")
        #endif

        // Show a notification that climate was started
        await showClimateStartedNotification(for: event)
    }

    private func showClimateStartedNotification(for event: WidgetEvent) async {
        let content = UNMutableNotificationContent()
        content.title = "Climate Control Started"
        content.body = "Warming up your Rivian for \(event.title)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "climate-started-\(event.id)",
            content: content,
            trigger: nil // Deliver immediately
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
