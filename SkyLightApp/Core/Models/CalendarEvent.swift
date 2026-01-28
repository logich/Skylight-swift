import Foundation
import SwiftUI

struct CalendarEvent: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool?
    let location: String?
    let color: String?
    let sourceId: String?
    let sourceName: String?
    let recurrence: String?

    var displayColor: Color {
        guard let colorHex = color else { return .blue }
        return Color(hex: colorHex) ?? .blue
    }

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var isMultiDay: Bool {
        let calendar = Calendar.current
        return !calendar.isDate(startDate, inSameDayAs: endDate)
    }
}

struct CalendarEventsResponse: Codable {
    let events: [CalendarEvent]
}

struct CalendarSource: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: String?
    let color: String?
    let isEnabled: Bool?
}

struct CalendarSourcesResponse: Codable {
    let sources: [CalendarSource]
}
