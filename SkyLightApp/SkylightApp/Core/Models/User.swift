import Foundation

// MARK: - JSON:API User Response
struct UserResponse: Codable {
    let data: UserData

    var user: User {
        User(
            id: data.id,
            email: data.attributes.email,
            name: data.attributes.profile?.name,
            phone: data.attributes.phone,
            subscriptionStatus: data.attributes.subscriptionStatus
        )
    }
}

struct UserData: Codable {
    let id: String
    let type: String
    let attributes: UserAttributes
}

struct UserAttributes: Codable {
    let email: String
    let phone: String?
    let subscriptionStatus: String?
    let profile: UserProfile?
    let agreedToMarketing: Bool?
    let notificationPreference: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case email
        case phone
        case subscriptionStatus = "subscription_status"
        case profile
        case agreedToMarketing = "agreed_to_marketing"
        case notificationPreference = "notification_preference"
        case createdAt = "created_at"
    }
}

struct UserProfile: Codable {
    let id: Int
    let name: String?
    let birthday: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case birthday
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Simple User Model
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let name: String?
    let phone: String?
    let subscriptionStatus: String?

    var displayName: String {
        name ?? email
    }

    var initials: String {
        if let name = name, !name.isEmpty {
            let components = name.split(separator: " ")
            if components.count >= 2 {
                let first = components[0].first.map(String.init) ?? ""
                let last = components[1].first.map(String.init) ?? ""
                return "\(first)\(last)".uppercased()
            }
            return String(name.prefix(2)).uppercased()
        }
        return String(email.prefix(2)).uppercased()
    }
}
