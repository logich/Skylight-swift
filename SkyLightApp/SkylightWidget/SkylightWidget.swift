import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct SkylightWidgetEntry: TimelineEntry {
    let date: Date
    let event: WidgetEvent?
    let state: WidgetState

    enum WidgetState {
        case noData          // No events data available
        case noUpcoming      // No upcoming events
        case upcoming        // Showing next event (not yet time to leave)
        case leaveNow        // It's time to leave
        case eventStarted    // Event has started
    }
}

// MARK: - Timeline Provider

struct SkylightWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SkylightWidgetEntry {
        SkylightWidgetEntry(
            date: Date(),
            event: sampleEvent,
            state: .upcoming
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SkylightWidgetEntry) -> Void) {
        let events = loadEvents()
        let nextEvent = events.nextUpcoming

        let entry = SkylightWidgetEntry(
            date: Date(),
            event: nextEvent ?? sampleEvent,
            state: nextEvent != nil ? determineState(for: nextEvent!) : .noUpcoming
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SkylightWidgetEntry>) -> Void) {
        var entries: [SkylightWidgetEntry] = []
        let events = loadEvents()
        let now = Date()

        // Get upcoming events (not started yet and not all-day)
        let upcomingEvents = events
            .filter { !$0.hasStarted && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        if upcomingEvents.isEmpty {
            // No more upcoming events - check for tomorrow's events
            let tomorrowEvents = events.tomorrowEvents
            if let nextEvent = tomorrowEvents.first {
                entries.append(SkylightWidgetEntry(
                    date: now,
                    event: nextEvent,
                    state: .upcoming
                ))
            } else {
                // No upcoming events at all
                entries.append(SkylightWidgetEntry(
                    date: now,
                    event: nil,
                    state: .noUpcoming
                ))
            }
        } else {
            // Create entries for state transitions
            for event in upcomingEvents.prefix(5) {
                if event.hasStarted {
                    // Event is already in progress
                    entries.append(SkylightWidgetEntry(
                        date: now,
                        event: event,
                        state: .eventStarted
                    ))

                    // Entry when event ends (refresh to show next event)
                    entries.append(SkylightWidgetEntry(
                        date: event.endDate,
                        event: event,
                        state: .eventStarted
                    ))
                } else if let leaveByDate = event.leaveByDate, leaveByDate > now {
                    // Entry for "upcoming" state (now until leave time)
                    entries.append(SkylightWidgetEntry(
                        date: now,
                        event: event,
                        state: .upcoming
                    ))

                    // Entry for "leave now" state (at leave time)
                    entries.append(SkylightWidgetEntry(
                        date: leaveByDate,
                        event: event,
                        state: .leaveNow
                    ))

                    // Entry when event starts
                    entries.append(SkylightWidgetEntry(
                        date: event.startDate,
                        event: event,
                        state: .eventStarted
                    ))
                } else if event.leaveByDate != nil && event.leaveByDate! <= now && !event.hasStarted {
                    // Already past leave time but event hasn't started
                    entries.append(SkylightWidgetEntry(
                        date: now,
                        event: event,
                        state: .leaveNow
                    ))

                    // Entry when event starts
                    entries.append(SkylightWidgetEntry(
                        date: event.startDate,
                        event: event,
                        state: .eventStarted
                    ))
                } else {
                    // No drive time, just show upcoming
                    entries.append(SkylightWidgetEntry(
                        date: now,
                        event: event,
                        state: .upcoming
                    ))

                    // Entry when event starts
                    entries.append(SkylightWidgetEntry(
                        date: event.startDate,
                        event: event,
                        state: .eventStarted
                    ))
                }
            }
        }

        // Sort entries by date
        entries.sort { $0.date < $1.date }

        // Refresh policy: after the last event starts or in 1 hour
        let refreshDate = entries.last?.date.addingTimeInterval(60) ?? now.addingTimeInterval(3600)

        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    // MARK: - Helpers

    private func loadEvents() -> [WidgetEvent] {
        guard let defaults = UserDefaults(suiteName: SharedConstants.appGroupId),
              let data = defaults.data(forKey: SharedConstants.UserDefaultsKeys.cachedEventsWithDriveTime) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WidgetEvent].self, from: data)
        } catch {
            return []
        }
    }

    private func determineState(for event: WidgetEvent) -> SkylightWidgetEntry.WidgetState {
        if event.hasStarted {
            return .eventStarted
        } else if event.shouldLeaveNow {
            return .leaveNow
        } else {
            return .upcoming
        }
    }

    private var sampleEvent: WidgetEvent {
        WidgetEvent(
            id: "sample",
            title: "Softball Practice",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            location: "City Park Field #3",
            isAllDay: false,
            categoryColor: "#4A90D9",
            driveTimeMinutes: 15,
            bufferMinutes: 10,
            attendeeNames: ["Emma", "Liam"]
        )
    }
}

// MARK: - Widget Views

struct SkylightWidgetEntryView: View {
    var entry: SkylightWidgetProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: SkylightWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let event = entry.event {
                // Show "Tomorrow" if event is tomorrow
                if isTomorrow(event.startDate) {
                    Text("Tomorrow")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fontWeight(.medium)
                }

                // Event title
                Text(event.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(entry.state == .leaveNow ? .white : .primary)

                Spacer()

                // Time display - start time in white/primary, end time in gray
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.startDate, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(entry.state == .leaveNow ? .white : .primary)

                    Text(event.endDate, style: .time)
                        .font(.caption)
                        .foregroundStyle(entry.state == .leaveNow ? .white.opacity(0.7) : .secondary)
                }

                // Family members
                if let attendees = event.attendeesDisplay {
                    Text(attendees)
                        .font(.caption2)
                        .foregroundStyle(entry.state == .leaveNow ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }

                // Drive time or leave countdown
                if entry.state == .leaveNow {
                    Text("Leave Now!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else if let countdown = event.leaveCountdownDisplay {
                    Text(countdown)
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let driveTime = event.driveTimeDisplay {
                    Text(driveTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                // No upcoming events
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(backgroundGradient)
    }

    private var backgroundGradient: some View {
        Group {
            if entry.state == .leaveNow {
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.clear
            }
        }
    }

    private func isTomorrow(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        return calendar.isDate(date, inSameDayAs: tomorrow)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: SkylightWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            if let event = entry.event {
                // Left side - event info
                VStack(alignment: .leading, spacing: 4) {
                    // Show "Tomorrow" if event is tomorrow
                    if isTomorrow(event.startDate) {
                        Text("Tomorrow")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }

                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)

                    // Time display - start time in primary, end time in gray
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.startDate, style: .time)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Text(event.endDate, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Family members
                    if let attendees = event.attendeesDisplay {
                        Label {
                            Text(attendees)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "person.2")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    // Location (if present)
                    if let location = event.location {
                        Label {
                            Text(location)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "mappin")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Spacer()

                // Right side - drive time info
                VStack(alignment: .trailing, spacing: 4) {
                    if entry.state == .leaveNow {
                        leaveNowBadge
                    } else if let countdown = event.leaveCountdownDisplay {
                        countdownBadge(countdown)
                    }

                    Spacer()

                    if let driveTime = event.driveTimeDisplay {
                        Label {
                            Text(driveTime)
                        } icon: {
                            Image(systemName: "car.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
            } else {
                // No upcoming events
                HStack {
                    Image(systemName: "calendar")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading) {
                        Text("No upcoming events")
                            .font(.headline)
                        Text("Your calendar is clear")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var leaveNowBadge: some View {
        Text("Leave Now!")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(.orange))
    }

    private func countdownBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().strokeBorder(.orange, lineWidth: 1))
    }

    private func isTomorrow(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        return calendar.isDate(date, inSameDayAs: tomorrow)
    }
}

// MARK: - Accessory Circular View (Lock Screen)

struct AccessoryCircularView: View {
    let entry: SkylightWidgetEntry

    var body: some View {
        if let event = entry.event {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 2) {
                    if entry.state == .leaveNow {
                        Image(systemName: "car.fill")
                            .font(.caption)
                        Text("GO")
                            .font(.caption2)
                            .fontWeight(.bold)
                    } else if let minutes = event.minutesUntilLeave, minutes < 60 {
                        Text("\(minutes)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("min")
                            .font(.caption2)
                    } else {
                        Text(event.startDate, style: .time)
                            .font(.caption2)
                    }
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "calendar")
            }
        }
    }
}

// MARK: - Accessory Rectangular View (Lock Screen)

struct AccessoryRectangularView: View {
    let entry: SkylightWidgetEntry

    var body: some View {
        if let event = entry.event {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(event.startDate, style: .time)

                    if entry.state == .leaveNow {
                        Text("Leave now!")
                            .fontWeight(.bold)
                    } else if let countdown = event.leaveCountdownDisplay {
                        Text(countdown)
                    }
                }
                .font(.caption)
            }
        } else {
            Text("No upcoming events")
                .font(.caption)
        }
    }
}

// MARK: - Widget Definition

struct SkylightWidget: Widget {
    let kind: String = "SkylightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SkylightWidgetProvider()) { entry in
            SkylightWidgetEntryView(entry: entry)
                .widgetURL(entry.event.flatMap { SharedConstants.URLScheme.eventURL(id: $0.id) })
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Skylight Calendar")
        .description("Shows your next event with drive time and leave countdown")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Widget Bundle

@main
struct SkylightWidgetBundle: WidgetBundle {
    var body: some Widget {
        SkylightWidget()
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    SkylightWidget()
} timeline: {
    SkylightWidgetEntry(
        date: Date(),
        event: WidgetEvent(
            id: "1",
            title: "Softball Practice",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            location: "City Park Field #3",
            isAllDay: false,
            categoryColor: "#4A90D9",
            driveTimeMinutes: 15,
            bufferMinutes: 10,
            attendeeNames: ["Emma", "Liam"]
        ),
        state: .upcoming
    )

    SkylightWidgetEntry(
        date: Date(),
        event: WidgetEvent(
            id: "1",
            title: "Soccer Game",
            startDate: Date().addingTimeInterval(600),
            endDate: Date().addingTimeInterval(4200),
            location: "Sports Complex",
            isAllDay: false,
            categoryColor: "#4A90D9",
            driveTimeMinutes: 15,
            bufferMinutes: 10,
            attendeeNames: ["Emma"]
        ),
        state: .leaveNow
    )

    SkylightWidgetEntry(
        date: Date(),
        event: nil,
        state: .noUpcoming
    )
}
