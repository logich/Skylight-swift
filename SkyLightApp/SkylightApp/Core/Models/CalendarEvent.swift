import Foundation
import SwiftUI

// MARK: - Event Attendee (Family Member)
struct EventAttendee: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let color: String?
    let avatarUrl: String?

    var displayColor: Color {
        guard let colorHex = color else { return .gray }
        return Color(hex: colorHex) ?? .gray
    }

    var initials: String {
        String(name.prefix(1)).uppercased()
    }
}

// MARK: - Simple CalendarEvent Model
struct CalendarEvent: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let isRecurring: Bool
    let categoryId: String?
    let categoryColor: String?
    let attendees: [EventAttendee]

    var displayColor: Color {
        guard let colorHex = categoryColor else { return .blue }
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

// MARK: - JSON:API Calendar Events Response
struct CalendarEventsResponse: Codable {
    let data: [CalendarEventData]
    let included: [CalendarIncludedData]?

    var events: [CalendarEvent] {
        // Build a lookup for categories by id (includes color, label, avatar, linkedToProfile)
        var categoryInfo: [String: CalendarIncludedData] = [:]
        if let included = included {
            for item in included where item.type == "category" {
                categoryInfo[item.id] = item
            }
        }

        return data.compactMap { eventData -> CalendarEvent? in
            // Dates are decoded automatically by JSONCoders
            guard let startDate = eventData.attributes.startsAt,
                  let endDate = eventData.attributes.endsAt else {
                #if DEBUG
                print("CalendarEvent: Missing start or end date for event \(eventData.id)")
                #endif
                return nil
            }

            // Get all category IDs for this event
            let categoryIds = eventData.relationships?.categories?.data?.map { $0.id } ?? []

            // Get primary category color (first category)
            let primaryCategoryId = categoryIds.first
            let primaryCategoryColor = primaryCategoryId.flatMap { categoryInfo[$0]?.attributes?.color }

            // Build attendees list from categories that are linked to profiles (family members)
            let attendees: [EventAttendee] = categoryIds.compactMap { categoryId -> EventAttendee? in
                guard let info = categoryInfo[categoryId],
                      let attrs = info.attributes,
                      let label = attrs.label else {
                    return nil
                }
                // Include all categories as attendees (they represent family members assigned to events)
                return EventAttendee(
                    id: categoryId,
                    name: label,
                    color: attrs.color,
                    avatarUrl: attrs.profilePicUrl
                )
            }

            return CalendarEvent(
                id: eventData.id,
                title: eventData.attributes.summary,
                description: eventData.attributes.description,
                startDate: startDate,
                endDate: endDate,
                isAllDay: eventData.attributes.allDay ?? false,
                location: eventData.attributes.location,
                isRecurring: eventData.attributes.recurring ?? false,
                categoryId: primaryCategoryId,
                categoryColor: primaryCategoryColor,
                attendees: attendees
            )
        }
    }
}

struct CalendarEventData: Codable {
    let id: String
    let type: String
    let attributes: CalendarEventAttributes
    let relationships: CalendarEventRelationships?
}

struct CalendarEventAttributes: Codable {
    let summary: String
    let description: String?
    let location: String?
    let allDay: Bool?
    let timezone: String?
    let startsAt: Date?
    let endsAt: Date?
    let recurring: Bool?
    let rrule: [String]?
}

struct CalendarEventRelationships: Codable {
    let categories: CalendarCategoryRelationship?
}

struct CalendarCategoryRelationship: Codable {
    let data: [CalendarResourceIdentifier]?
}

struct CalendarResourceIdentifier: Codable {
    let id: String
    let type: String
}

struct CalendarIncludedData: Codable {
    let id: String
    let type: String
    let attributes: CalendarIncludedAttributes?
}

struct CalendarIncludedAttributes: Codable {
    let color: String?
    let label: String?
    let profilePicUrl: String?
    let linkedToProfile: Bool?
}
