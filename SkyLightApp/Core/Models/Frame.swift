import Foundation

struct Frame: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: String?
    let timezone: String?
    let createdAt: Date?
    let updatedAt: Date?

    var displayTimezone: String {
        timezone ?? TimeZone.current.identifier
    }
}

struct FramesResponse: Codable {
    let frames: [Frame]
}

struct FrameResponse: Codable {
    let frame: Frame
}
