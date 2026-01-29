import Foundation
import SwiftUI

// MARK: - Simple FamilyMember Model
struct FamilyMember: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let color: String?
    let avatarUrl: String?
    let linkedToProfile: Bool

    var displayColor: Color {
        guard let colorHex = color else { return .gray }
        return Color(hex: colorHex) ?? .gray
    }

    var initials: String {
        String(name.prefix(1)).uppercased()
    }
}

// Note: FamilyMembersResponse is now handled by CategoriesResponse in FamilyService.swift
