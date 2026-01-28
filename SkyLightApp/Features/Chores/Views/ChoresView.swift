import SwiftUI

struct ChoresView: View {
    @StateObject private var viewModel = ChoresViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.chores.isEmpty {
                    loadingView
                } else if viewModel.chores.isEmpty {
                    emptyState
                } else {
                    choresList
                }
            }
            .navigationTitle("Chores")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadChores()
            }
            .refreshable {
                await viewModel.loadChores()
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateChoreView(viewModel: viewModel)
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
            ProgressView("Loading chores...")
            Spacer()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Chores", systemImage: "checkmark.circle")
        } description: {
            Text("Add chores to track tasks for your family.")
        } actions: {
            Button {
                viewModel.showCreateSheet = true
            } label: {
                Text("Add Chore")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var choresList: some View {
        List {
            if !viewModel.overdueChores.isEmpty {
                Section("Overdue") {
                    ForEach(viewModel.overdueChores) { chore in
                        ChoreRow(chore: chore, onComplete: {
                            Task { await viewModel.markComplete(choreId: chore.id) }
                        })
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteChore(choreId: viewModel.overdueChores[index].id)
                            }
                        }
                    }
                }
            }

            if !viewModel.todayChores.isEmpty {
                Section("Today") {
                    ForEach(viewModel.todayChores) { chore in
                        ChoreRow(chore: chore, onComplete: {
                            Task { await viewModel.markComplete(choreId: chore.id) }
                        })
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteChore(choreId: viewModel.todayChores[index].id)
                            }
                        }
                    }
                }
            }

            let upcomingChores = viewModel.pendingChores.filter { !$0.isOverdue && !$0.isDueToday }
            if !upcomingChores.isEmpty {
                Section("Upcoming") {
                    ForEach(upcomingChores) { chore in
                        ChoreRow(chore: chore, onComplete: {
                            Task { await viewModel.markComplete(choreId: chore.id) }
                        })
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteChore(choreId: upcomingChores[index].id)
                            }
                        }
                    }
                }
            }

            if !viewModel.completedChores.isEmpty {
                Section("Completed") {
                    ForEach(viewModel.completedChores.prefix(10)) { chore in
                        ChoreRow(chore: chore, onComplete: nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct ChoreRow: View {
    let chore: Chore
    let onComplete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onComplete?()
            } label: {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(chore.isCompleted ? .green : (chore.isOverdue ? .red : .secondary))
            }
            .buttonStyle(.plain)
            .disabled(chore.isCompleted || onComplete == nil)

            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.headline)
                    .strikethrough(chore.isCompleted)
                    .foregroundStyle(chore.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let assigneeName = chore.assigneeName {
                        Label(assigneeName, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let dueDate = chore.dueDate {
                        Label(dueDate.relativeDisplay, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(chore.isOverdue ? .red : .secondary)
                    }

                    if let recurrence = chore.recurrenceDisplay {
                        Label(recurrence, systemImage: "repeat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let points = chore.points, points > 0 {
                        Label("\(points)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CreateChoreView: View {
    @ObservedObject var viewModel: ChoresViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var points: String = ""
    @State private var recurrence: String = "none"

    private let recurrenceOptions = ["none", "daily", "weekly", "monthly"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Chore title", text: $title)
                }

                Section {
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section {
                    Picker("Repeat", selection: $recurrence) {
                        Text("Never").tag("none")
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                }

                Section {
                    TextField("Points (optional)", text: $points)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.createChore(
                                title: title,
                                assigneeId: nil,
                                dueDate: hasDueDate ? dueDate : nil,
                                recurrence: recurrence == "none" ? nil : recurrence,
                                points: Int(points)
                            )
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ChoresView()
        .environmentObject(AuthenticationManager.shared)
}
