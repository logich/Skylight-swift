import Foundation
@testable import SkylightApp

/// Factory for creating test data objects
enum TestDataFactory {

    // MARK: - Calendar Events

    static func makeCalendarEvent(
        id: String = UUID().uuidString,
        title: String = "Test Event",
        description: String? = nil,
        startDate: Date = Date().addingTimeInterval(3600), // 1 hour from now
        endDate: Date = Date().addingTimeInterval(7200),   // 2 hours from now
        isAllDay: Bool = false,
        location: String? = nil,
        isRecurring: Bool = false,
        categoryId: String? = nil,
        categoryColor: String? = "#007AFF",
        attendees: [EventAttendee] = []
    ) -> CalendarEvent {
        CalendarEvent(
            id: id,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location,
            isRecurring: isRecurring,
            categoryId: categoryId,
            categoryColor: categoryColor,
            attendees: attendees
        )
    }

    static func makeCalendarEvents(count: Int, startingFrom baseDate: Date = Date()) -> [CalendarEvent] {
        (0..<count).map { index in
            let startDate = Calendar.current.date(byAdding: .hour, value: index, to: baseDate) ?? baseDate
            let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
            return makeCalendarEvent(
                id: "event-\(index)",
                title: "Event \(index)",
                startDate: startDate,
                endDate: endDate
            )
        }
    }

    // MARK: - Widget Events

    static func makeWidgetEvent(
        id: String = UUID().uuidString,
        title: String = "Test Event",
        startDate: Date = Date().addingTimeInterval(3600),
        endDate: Date = Date().addingTimeInterval(7200),
        location: String? = nil,
        isAllDay: Bool = false,
        categoryColor: String? = "#007AFF",
        driveTimeMinutes: Int? = nil,
        bufferMinutes: Int = 10,
        attendeeNames: [String] = []
    ) -> WidgetEvent {
        WidgetEvent(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            isAllDay: isAllDay,
            categoryColor: categoryColor,
            driveTimeMinutes: driveTimeMinutes,
            bufferMinutes: bufferMinutes,
            attendeeNames: attendeeNames
        )
    }

    // MARK: - Chores

    static func makeChore(
        id: String = UUID().uuidString,
        title: String = "Test Chore",
        dueDate: Date? = nil,
        assigneeId: String? = nil,
        assigneeName: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        points: Int? = nil
    ) -> Chore {
        Chore(
            id: id,
            title: title,
            dueDate: dueDate,
            assigneeId: assigneeId,
            assigneeName: assigneeName,
            isCompleted: isCompleted,
            completedAt: completedAt,
            points: points
        )
    }

    // MARK: - Family Members

    static func makeFamilyMember(
        id: String = UUID().uuidString,
        name: String = "Test Member",
        color: String? = "#FF0000",
        avatarUrl: String? = nil,
        linkedToProfile: Bool = true
    ) -> FamilyMember {
        FamilyMember(
            id: id,
            name: name,
            color: color,
            avatarUrl: avatarUrl,
            linkedToProfile: linkedToProfile
        )
    }

    // MARK: - Frames

    static func makeFrame(
        id: String = UUID().uuidString,
        name: String = "Test Frame"
    ) -> Frame {
        Frame(id: id, name: name)
    }

    // MARK: - Shopping Lists

    static func makeShoppingList(
        id: String = UUID().uuidString,
        name: String = "Test List"
    ) -> ShoppingList {
        ShoppingList(id: id, name: name)
    }

    static func makeListItem(
        id: String = UUID().uuidString,
        title: String = "Test Item",
        quantity: String? = nil,
        notes: String? = nil,
        isChecked: Bool = false
    ) -> ListItem {
        ListItem(
            id: id,
            title: title,
            quantity: quantity,
            notes: notes,
            isChecked: isChecked
        )
    }

    // MARK: - Large Dataset Generation

    /// Creates a large dataset of events for performance testing
    static func makeLargeEventDataset(count: Int = 500) -> [CalendarEvent] {
        let baseDate = Date()
        let calendar = Calendar.current

        return (0..<count).map { index in
            // Spread events over 90 days
            let dayOffset = index % 90
            let hourOffset = (index / 90) % 24

            let startDate = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: calendar.startOfDay(for: baseDate)
            )!
            let adjustedStart = calendar.date(byAdding: .hour, value: hourOffset, to: startDate)!
            let endDate = calendar.date(byAdding: .hour, value: 1, to: adjustedStart)!

            let hasLocation = index % 3 == 0 // ~33% have locations
            let isAllDay = index % 10 == 0   // 10% are all-day

            return makeCalendarEvent(
                id: "perf-event-\(index)",
                title: "Performance Test Event \(index)",
                startDate: adjustedStart,
                endDate: endDate,
                isAllDay: isAllDay,
                location: hasLocation ? "123 Test Street, City \(index % 10)" : nil,
                categoryColor: ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF"][index % 5]
            )
        }
    }
}
