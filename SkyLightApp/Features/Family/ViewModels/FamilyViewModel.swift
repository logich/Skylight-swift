import Foundation

@MainActor
final class FamilyViewModel: ObservableObject {
    @Published var members: [FamilyMember] = []
    @Published var devices: [Device] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false

    private let familyService: FamilyServiceProtocol
    private let authManager: AuthenticationManager

    var parents: [FamilyMember] {
        members.filter { $0.roleType == .parent }
    }

    var children: [FamilyMember] {
        members.filter { $0.roleType == .child }
    }

    var others: [FamilyMember] {
        members.filter { $0.roleType == .other }
    }

    init(
        familyService: FamilyServiceProtocol = FamilyService(),
        authManager: AuthenticationManager = .shared
    ) {
        self.familyService = familyService
        self.authManager = authManager
    }

    func loadData() async {
        guard let frameId = authManager.currentFrameId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            async let membersTask = familyService.getFamilyMembers(frameId: frameId)
            async let devicesTask = familyService.getDevices(frameId: frameId)

            let (fetchedMembers, fetchedDevices) = try await (membersTask, devicesTask)
            members = fetchedMembers
            devices = fetchedDevices
        } catch {
            self.error = error
            self.showError = true
        }
    }
}
