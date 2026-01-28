import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let name: String?

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
