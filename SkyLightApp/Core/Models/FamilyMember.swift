import Foundation

struct FamilyMember: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let email: String?
    let role: String?
    let avatarUrl: String?
    let rewardPoints: Int?
    let isAdmin: Bool?
    let joinedAt: Date?

    var roleType: Role {
        guard let role = role else { return .other }
        return Role(rawValue: role.lowercased()) ?? .other
    }

    enum Role: String, Codable, CaseIterable {
        case parent
        case child
        case other

        var displayName: String {
            rawValue.capitalized
        }
    }

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].first.map(String.init) ?? ""
            let last = components[1].first.map(String.init) ?? ""
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct FamilyMembersResponse: Codable {
    let members: [FamilyMember]
}
