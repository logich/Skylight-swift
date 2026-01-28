import Foundation

struct Device: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: String?
    let status: String?
    let lastSeenAt: Date?
    let firmwareVersion: String?

    var deviceType: DeviceType {
        guard let type = type else { return .unknown }
        return DeviceType(rawValue: type.lowercased()) ?? .unknown
    }

    var deviceStatus: DeviceStatus {
        guard let status = status else { return .unknown }
        return DeviceStatus(rawValue: status.lowercased()) ?? .unknown
    }

    enum DeviceType: String, Codable {
        case calendar
        case frame
        case unknown

        var displayName: String {
            switch self {
            case .calendar: return "Calendar"
            case .frame: return "Frame"
            case .unknown: return "Device"
            }
        }

        var systemImage: String {
            switch self {
            case .calendar: return "calendar"
            case .frame: return "photo.artframe"
            case .unknown: return "desktopcomputer"
            }
        }
    }

    enum DeviceStatus: String, Codable {
        case online
        case offline
        case unknown

        var isOnline: Bool {
            self == .online
        }
    }
}

struct DevicesResponse: Codable {
    let devices: [Device]
}
