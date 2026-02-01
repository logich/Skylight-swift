import Foundation
import SwiftUI

/// Lightweight event model for sharing between app and widget
/// Contains only the essential data needed for widget display and notifications
struct WidgetEvent: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let isAllDay: Bool
    let categoryColor: String?

    /// Drive time in minutes from current location to event location
    /// Nil if location is not available or drive time couldn't be calculated
    let driveTimeMinutes: Int?

    /// The buffer time in minutes that was used when calculating leave time
    let bufferMinutes: Int

    /// Family member names assigned to the event
    let attendeeNames: [String]

    // MARK: - Computed Properties

    /// The color to display for this event
    var displayColor: Color {
        guard let colorHex = categoryColor else { return .blue }
        return Color(hex: colorHex) ?? .blue
    }

    /// The time the user should leave to arrive on time
    /// Returns nil if drive time is not available
    var leaveByDate: Date? {
        guard let driveTime = driveTimeMinutes else { return nil }
        let totalMinutes = driveTime + bufferMinutes
        return startDate.addingTimeInterval(-Double(totalMinutes) * 60)
    }

    /// Minutes until the user should leave
    /// Returns nil if no leave time is calculated
    var minutesUntilLeave: Int? {
        guard let leaveBy = leaveByDate else { return nil }
        let minutes = Int(leaveBy.timeIntervalSinceNow / 60)
        return max(0, minutes)
    }

    /// Whether it's time to leave (leave time has passed but event hasn't started)
    var shouldLeaveNow: Bool {
        guard let leaveBy = leaveByDate else { return false }
        return Date() >= leaveBy && Date() < startDate
    }

    /// Whether the event has already started
    var hasStarted: Bool {
        Date() >= startDate
    }

    /// Whether the event has ended
    var hasEnded: Bool {
        Date() >= endDate
    }

    /// Duration of the event in minutes
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    /// Formatted attendee names (e.g., "John, Jane")
    var attendeesDisplay: String? {
        guard !attendeeNames.isEmpty else { return nil }
        return attendeeNames.joined(separator: ", ")
    }

    /// Formatted drive time string (e.g., "15 min drive")
    var driveTimeDisplay: String? {
        guard let minutes = driveTimeMinutes else { return nil }
        if minutes < 60 {
            return "\(minutes) min drive"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr drive"
            } else {
                return "\(hours) hr \(remainingMinutes) min drive"
            }
        }
    }

    /// Formatted leave time string (e.g., "Leave by 2:30 PM")
    var leaveByDisplay: String? {
        guard let leaveBy = leaveByDate else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Leave by \(formatter.string(from: leaveBy))"
    }

    /// Formatted countdown string (e.g., "Leave in 15 min")
    var leaveCountdownDisplay: String? {
        guard let minutes = minutesUntilLeave else { return nil }
        if minutes <= 0 {
            return "Leave now!"
        } else if minutes < 60 {
            return "Leave in \(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "Leave in \(hours) hr"
            } else {
                return "Leave in \(hours) hr \(remainingMinutes) min"
            }
        }
    }

    // MARK: - Initialization

    /// Direct initializer
    init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        isAllDay: Bool,
        categoryColor: String?,
        driveTimeMinutes: Int?,
        bufferMinutes: Int,
        attendeeNames: [String] = []
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.isAllDay = isAllDay
        self.categoryColor = categoryColor
        self.driveTimeMinutes = driveTimeMinutes
        self.bufferMinutes = bufferMinutes
        self.attendeeNames = attendeeNames
    }
}

// MARK: - Array Extension for WidgetEvent

extension Array where Element == WidgetEvent {
    /// Returns the next upcoming event that hasn't ended
    var nextUpcoming: WidgetEvent? {
        self
            .filter { !$0.hasEnded && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    /// Returns events that are happening today
    var todayEvents: [WidgetEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return self.filter { event in
            event.startDate >= today && event.startDate < tomorrow
        }.sorted { $0.startDate < $1.startDate }
    }

    /// Returns events that are happening tomorrow
    var tomorrowEvents: [WidgetEvent] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: tomorrow)!

        return self.filter { event in
            event.startDate >= tomorrow && event.startDate < dayAfter && !event.isAllDay
        }.sorted { $0.startDate < $1.startDate }
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count

        switch length {
        case 6: // RGB (e.g., "FF5733")
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        case 8: // RGBA (e.g., "FF5733FF")
            let r = Double((rgb & 0xFF000000) >> 24) / 255.0
            let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let a = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        default:
            return nil
        }
    }
}
