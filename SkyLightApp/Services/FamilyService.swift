import Foundation

protocol FamilyServiceProtocol {
    func getFamilyMembers(frameId: String) async throws -> [FamilyMember]
    func getDevices(frameId: String) async throws -> [Device]
}

final class FamilyService: FamilyServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getFamilyMembers(frameId: String) async throws -> [FamilyMember] {
        let endpoint = SkylightEndpoint.getFamilyMembers(frameId: frameId)
        let response: FamilyMembersResponse = try await apiClient.request(endpoint)
        return response.members
    }

    func getDevices(frameId: String) async throws -> [Device] {
        let endpoint = SkylightEndpoint.getDevices(frameId: frameId)
        let response: DevicesResponse = try await apiClient.request(endpoint)
        return response.devices
    }
}
