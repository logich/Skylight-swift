import Foundation

struct LoginResponse: Codable {
    let userId: String
    let token: String
    let refreshToken: String?
    let expiresIn: Int?
    let user: User?
}

struct RefreshTokenResponse: Codable {
    let token: String
    let expiresIn: Int?
}
