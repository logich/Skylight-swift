import Foundation

// MARK: - Simple Device Model
struct Device: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let timezone: String?
    let activated: Bool
    let brightness: Int?
    let sleepsAt: String?
    let wakesAt: String?
    let currentlySleeping: Bool?
    let sleepModeOn: Bool?

    var isOnline: Bool {
        activated
    }

    var systemImage: String {
        "desktopcomputer"
    }
}

// MARK: - JSON:API Devices Response
struct DevicesResponse: Codable {
    let data: [DeviceData]

    var devices: [Device] {
        data.map { deviceData in
            Device(
                id: deviceData.id,
                name: deviceData.attributes.name,
                timezone: deviceData.attributes.timezone,
                activated: deviceData.attributes.activated ?? false,
                brightness: deviceData.attributes.brightness,
                sleepsAt: deviceData.attributes.sleepsAt,
                wakesAt: deviceData.attributes.wakesAt,
                currentlySleeping: deviceData.attributes.currentlySleeping,
                sleepModeOn: deviceData.attributes.sleepModeOn
            )
        }
    }
}

struct DeviceData: Codable {
    let id: String
    let type: String
    let attributes: DeviceAttributes
}

struct DeviceAttributes: Codable {
    let name: String
    let brightness: Int?
    let slideshowSpeed: Int?
    let sleepsAt: String?
    let wakesAt: String?
    let currentlySleeping: Bool?
    let timezone: String?
    let sleepModeOn: Bool?
    let activated: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case brightness
        case slideshowSpeed = "slideshow_speed"
        case sleepsAt = "sleeps_at"
        case wakesAt = "wakes_at"
        case currentlySleeping = "currently_sleeping"
        case timezone
        case sleepModeOn = "sleep_mode_on"
        case activated
    }
}
