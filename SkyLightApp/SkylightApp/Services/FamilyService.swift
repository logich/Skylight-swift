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
        // Family members are retrieved via frame categories
        let endpoint = SkylightEndpoint.getFrameCategories(frameId: frameId)
        let response: CategoriesResponse = try await apiClient.request(endpoint)
        // Return categories that are linked to profiles (these are family members)
        return response.familyMembers
    }

    func getDevices(frameId: String) async throws -> [Device] {
        let endpoint = SkylightEndpoint.getDevices(frameId: frameId)
        let response: DevicesResponse = try await apiClient.request(endpoint)
        return response.devices
    }
}

// MARK: - JSON:API Categories Response
struct CategoriesResponse: Codable {
    let data: [CategoryData]

    var familyMembers: [FamilyMember] {
        data.compactMap { categoryData -> FamilyMember? in
            // Only include categories linked to profiles (family members)
            guard categoryData.attributes.linkedToProfile == true else { return nil }
            return FamilyMember(
                id: categoryData.id,
                name: categoryData.attributes.label,
                color: categoryData.attributes.color,
                avatarUrl: categoryData.attributes.profilePicUrl,
                linkedToProfile: true
            )
        }
    }
}

struct CategoryData: Codable {
    let id: String
    let type: String
    let attributes: CategoryAttributes
}

struct CategoryAttributes: Codable {
    let label: String
    let color: String?
    let linkedToProfile: Bool?
    let profilePicUrl: String?
}
