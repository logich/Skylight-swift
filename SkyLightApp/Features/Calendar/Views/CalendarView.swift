import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateNavigation

                if viewModel.isLoading && viewModel.events.isEmpty {
                    loadingView
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
                                viewModel.displayMode = mode
                                Task { await viewModel.loadEvents() }
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
                await viewModel.loadEvents()
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

                    if let sourceName = event.sourceName {
                        Text(sourceName)
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

            if let location = event.location, !location.isEmpty {
                Section("Location") {
                    Label(location, systemImage: "mappin.circle")
                }
            }

            if let description = event.description, !description.isEmpty {
                Section("Notes") {
                    Text(description)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthenticationManager.shared)
}
