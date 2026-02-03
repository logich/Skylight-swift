import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEventViewModel
    @FocusState private var focusedField: Field?
    @State private var showLocationSearch = false

    let onEventSaved: () -> Void

    private enum Field { case title, description }

    /// Initialize for creating a new event
    init(selectedDate: Date = Date(), onEventCreated: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: CreateEventViewModel(initialDate: selectedDate))
        self.onEventSaved = onEventCreated
    }

    /// Initialize for editing an existing event
    init(event: CalendarEvent, onEventSaved: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: CreateEventViewModel(event: event))
        self.onEventSaved = onEventSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                }

                Section {
                    Toggle("All-day", isOn: $viewModel.isAllDay)

                    if viewModel.isAllDay {
                        DatePicker("Starts", selection: $viewModel.startDate, displayedComponents: .date)
                        DatePicker("Ends", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                    } else {
                        DatePicker("Starts", selection: $viewModel.startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Ends", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section {
                    profileSelectionView
                } header: {
                    Text("Select profile(s)")
                }

                Section {
                    Button {
                        showLocationSearch = true
                    } label: {
                        HStack {
                            Text("Location")
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.location.isEmpty {
                                Text("Add")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(viewModel.location)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Section {
                    TextField("Description", text: $viewModel.eventDescription, axis: .vertical)
                        .focused($focusedField, equals: .description)
                        .lineLimit(3...6)
                }

                if viewModel.isEditMode {
                    Section {
                        Button(role: .destructive) {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                if viewModel.isDeleting {
                                    ProgressView()
                                        .tint(.red)
                                } else {
                                    Text("Delete Event")
                                }
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isLoading || viewModel.isDeleting)
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Event" : "Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditMode ? "Save" : "Add") {
                        Task {
                            if await viewModel.saveEvent() {
                                onEventSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading || viewModel.isDeleting)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Failed to save event")
            }
            .confirmationDialog(
                "Delete Event",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        if await viewModel.deleteEvent() {
                            onEventSaved()
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
            .task {
                await viewModel.loadProfiles()
            }
            .sheet(isPresented: $showLocationSearch) {
                LocationSearchView(initialLocation: viewModel.location) { selectedLocation in
                    viewModel.location = selectedLocation
                }
            }
            .onAppear { focusedField = .title }
        }
    }

    @ViewBuilder
    private var profileSelectionView: some View {
        if viewModel.isLoadingProfiles {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading profiles...")
                    .foregroundStyle(.secondary)
            }
        } else if viewModel.availableProfiles.isEmpty {
            Text("No profiles available")
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 12)], spacing: 12) {
                ForEach(viewModel.availableProfiles) { profile in
                    ProfileSelectionItem(
                        profile: profile,
                        isSelected: viewModel.selectedProfileIds.contains(profile.id),
                        onTap: { viewModel.toggleProfile(profile.id) }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct ProfileSelectionItem: View {
    let profile: FamilyMember
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(profile.displayColor)
                        .frame(width: 44, height: 44)

                    if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Text(profile.initials)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    } else {
                        Text(profile.initials)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                            .frame(width: 48, height: 48)

                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 16, y: -16)
                    }
                }

                Text(profile.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateEventView(onEventCreated: {})
}
