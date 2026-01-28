import SwiftUI

struct ListsView: View {
    @StateObject private var viewModel = ListsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.lists.isEmpty {
                    loadingView
                } else if viewModel.lists.isEmpty {
                    emptyState
                } else {
                    listsList
                }
            }
            .navigationTitle("Lists")
            .task {
                await viewModel.loadLists()
            }
            .refreshable {
                await viewModel.loadLists()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading lists...")
            Spacer()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Lists", systemImage: "list.bullet")
        } description: {
            Text("Lists from your Skylight will appear here.")
        }
    }

    private var listsList: some View {
        List(viewModel.lists) { list in
            NavigationLink {
                ListDetailView(listId: list.id, listName: list.name)
            } label: {
                ListRow(list: list)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct ListRow: View {
    let list: ShoppingList

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForListType(list.type))
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)

                if let itemCount = list.itemCount {
                    Text("\(itemCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func iconForListType(_ type: String?) -> String {
        switch type?.lowercased() {
        case "grocery", "shopping":
            return "cart"
        case "todo":
            return "checklist"
        default:
            return "list.bullet"
        }
    }
}

struct ListDetailView: View {
    @StateObject private var viewModel: ListDetailViewModel
    @FocusState private var isInputFocused: Bool

    let listName: String

    init(listId: String, listName: String) {
        _viewModel = StateObject(wrappedValue: ListDetailViewModel(listId: listId))
        self.listName = listName
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.items.isEmpty {
                loadingView
            } else {
                itemsList
            }

            addItemBar
        }
        .navigationTitle(listName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadItems()
        }
        .refreshable {
            await viewModel.loadItems()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error")
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading items...")
            Spacer()
        }
    }

    private var itemsList: some View {
        List {
            if viewModel.items.isEmpty {
                ContentUnavailableView {
                    Label("No Items", systemImage: "tray")
                } description: {
                    Text("Add items to this list below.")
                }
                .listRowBackground(Color.clear)
            } else {
                if !viewModel.uncheckedItems.isEmpty {
                    Section {
                        ForEach(viewModel.uncheckedItems) { item in
                            ListItemRow(item: item) {
                                Task { await viewModel.toggleItem(item) }
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteItem(viewModel.uncheckedItems[index])
                                }
                            }
                        }
                    }
                }

                if !viewModel.checkedItems.isEmpty {
                    Section("Checked off") {
                        ForEach(viewModel.checkedItems) { item in
                            ListItemRow(item: item) {
                                Task { await viewModel.toggleItem(item) }
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteItem(viewModel.checkedItems[index])
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var addItemBar: some View {
        HStack(spacing: 12) {
            TextField("Add item...", text: $viewModel.newItemTitle)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit {
                    Task { await viewModel.addItem() }
                }

            Button {
                Task { await viewModel.addItem() }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .disabled(viewModel.newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, y: -5)
    }
}

struct ListItemRow: View {
    let item: ListItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.title)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)

                    if let quantity = item.displayQuantity {
                        Text(quantity)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let addedByName = item.addedByName {
                    Text("Added by \(addedByName)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ListsView()
        .environmentObject(AuthenticationManager.shared)
}
