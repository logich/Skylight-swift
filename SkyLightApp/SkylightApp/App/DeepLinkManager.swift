import SwiftUI
import Combine

@MainActor
final class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published var pendingEventId: String?

    private init() {}

    func handleEventDeepLink(eventId: String) {
        pendingEventId = eventId
    }

    func clearPendingEvent() {
        pendingEventId = nil
    }
}
