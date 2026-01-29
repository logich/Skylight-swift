import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateNavigation

                if viewModel.isLoading && viewModel.events.isEmpty {
                    loadingView
                } else if viewModel.displayMode == .month {
                    monthGridView
                } else if viewModel.events.isEmpty {
                    emptyState
                } else {
                    eventsList
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(CalendarViewModel.DisplayMode.allCases, id: \.self) { mode in
                            Button {
                                viewModel.changeDisplayMode(mode)
                            } label: {
                                HStack {
                                    Text(mode.rawValue)
                                    if viewModel.displayMode == mode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("View Mode", systemImage: "calendar.badge.clock")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") {
                        viewModel.goToToday()
                    }
                    .disabled(viewModel.selectedDate.isToday)
                }
            }
            .task {
                await viewModel.loadEvents()
            }
            .refreshable {
                await viewModel.loadEvents(forceRefresh: true)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
        }
    }

    private var dateNavigation: some View {
        HStack {
            Button {
                viewModel.goToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(dateTitle)
                .font(.headline)

            Spacer()

            Button {
                viewModel.goToNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        switch viewModel.displayMode {
        case .day:
            formatter.dateFormat = "EEEE, MMM d, yyyy"
        case .week:
            formatter.dateFormat = "'Week of' MMM d"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: viewModel.selectedDate)
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading events...")
            Spacer()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Events", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("There are no events scheduled for this time period.")
        }
    }

    private var eventsList: some View {
        List {
            ForEach(groupedEvents.keys.sorted(), id: \.self) { date in
                Section {
                    ForEach(groupedEvents[date] ?? []) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            CalendarEventRow(event: event)
                        }
                    }
                } header: {
                    Text(date.displayDate)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedEvents: [Date: [CalendarEvent]] {
        Dictionary(grouping: viewModel.events) { event in
            event.startDate.startOfDay
        }
    }

    // MARK: - Month Grid View (Native Calendar Style)

    @State private var selectedDayInMonth: Date = Date()

    private var monthGridView: some View {
        VStack(spacing: 0) {
            // Weekday headers
            weekdayHeader

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        MonthDayCell(
                            date: date,
                            events: groupedEvents[date.startOfDay] ?? [],
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDayInMonth),
                            isToday: date.isToday
                        ) {
                            selectedDayInMonth = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 8)

            Divider()
                .padding(.top, 12)

            // Events list for selected day
            selectedDayEventsList
        }
        .onAppear {
            selectedDayInMonth = viewModel.selectedDate
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = viewModel.selectedDate.startOfMonth

        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        // Get the weekday of the first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmptyDays = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        // Add trailing empty days to complete the grid
        let trailingEmptyDays = (7 - (days.count % 7)) % 7
        days.append(contentsOf: Array(repeating: nil, count: trailingEmptyDays))

        return days
    }

    private var eventsForSelectedDay: [CalendarEvent] {
        groupedEvents[selectedDayInMonth.startOfDay] ?? []
    }

    private var selectedDayEventsList: some View {
        List {
            ForEach(eventsForSelectedDay) { event in
                NavigationLink {
                    EventDetailView(event: event)
                } label: {
                    MonthEventRow(event: event)
                }
            }

            if eventsForSelectedDay.isEmpty {
                Text("No events")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Month View Components

struct MonthDayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private var uniqueEventColors: [Color] {
        // Get unique colors, limit to 3
        var seen = Set<String>()
        var colors: [Color] = []
        for event in events {
            let colorKey = event.categoryColor ?? "blue"
            if !seen.contains(colorKey) {
                seen.insert(colorKey)
                colors.append(event.displayColor)
                if colors.count >= 3 { break }
            }
        }
        return colors
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 17, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(dayTextColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isToday ? Color.white : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected && !isToday ? Color.accentColor : Color.clear, lineWidth: 2)
                    )

                // Event indicator dots
                HStack(spacing: 3) {
                    ForEach(Array(uniqueEventColors.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var dayTextColor: Color {
        if isToday {
            return .black
        }
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 { // Sunday
            return .red
        }
        return .primary
    }
}

struct MonthEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(event.displayColor)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                    .lineLimit(1)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Time
            VStack(alignment: .trailing, spacing: 2) {
                if event.isAllDay {
                    Text("all-day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(event.startDate.displayTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(event.endDate.displayTime)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.displayColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if event.isAllDay == true {
                        Text("All day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(event.startDate.displayTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let location = event.location, !location.isEmpty {
                        Label(location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EventDetailView: View {
    let event: CalendarEvent

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if event.isRecurring {
                        Label("Recurring", systemImage: "repeat")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            }

            Section("Time") {
                if event.isAllDay == true {
                    Label("All Day", systemImage: "sun.max")
                } else {
                    Label {
                        VStack(alignment: .leading) {
                            Text(event.startDate.displayDateTime)
                            if event.startDate != event.endDate {
                                Text("to \(event.endDate.displayDateTime)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "clock")
                    }
                }
            }

            if !event.attendees.isEmpty {
                Section("Family Members") {
                    ForEach(event.attendees) { attendee in
                        HStack(spacing: 12) {
                            AttendeeAvatarView(attendee: attendee)
                                .frame(width: 36, height: 36)

                            Text(attendee.name)
                                .font(.body)
                        }
                    }
                }
            }

            Section("Location") {
                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.circle")
                } else {
                    Text("No location")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notes") {
                if let description = event.description, !description.isEmpty {
                    Text(description)
                } else {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AttendeeAvatarView: View {
    let attendee: EventAttendee

    var body: some View {
        Group {
            if let avatarUrl = attendee.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(attendee.displayColor.opacity(0.2))

            Text(attendee.initials)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(attendee.displayColor)
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthenticationManager.shared)
}
