import Foundation
import UserNotifications
import UIKit

/// Service for managing local notifications, specifically "Time to Leave" alerts
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    /// Requests notification authorization from the user
    /// Returns true if authorization was granted
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

            #if DEBUG
            print("NotificationService: Authorization \(granted ? "granted" : "denied")")
            #endif

            return granted
        } catch {
            #if DEBUG
            print("NotificationService: Authorization request failed - \(error)")
            #endif
            return false
        }
    }

    /// Checks current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    /// Returns true if notifications are authorized
    func isAuthorized() async -> Bool {
        let status = await checkAuthorizationStatus()
        return status == .authorized
    }

    // MARK: - Notification Categories

    /// Registers notification categories and actions
    /// Call this at app launch
    func registerCategories() {
        let openAction = UNNotificationAction(
            identifier: SharedConstants.Notifications.openEventActionId,
            title: "View Event",
            options: [.foreground]
        )

        let climateAction = UNNotificationAction(
            identifier: SharedConstants.Notifications.startClimateActionId,
            title: "Start Climate",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: SharedConstants.Notifications.dismissActionId,
            title: "Dismiss",
            options: []
        )

        let timeToLeaveCategory = UNNotificationCategory(
            identifier: SharedConstants.Notifications.timeToLeaveCategoryId,
            actions: [openAction, climateAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([timeToLeaveCategory])

        #if DEBUG
        print("NotificationService: Registered notification categories")
        #endif
    }

    // MARK: - Time to Leave Notifications

    /// Schedules a "Time to Leave" notification for an event
    /// - Parameter event: The event to schedule a notification for
    /// - Returns: True if the notification was scheduled successfully
    @discardableResult
    func scheduleTimeToLeaveNotification(for event: WidgetEvent) async -> Bool {
        // Must have a leave-by date
        guard let leaveByDate = event.leaveByDate else {
            #if DEBUG
            print("NotificationService: Cannot schedule notification - no leave time for event \(event.id)")
            #endif
            return false
        }

        // Don't schedule if leave time is in the past
        guard leaveByDate > Date() else {
            #if DEBUG
            print("NotificationService: Not scheduling notification - leave time is in the past for event \(event.id)")
            #endif
            return false
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Leave"
        content.body = createNotificationBody(for: event)
        content.sound = .default
        content.categoryIdentifier = SharedConstants.Notifications.timeToLeaveCategoryId

        // Add event ID for deep linking
        content.userInfo = [
            "eventId": event.id,
            "eventTitle": event.title
        ]

        // Add deep link URL if available
        if let deepLink = SharedConstants.URLScheme.eventURL(id: event.id) {
            content.userInfo["deepLink"] = deepLink.absoluteString
        }

        // Create trigger for the leave time
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: leaveByDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create unique identifier for this notification
        let identifier = notificationIdentifier(for: event.id)

        // Remove any existing notification for this event first
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Create and schedule the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)

            #if DEBUG
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            print("NotificationService: Scheduled notification for '\(event.title)' at \(formatter.string(from: leaveByDate))")
            #endif

            return true
        } catch {
            #if DEBUG
            print("NotificationService: Failed to schedule notification - \(error)")
            #endif
            return false
        }
    }

    /// Schedules notifications for multiple events
    /// - Parameter events: The events to schedule notifications for
    /// - Returns: The number of notifications successfully scheduled
    func scheduleTimeToLeaveNotifications(for events: [WidgetEvent]) async -> Int {
        var successCount = 0

        for event in events.eventsNeedingNotifications {
            if await scheduleTimeToLeaveNotification(for: event) {
                successCount += 1
            }
        }

        #if DEBUG
        print("NotificationService: Scheduled \(successCount) of \(events.eventsNeedingNotifications.count) notifications")
        #endif

        return successCount
    }

    /// Cancels the notification for a specific event
    func cancelNotification(for eventId: String) {
        let identifier = notificationIdentifier(for: eventId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        #if DEBUG
        print("NotificationService: Cancelled notification for event \(eventId)")
        #endif
    }

    /// Cancels all "Time to Leave" notifications
    func cancelAllTimeToLeaveNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()

        let timeToLeaveIds = pendingRequests
            .filter { $0.identifier.hasPrefix(SharedConstants.Notifications.timeToLeaveIdPrefix) }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: timeToLeaveIds)

        #if DEBUG
        print("NotificationService: Cancelled \(timeToLeaveIds.count) time to leave notifications")
        #endif
    }

    /// Removes all delivered notifications
    func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Helpers

    private func notificationIdentifier(for eventId: String) -> String {
        "\(SharedConstants.Notifications.timeToLeaveIdPrefix)\(eventId)"
    }

    private func createNotificationBody(for event: WidgetEvent) -> String {
        var body = "Leave now for \(event.title)"

        if let driveTime = event.driveTimeDisplay {
            body += " (\(driveTime))"
        }

        if let location = event.location, !location.isEmpty {
            // Truncate long locations
            let shortLocation = location.count > 40 ? String(location.prefix(37)) + "..." : location
            body += "\n\(shortLocation)"
        }

        return body
    }

    /// Triggers Rivian climate control using App Intent
    func startRivianClimate(eventTitle: String, vehicle: String = "R1S") async {
        let intent = AutoStartRivianClimateIntent()
        intent.eventTitle = eventTitle
        intent.vehicleModel = vehicle

        do {
            _ = try await intent.perform()

            #if DEBUG
            print("NotificationService: Successfully triggered climate control for '\(eventTitle)'")
            #endif
        } catch {
            #if DEBUG
            print("NotificationService: Failed to start climate control - \(error)")
            #endif
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension NotificationService {
    /// Lists all pending notifications (for debugging)
    func listPendingNotifications() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        print("NotificationService: \(pending.count) pending notifications:")
        for request in pending {
            print("  - \(request.identifier): \(request.content.title)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let date = trigger.nextTriggerDate() {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                print("    Scheduled for: \(formatter.string(from: date))")
            }
        }
    }
}
#endif
