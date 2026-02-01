import SwiftUI
import UserNotifications

@main
struct SkyLightApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()

        // Register notification categories
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            BackgroundTaskManager.shared.handleScenePhaseChange(to: newPhase)

            // Sync frame selection when app becomes active
            if newPhase == .active {
                syncFrameSelection()
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == SharedConstants.URLScheme.scheme else { return }

        if url.host == SharedConstants.URLScheme.eventHost,
           let eventId = url.pathComponents.dropFirst().first {
            DeepLinkManager.shared.handleEventDeepLink(eventId: eventId)
        }
    }

    // MARK: - Frame Sync

    private func syncFrameSelection() {
        SharedDataManager.shared.syncFrameSelection(
            frameId: authManager.currentFrameId,
            frameName: authManager.currentFrame?.name
        )
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case SharedConstants.Notifications.openEventActionId,
             UNNotificationDefaultActionIdentifier:
            // User tapped the notification or "View Event" action
            if let eventId = userInfo["eventId"] as? String {
                #if DEBUG
                print("NotificationDelegate: Opening event \(eventId)")
                #endif
                // Handle navigation to event
                // Could post notification or use app state
            }

        case SharedConstants.Notifications.startClimateActionId:
            // User tapped "Start Climate" action
            #if DEBUG
            print("NotificationDelegate: Starting Rivian climate control")
            #endif
            NotificationService.shared.startRivianClimate()

        case SharedConstants.Notifications.dismissActionId:
            // User dismissed the notification
            break

        default:
            break
        }

        completionHandler()
    }
}
