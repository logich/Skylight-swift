import Foundation

@MainActor
final class ChoresViewModel: ObservableObject {
    @Published var chores: [Chore] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false
    @Published var showCreateSheet: Bool = false
    @Published var filterAssignee: String?

    private let choresService: ChoresServiceProtocol
    private let authManager: AuthenticationManager

    var pendingChores: [Chore] {
        chores.filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var completedChores: [Chore] {
        chores.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var overdueChores: [Chore] {
        pendingChores.filter { $0.isOverdue }
    }

    var todayChores: [Chore] {
        pendingChores.filter { $0.isDueToday }
    }

    init(
        choresService: ChoresServiceProtocol = ChoresService(),
        authManager: AuthenticationManager = .shared
    ) {
        self.choresService = choresService
        self.authManager = authManager
    }

    func loadChores() async {
        guard let frameId = authManager.currentFrameId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            chores = try await choresService.getChores(frameId: frameId)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func createChore(title: String, assigneeId: String?, dueDate: Date?, recurrence: String?, points: Int?) async {
        guard let frameId = authManager.currentFrameId else { return }

        isLoading = true
        defer { isLoading = false }

        let request = CreateChoreRequest(
            title: title,
            assigneeId: assigneeId,
            dueDate: dueDate,
            recurrence: recurrence,
            points: points
        )

        do {
            let newChore = try await choresService.createChore(frameId: frameId, chore: request)
            chores.append(newChore)
            showCreateSheet = false
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func markComplete(choreId: String) async {
        guard let frameId = authManager.currentFrameId else { return }

        do {
            let updatedChore = try await choresService.completeChore(frameId: frameId, choreId: choreId)
            if let index = chores.firstIndex(where: { $0.id == choreId }) {
                chores[index] = updatedChore
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func deleteChore(choreId: String) async {
        guard let frameId = authManager.currentFrameId else { return }

        do {
            try await choresService.deleteChore(frameId: frameId, choreId: choreId)
            chores.removeAll { $0.id == choreId }
        } catch {
            self.error = error
            self.showError = true
        }
    }
}
