import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @ObservedObject private var deepLinkManager = DeepLinkManager.shared
    @State private var deepLinkEvent: CalendarEvent?
    @State private var showDeepLinkEvent = false
    @State private var showSettings = false
    @State private var isSearching = false
    @State private var showCreateEvent = false

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") {
                        viewModel.goToToday()
                    }
                    .disabled(viewModel.selectedDate.isToday)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        isSearching = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }

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
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(
                    selectedDate: viewModel.selectedDate,
                    onEventCreated: {
                        Task { await viewModel.refreshEvents() }
                    }
                )
            }
            .searchable(
                text: $viewModel.searchQuery,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search events"
            )
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
            .onChange(of: deepLinkManager.pendingEventId) { _, eventId in
                if let eventId = eventId {
                    handleDeepLinkNavigation(eventId: eventId)
                }
            }
            .navigationDestination(isPresented: $showDeepLinkEvent) {
                if let event = deepLinkEvent {
                    EventDetailView(event: event) {
                        Task { await viewModel.refreshEvents() }
                    }
                }
            }
        }
    }

    private func handleDeepLinkNavigation(eventId: String) {
        if let event = viewModel.events.first(where: { $0.id == eventId }) {
            deepLinkEvent = event
            showDeepLinkEvent = true
            deepLinkManager.clearPendingEvent()
            return
        }

        Task {
            if let event = await viewModel.fetchEvent(byId: eventId) {
                deepLinkEvent = event
                showDeepLinkEvent = true
            }
            deepLinkManager.clearPendingEvent()
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
                            EventDetailView(event: event) {
                                Task { await viewModel.refreshEvents() }
                            }
                        } label: {
                        EventRow(event: event)
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                } header: {
                    Text(date.displayDate)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedEvents: [Date: [CalendarEvent]] {
        Dictionary(grouping: viewModel.filteredEvents) { event in
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
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
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
            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
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
                    EventDetailView(event: event) {
                        Task { await viewModel.refreshEvents() }
                    }
                } label: {
                    EventRow(event: event)
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

struct EventRow: View {
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

struct EventDetailView: View {
    let event: CalendarEvent
    let onEventUpdated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showEditEvent = false
    @State private var eventWasDeleted = false

    init(event: CalendarEvent, onEventUpdated: @escaping () -> Void = {}) {
        self.event = event
        self.onEventUpdated = onEventUpdated
    }

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
                    DriveTimeRow(location: location)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditEvent = true
                }
            }
        }
        .sheet(isPresented: $showEditEvent) {
            CreateEventView(event: event) {
                onEventUpdated()
                eventWasDeleted = true
            }
        }
        .onChange(of: eventWasDeleted) { _, deleted in
            if deleted {
                dismiss()
            }
        }
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

// MARK: - Drive Time Components

struct DriveTimeBadge: View {
    let location: String

    @State private var driveTimeMinutes: Int?
    @State private var isLoading = false
    @State private var hasFailed = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            } else if let minutes = driveTimeMinutes {
                HStack(spacing: 2) {
                    Image(systemName: "car.fill")
                    Text("\(minutes)m")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else if hasFailed {
                EmptyView()
            }
        }
        .task {
            await fetchDriveTime()
        }
    }

    private func fetchDriveTime() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let minutes = try await LocationService.shared.getDrivingTimeToAddress(location)
            driveTimeMinutes = minutes
        } catch {
            hasFailed = true
        }
    }
}

struct DriveTimeRow: View {
    let location: String

    @State private var driveTimeMinutes: Int?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        HStack {
            Label {
                if isLoading {
                    Text("Calculating drive time...")
                        .foregroundStyle(.secondary)
                } else if let minutes = driveTimeMinutes {
                    Text("\(minutes) min drive from current location")
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Tap to calculate drive time")
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "car.fill")
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await fetchDriveTime()
            }
        }
        .task {
            await fetchDriveTime()
        }
    }

    private func fetchDriveTime() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let minutes = try await LocationService.shared.getDrivingTimeToAddress(location)
            driveTimeMinutes = minutes
            errorMessage = nil
        } catch let error as LocationError {
            errorMessage = String(localized: error.localizedStringResource)
        } catch {
            errorMessage = "Unable to calculate drive time"
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthenticationManager.shared)
}
