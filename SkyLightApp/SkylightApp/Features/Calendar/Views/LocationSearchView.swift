import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String
    @State private var searchResults: [LocationSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    let initialLocation: String
    let onLocationSelected: (String) -> Void

    init(initialLocation: String = "", onLocationSelected: @escaping (String) -> Void) {
        self.initialLocation = initialLocation
        self._searchText = State(initialValue: initialLocation)
        self.onLocationSelected = onLocationSelected
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    // Option to use the typed text as-is
                    Button {
                        onLocationSelected(searchText)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "text.cursor")
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text("Use \"\(searchText)\"")
                                    .foregroundStyle(.primary)
                                Text("Enter custom location")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if !searchResults.isEmpty {
                    Section("Search Results") {
                        ForEach(searchResults) { result in
                            Button {
                                onLocationSelected(result.displayText)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.red)
                                        .frame(width: 30)
                                    VStack(alignment: .leading) {
                                        if !result.name.isEmpty {
                                            Text(result.name)
                                                .foregroundStyle(.primary)
                                        }
                                        if !result.address.isEmpty {
                                            Text(result.address)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if !searchText.isEmpty {
                    Text("No results found")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if !initialLocation.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            onLocationSelected("")
                            dismiss()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search for a place")
            .onChange(of: searchText) { _, newValue in
                performSearch(query: newValue)
            }
            .onAppear {
                if !searchText.isEmpty {
                    performSearch(query: searchText)
                }
            }
        }
    }

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            isSearching = true
            defer { isSearching = false }

            do {
                let results = try await LocationService.shared.searchLocations(query: query)
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                if !Task.isCancelled {
                    searchResults = []
                }
            }
        }
    }
}

#Preview {
    LocationSearchView { location in
        print("Selected: \(location)")
    }
}
