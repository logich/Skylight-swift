import Foundation
import Combine

/// Orchestrates drive time calculations, notifications, and widget updates
/// Central coordinator for the "Time to Leave" feature
@MainActor
final class DriveTimeManager: ObservableObject {
    static let shared = DriveTimeManager()

    @Published private(set) var isProcessing = false
    @Published private(set) var lastProcessedCount = 0
    @Published private(set) var lastError: Error?

    private let locationService: LocationService
    private let notificationService: NotificationService
    private let sharedDataManager: SharedDataManager

    /// Cache of drive times to avoid recalculating for the same location
    private var driveTimeCache: [String: DriveTimeCacheEntry] = [:]
    private let cacheExpiration: TimeInterval = 30 * 60 // 30 minutes

    private struct DriveTimeCacheEntry {
        let driveTimeMinutes: Int
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 30 * 60
        }
    }

    private init(
        locationService: LocationService = .shared,
        notificationService: NotificationService = .shared,
        sharedDataManager: SharedDataManager = .shared
    ) {
        self.locationService = locationService
        self.notificationService = notificationService
        self.sharedDataManager = sharedDataManager
    }

    // MARK: - Main Processing

    /// Processes calendar events to calculate drive times, schedule notifications, and update widget
    /// - Parameters:
    ///   - events: The calendar events to process
    ///   - forceRefresh: If true, ignores cache and recalculates all drive times
    func processEvents(_ events: [CalendarEvent], forceRefresh: Bool = false) async {
        guard !isProcessing else {
            #if DEBUG
            print("DriveTimeManager: Already processing, skipping")
            #endif
            return
        }

        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        #if DEBUG
        print("DriveTimeManager: Processing \(events.count) events")
        #endif

        // Filter to upcoming events with locations (skip all-day and past events)
        let relevantEvents = events.filter { event in
            !event.isAllDay &&
            event.startDate > Date() &&
            event.location != nil &&
            !event.location!.isEmpty
        }

        #if DEBUG
        print("DriveTimeManager: \(relevantEvents.count) events have locations and are upcoming")
        #endif

        let bufferMinutes = sharedDataManager.bufferTimeMinutes

        // Calculate drive times for each event
        var widgetEvents: [WidgetEvent] = []

        for event in relevantEvents {
            let driveTime = await calculateDriveTime(for: event, forceRefresh: forceRefresh)
            let widgetEvent = WidgetEvent(
                from: event,
                driveTimeMinutes: driveTime,
                bufferMinutes: bufferMinutes
            )
            widgetEvents.append(widgetEvent)
        }

        // Also include events without locations (with nil drive time)
        let eventsWithoutLocation = events.filter { event in
            !event.isAllDay &&
            event.startDate > Date() &&
            (event.location == nil || event.location!.isEmpty)
        }

        for event in eventsWithoutLocation {
            let widgetEvent = WidgetEvent(
                from: event,
                driveTimeMinutes: nil,
                bufferMinutes: bufferMinutes
            )
            widgetEvents.append(widgetEvent)
        }

        // Sort by start date
        widgetEvents.sort { $0.startDate < $1.startDate }

        // Save to shared storage for widget
        sharedDataManager.saveEvents(widgetEvents)

        // Schedule notifications if enabled
        if sharedDataManager.driveTimeAlertsEnabled {
            await scheduleNotifications(for: widgetEvents)
        }

        // Refresh widget
        sharedDataManager.refreshWidget()

        lastProcessedCount = widgetEvents.count

        #if DEBUG
        print("DriveTimeManager: Finished processing. \(widgetEvents.count) events saved, widget refreshed")
        #endif
    }

    // MARK: - Drive Time Calculation

    /// Calculates drive time for a single event
    /// - Parameters:
    ///   - event: The event to calculate drive time for
    ///   - forceRefresh: If true, ignores cache
    /// - Returns: Drive time in minutes, or nil if calculation failed
    private func calculateDriveTime(for event: CalendarEvent, forceRefresh: Bool) async -> Int? {
        guard let location = event.location, !location.isEmpty else {
            return nil
        }

        // Check cache first
        if !forceRefresh, let cached = driveTimeCache[location], !cached.isExpired {
            #if DEBUG
            print("DriveTimeManager: Using cached drive time for '\(location)': \(cached.driveTimeMinutes) min")
            #endif
            return cached.driveTimeMinutes
        }

        // Calculate new drive time
        do {
            let driveTime = try await locationService.getDrivingTimeToAddress(location)

            // Cache the result
            driveTimeCache[location] = DriveTimeCacheEntry(
                driveTimeMinutes: driveTime,
                timestamp: Date()
            )

            #if DEBUG
            print("DriveTimeManager: Calculated drive time for '\(location)': \(driveTime) min")
            #endif

            return driveTime
        } catch {
            #if DEBUG
            print("DriveTimeManager: Failed to calculate drive time for '\(location)': \(error)")
            #endif

            // Don't set lastError for individual failures, only for critical errors
            return nil
        }
    }

    // MARK: - Notifications

    /// Schedules notifications for events with drive times
    private func scheduleNotifications(for events: [WidgetEvent]) async {
        // Cancel existing notifications first
        await notificationService.cancelAllTimeToLeaveNotifications()

        // Schedule new notifications
        let scheduledCount = await notificationService.scheduleTimeToLeaveNotifications(for: events)

        #if DEBUG
        print("DriveTimeManager: Scheduled \(scheduledCount) notifications")
        #endif
    }

    // MARK: - Settings Changes

    /// Called when settings change (e.g., buffer time or alerts toggle)
    /// Re-processes existing cached events with new settings
    func onSettingsChanged() async {
        let existingEvents = sharedDataManager.loadEvents()

        guard !existingEvents.isEmpty else { return }

        #if DEBUG
        print("DriveTimeManager: Settings changed, updating \(existingEvents.count) cached events")
        #endif

        let bufferMinutes = sharedDataManager.bufferTimeMinutes

        // Update buffer time on existing events
        let updatedEvents = existingEvents.map { event in
            WidgetEvent(
                id: event.id,
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                isAllDay: event.isAllDay,
                categoryColor: event.categoryColor,
                driveTimeMinutes: event.driveTimeMinutes,
                bufferMinutes: bufferMinutes
            )
        }

        // Save updated events
        sharedDataManager.saveEvents(updatedEvents)

        // Reschedule notifications if enabled
        if sharedDataManager.driveTimeAlertsEnabled {
            await scheduleNotifications(for: updatedEvents)
        } else {
            // Cancel all notifications if disabled
            await notificationService.cancelAllTimeToLeaveNotifications()
        }

        // Refresh widget
        sharedDataManager.refreshWidget()
    }

    // MARK: - Cache Management

    /// Clears the drive time cache
    func clearCache() {
        driveTimeCache.removeAll()
        #if DEBUG
        print("DriveTimeManager: Cache cleared")
        #endif
    }

    /// Clears expired entries from the cache
    func cleanupExpiredCache() {
        let expiredKeys = driveTimeCache.filter { $0.value.isExpired }.map { $0.key }
        for key in expiredKeys {
            driveTimeCache.removeValue(forKey: key)
        }
        #if DEBUG
        if !expiredKeys.isEmpty {
            print("DriveTimeManager: Removed \(expiredKeys.count) expired cache entries")
        }
        #endif
    }
}

// MARK: - Convenience Methods

extension DriveTimeManager {
    /// Requests notification permission and enables drive time alerts if granted
    func enableDriveTimeAlerts() async -> Bool {
        let authorized = await notificationService.requestAuthorization()

        if authorized {
            sharedDataManager.driveTimeAlertsEnabled = true
            await onSettingsChanged()
        }

        return authorized
    }

    /// Disables drive time alerts and cancels all notifications
    func disableDriveTimeAlerts() async {
        sharedDataManager.driveTimeAlertsEnabled = false
        await notificationService.cancelAllTimeToLeaveNotifications()
        sharedDataManager.refreshWidget()
    }

    /// Updates the buffer time setting
    func updateBufferTime(_ minutes: Int) async {
        sharedDataManager.bufferTimeMinutes = minutes
        await onSettingsChanged()
    }
}
