import Foundation
import BackgroundTasks
import SwiftUI

/// Manages background task registration and execution for periodic data refresh
@MainActor
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private init() {}

    // MARK: - Registration

    /// Registers background tasks with the system
    /// Call this in the App's init or early in the app lifecycle
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: SharedConstants.BackgroundTasks.refreshTaskId,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        }

        #if DEBUG
        print("BackgroundTaskManager: Registered background refresh task")
        #endif
    }

    /// Schedules the next background refresh
    /// Call this when the app enters background
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: SharedConstants.BackgroundTasks.refreshTaskId)
        // Request refresh in at least 15 minutes (minimum allowed by iOS)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("BackgroundTaskManager: Scheduled background refresh")
            #endif
        } catch {
            #if DEBUG
            print("BackgroundTaskManager: Failed to schedule background refresh - \(error)")
            #endif
        }
    }

    /// Cancels any pending background refresh tasks
    func cancelBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: SharedConstants.BackgroundTasks.refreshTaskId)
        #if DEBUG
        print("BackgroundTaskManager: Cancelled background refresh")
        #endif
    }

    // MARK: - Task Handling

    /// Handles the background refresh task
    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        #if DEBUG
        print("BackgroundTaskManager: Starting background refresh")
        #endif

        // Schedule next refresh before we do anything else
        scheduleBackgroundRefresh()

        // Set up expiration handler
        task.expirationHandler = {
            #if DEBUG
            print("BackgroundTaskManager: Background task expired")
            #endif
        }

        // Check if we have the necessary data to refresh
        guard let frameId = SharedDataManager.shared.selectedFrameId else {
            #if DEBUG
            print("BackgroundTaskManager: No frame selected, completing task")
            #endif
            task.setTaskCompleted(success: true)
            return
        }

        // Perform the refresh
        do {
            try await performBackgroundRefresh(frameId: frameId)
            task.setTaskCompleted(success: true)
            #if DEBUG
            print("BackgroundTaskManager: Background refresh completed successfully")
            #endif
        } catch {
            #if DEBUG
            print("BackgroundTaskManager: Background refresh failed - \(error)")
            #endif
            task.setTaskCompleted(success: false)
        }
    }

    /// Performs the actual background data refresh
    private func performBackgroundRefresh(frameId: String) async throws {
        // Fetch updated events from API
        let calendarService = CalendarService()
        let timezone = TimeZone.current.identifier

        // Fetch next 7 days of events
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        let events = try await calendarService.getEvents(
            frameId: frameId,
            from: startDate,
            to: endDate,
            timezone: timezone
        )

        #if DEBUG
        print("BackgroundTaskManager: Fetched \(events.count) events")
        #endif

        // Process events to update drive times and notifications
        await DriveTimeManager.shared.processEvents(events)
    }
}

// MARK: - App Lifecycle Integration

extension BackgroundTaskManager {
    /// Sets up scene phase observers for background task scheduling
    /// Call this when the app's scene phase changes
    func handleScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .background:
            scheduleBackgroundRefresh()
        case .active:
            // Could cancel and reschedule or do immediate refresh
            break
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension BackgroundTaskManager {
    /// Simulates a background refresh for testing
    func simulateBackgroundRefresh() async {
        guard let frameId = SharedDataManager.shared.selectedFrameId else {
            print("BackgroundTaskManager: Cannot simulate - no frame selected")
            return
        }

        print("BackgroundTaskManager: Simulating background refresh")
        do {
            try await performBackgroundRefresh(frameId: frameId)
            print("BackgroundTaskManager: Simulation completed successfully")
        } catch {
            print("BackgroundTaskManager: Simulation failed - \(error)")
        }
    }
}
#endif
