import Foundation

// MARK: - JSON:API Login Response
struct LoginResponse: Codable {
    let data: AuthenticatedUserData
    let meta: LoginMeta?

    var userId: String { data.id }
    var token: String { data.attributes.token }
    var email: String { data.attributes.email }
}

struct AuthenticatedUserData: Codable {
    let id: String
    let type: String
    let attributes: AuthenticatedUserAttributes
}

struct AuthenticatedUserAttributes: Codable {
    let email: String
    let token: String
    let subscriptionStatus: String?

    enum CodingKeys: String, CodingKey {
        case email
        case token
        case subscriptionStatus = "subscription_status"
    }
}

struct LoginMeta: Codable {
    let passwordReset: Bool?

    enum CodingKeys: String, CodingKey {
        case passwordReset = "password_reset"
    }
}
