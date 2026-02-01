import Foundation

/// Constants shared between the main app and widget extension
enum SharedConstants {
    /// App Group identifier for sharing data between app and widget
    static let appGroupId = "group.com.rosetrace.SkylightApp"

    /// Shared UserDefaults instance for App Group
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    /// Keys for shared UserDefaults
    enum UserDefaultsKeys {
        /// Whether drive time alerts are enabled (Bool)
        static let driveTimeAlertsEnabled = "driveTimeAlertsEnabled"

        /// Buffer time in minutes before calculated leave time (Int)
        static let bufferTimeMinutes = "bufferTimeMinutes"

        /// Encoded array of WidgetEvent with drive time info (Data)
        static let cachedEventsWithDriveTime = "cachedEventsWithDriveTime"

        /// Last time the cached events were updated (Date)
        static let lastUpdateTimestamp = "lastUpdateTimestamp"

        /// Currently selected frame ID for widget to use
        static let selectedFrameId = "selectedFrameId"

        /// Currently selected frame name for widget display
        static let selectedFrameName = "selectedFrameName"
    }

    /// Default values for settings
    enum Defaults {
        /// Drive time alerts are disabled by default
        static let driveTimeAlertsEnabled = false

        /// Default buffer time is 10 minutes
        static let bufferTimeMinutes = 10

        /// Available buffer time options in minutes
        static let bufferTimeOptions = [5, 10, 15, 20, 30]
    }

    /// Notification identifiers
    enum Notifications {
        /// Category identifier for time to leave notifications
        static let timeToLeaveCategoryId = "TIME_TO_LEAVE_CATEGORY"

        /// Prefix for time to leave notification identifiers
        static let timeToLeaveIdPrefix = "timeToLeave_"

        /// Action identifier for opening the event
        static let openEventActionId = "OPEN_EVENT_ACTION"

        /// Action identifier for starting climate control
        static let startClimateActionId = "START_CLIMATE_ACTION"

        /// Action identifier for dismissing the notification
        static let dismissActionId = "DISMISS_ACTION"
    }

    /// Background task identifiers
    enum BackgroundTasks {
        /// Identifier for the background refresh task
        static let refreshTaskId = "com.rosetrace.SkylightApp.refresh"
    }

    /// URL scheme for deep linking
    enum URLScheme {
        /// Base URL scheme
        static let scheme = "skylight"

        /// Host for event deep links
        static let eventHost = "event"

        /// Creates a deep link URL for an event
        static func eventURL(id: String) -> URL? {
            URL(string: "\(scheme)://\(eventHost)/\(id)")
        }
    }
}
