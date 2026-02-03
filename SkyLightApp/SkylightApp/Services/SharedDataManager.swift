import Foundation
import WidgetKit

/// Manages shared data between the main app and widget extension using App Groups
@MainActor
final class SharedDataManager {
    static let shared = SharedDataManager()

    private let defaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        self.defaults = SharedConstants.sharedDefaults

        #if DEBUG
        if defaults == nil {
            print("SharedDataManager: Warning - Could not access shared UserDefaults. App Groups may not be configured.")
        }
        #endif
    }

    // MARK: - Settings

    /// Whether drive time alerts are enabled
    var driveTimeAlertsEnabled: Bool {
        get {
            defaults?.bool(forKey: SharedConstants.UserDefaultsKeys.driveTimeAlertsEnabled)
                ?? SharedConstants.Defaults.driveTimeAlertsEnabled
        }
        set {
            defaults?.set(newValue, forKey: SharedConstants.UserDefaultsKeys.driveTimeAlertsEnabled)
        }
    }

    /// Buffer time in minutes before calculated leave time
    var bufferTimeMinutes: Int {
        get {
            let value = defaults?.integer(forKey: SharedConstants.UserDefaultsKeys.bufferTimeMinutes)
            // If value is 0 and we haven't explicitly set it, return default
            if value == 0 && defaults?.object(forKey: SharedConstants.UserDefaultsKeys.bufferTimeMinutes) == nil {
                return SharedConstants.Defaults.bufferTimeMinutes
            }
            return value ?? SharedConstants.Defaults.bufferTimeMinutes
        }
        set {
            defaults?.set(newValue, forKey: SharedConstants.UserDefaultsKeys.bufferTimeMinutes)
        }
    }

    /// Whether automatic climate control is enabled for time-to-leave events
    var climateControlAutomationEnabled: Bool {
        get {
            defaults?.bool(forKey: SharedConstants.UserDefaultsKeys.climateControlAutomationEnabled)
                ?? SharedConstants.Defaults.climateControlAutomationEnabled
        }
        set {
            defaults?.set(newValue, forKey: SharedConstants.UserDefaultsKeys.climateControlAutomationEnabled)
        }
    }

    /// Currently selected frame ID
    var selectedFrameId: String? {
        get {
            defaults?.string(forKey: SharedConstants.UserDefaultsKeys.selectedFrameId)
        }
        set {
            defaults?.set(newValue, forKey: SharedConstants.UserDefaultsKeys.selectedFrameId)
        }
    }

    /// Currently selected frame name
    var selectedFrameName: String? {
        get {
            defaults?.string(forKey: SharedConstants.UserDefaultsKeys.selectedFrameName)
        }
        set {
            defaults?.set(newValue, forKey: SharedConstants.UserDefaultsKeys.selectedFrameName)
        }
    }

    // MARK: - Cached Events

    /// Saves events with drive time data for widget consumption
    func saveEvents(_ events: [WidgetEvent]) {
        do {
            let data = try encoder.encode(events)
            defaults?.set(data, forKey: SharedConstants.UserDefaultsKeys.cachedEventsWithDriveTime)
            defaults?.set(Date(), forKey: SharedConstants.UserDefaultsKeys.lastUpdateTimestamp)

            #if DEBUG
            print("SharedDataManager: Saved \(events.count) events to shared storage")
            #endif
        } catch {
            #if DEBUG
            print("SharedDataManager: Failed to encode events - \(error)")
            #endif
        }
    }

    /// Loads cached events with drive time data
    func loadEvents() -> [WidgetEvent] {
        guard let data = defaults?.data(forKey: SharedConstants.UserDefaultsKeys.cachedEventsWithDriveTime) else {
            return []
        }

        do {
            let events = try decoder.decode([WidgetEvent].self, from: data)
            return events
        } catch {
            #if DEBUG
            print("SharedDataManager: Failed to decode events - \(error)")
            #endif
            return []
        }
    }

    /// Returns the timestamp of the last data update
    var lastUpdateTimestamp: Date? {
        defaults?.object(forKey: SharedConstants.UserDefaultsKeys.lastUpdateTimestamp) as? Date
    }

    /// Clears all cached events
    func clearEvents() {
        defaults?.removeObject(forKey: SharedConstants.UserDefaultsKeys.cachedEventsWithDriveTime)
        defaults?.removeObject(forKey: SharedConstants.UserDefaultsKeys.lastUpdateTimestamp)
    }

    // MARK: - Widget Refresh

    /// Triggers a widget timeline refresh
    func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()

        #if DEBUG
        print("SharedDataManager: Triggered widget timeline refresh")
        #endif
    }

    /// Triggers refresh for a specific widget kind
    func refreshWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    // MARK: - Sync Frame Selection

    /// Syncs the current frame selection to shared storage
    /// Call this when frame selection changes in the main app
    func syncFrameSelection(frameId: String?, frameName: String?) {
        selectedFrameId = frameId
        selectedFrameName = frameName
    }
}

// MARK: - Widget Data Helpers

extension SharedDataManager {
    /// Returns the next upcoming event for widget display
    var nextUpcomingEvent: WidgetEvent? {
        loadEvents().nextUpcoming
    }

    /// Returns today's events for widget display
    var todayEvents: [WidgetEvent] {
        loadEvents().todayEvents
    }

    /// Returns whether there is data available for the widget
    var hasValidData: Bool {
        guard let timestamp = lastUpdateTimestamp else { return false }
        // Data is valid for 24 hours
        return Date().timeIntervalSince(timestamp) < 24 * 60 * 60
    }
}
