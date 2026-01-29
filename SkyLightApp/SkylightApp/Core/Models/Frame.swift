import Foundation

// MARK: - Simple Frame Model
struct Frame: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: String?
    let timezone: String?
    let isPlus: Bool
    let featureBundle: FeatureBundle?

    var displayTimezone: String {
        timezone ?? TimeZone.current.identifier
    }

    var hasChores: Bool {
        featureBundle?.chores?.enabled ?? false
    }

    var hasLists: Bool {
        featureBundle?.lists?.enabled ?? false
    }

    var hasRewards: Bool {
        featureBundle?.rewards?.enabled ?? false
    }
}

struct FeatureBundle: Codable, Equatable {
    let chores: FeatureFlag?
    let lists: FeatureFlag?
    let rewards: FeatureFlag?
    let calendar: FeatureFlag?
    let bundleName: String?

    enum CodingKeys: String, CodingKey {
        case chores
        case lists
        case rewards
        case calendar
        case bundleName = "bundle_name"
    }
}

struct FeatureFlag: Codable, Equatable {
    let enabled: Bool
    let unsupportedHardware: Bool?

    enum CodingKeys: String, CodingKey {
        case enabled
        case unsupportedHardware = "unsupported_hardware"
    }
}

// MARK: - JSON:API Frames Response
struct FramesResponse: Codable {
    let data: [FrameData]
    let included: [IncludedData]?

    var frames: [Frame] {
        data.map { frameData in
            Frame(
                id: frameData.id,
                name: frameData.attributes.name,
                type: frameData.type,
                timezone: frameData.attributes.timezone,
                isPlus: frameData.attributes.plus ?? false,
                featureBundle: frameData.attributes.featureBundle
            )
        }
    }
}

struct FrameData: Codable {
    let id: String
    let type: String
    let attributes: FrameAttributes
    let relationships: FrameRelationships?
}

struct FrameAttributes: Codable {
    let name: String
    let timezone: String?
    let plus: Bool?
    let apps: [String]?
    let featureBundle: FeatureBundle?
    let mine: Bool?
    let access: String?
    let sleepsAt: String?
    let wakesAt: String?
    let currentlySleeping: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case timezone
        case plus
        case apps
        case featureBundle = "feature_bundle"
        case mine
        case access
        case sleepsAt = "sleeps_at"
        case wakesAt = "wakes_at"
        case currentlySleeping = "currently_sleeping"
    }
}

struct FrameRelationships: Codable {
    let devices: RelationshipData?
}

struct RelationshipData: Codable {
    let data: [ResourceIdentifier]?
}

struct ResourceIdentifier: Codable {
    let id: String
    let type: String
}

struct IncludedData: Codable {
    let id: String
    let type: String
    let attributes: IncludedAttributes?
}

struct IncludedAttributes: Codable {
    let name: String?
    let activated: Bool?
    let timezone: String?
}

// MARK: - JSON:API Single Frame Response
struct FrameResponse: Codable {
    let data: FrameData

    var frame: Frame {
        Frame(
            id: data.id,
            name: data.attributes.name,
            type: data.type,
            timezone: data.attributes.timezone,
            isPlus: data.attributes.plus ?? false,
            featureBundle: data.attributes.featureBundle
        )
    }
}
