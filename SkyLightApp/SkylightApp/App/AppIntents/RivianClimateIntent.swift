import AppIntents
import Foundation
import UIKit
import Intents

// MARK: - Start Rivian Climate Intent

struct StartRivianClimateIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Rivian Climate Control"
    static var description = IntentDescription("Starts the climate control for your Rivian vehicle. This can be triggered manually or automatically before calendar events.")

    @Parameter(title: "Vehicle Model", default: "R1S")
    var vehicleModel: String

    static var parameterSummary: some ParameterSummary {
        Summary("Start climate for \(\.$vehicleModel)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        #if DEBUG
        print("RivianClimateIntent: Starting climate control for \(vehicleModel)")
        #endif

        // Call Rivian's "Start climate control" intent via Shortcuts URL scheme
        // The Rivian app exposes this intent in Shortcuts and accepts vehicle name
        let intentName = "Start climate control"

        // Create URL to run the Rivian intent with the vehicle parameter
        // Format: shortcuts://x-callback-url/run-shortcut?name=Start%20climate%20control&input=text&text=R1S
        let urlString = "shortcuts://x-callback-url/run-shortcut?name=\(intentName)&input=text&text=\(vehicleModel)"

        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURL) else {
            throw RivianClimateError.invalidURL
        }

        #if DEBUG
        print("RivianClimateIntent: Calling Rivian intent via URL: \(url.absoluteString)")
        #endif

        // Open the URL to trigger Rivian's intent
        await UIApplication.shared.open(url)

        return .result(
            dialog: IntentDialog("Starting climate control for your \(vehicleModel)")
        )
    }
}

// MARK: - Auto Start Climate Intent (for notifications)

struct AutoStartRivianClimateIntent: AppIntent {
    static var title: LocalizedStringResource = "Auto Start Rivian Climate"
    static var description = IntentDescription("Automatically starts climate control when it's time to leave for an event.")

    static var openAppWhenRun: Bool = false // Don't require opening the app

    @Parameter(title: "Event Title")
    var eventTitle: String

    @Parameter(title: "Vehicle Model", default: "R1S")
    var vehicleModel: String

    func perform() async throws -> some IntentResult {
        #if DEBUG
        print("AutoStartRivianClimateIntent: Auto-starting climate for event '\(eventTitle)'")
        #endif

        // Trigger the main climate control intent
        let climateIntent = StartRivianClimateIntent()
        climateIntent.vehicleModel = vehicleModel

        do {
            _ = try await climateIntent.perform()

            #if DEBUG
            print("AutoStartRivianClimateIntent: Successfully triggered climate control")
            #endif

            return .result()
        } catch {
            #if DEBUG
            print("AutoStartRivianClimateIntent: Failed to start climate - \(error)")
            #endif
            throw error
        }
    }
}

// MARK: - Errors

enum RivianClimateError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case invalidURL
    case rivianAppNotInstalled
    case rivianIntentNotSupported

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidURL:
            return "Failed to create Rivian URL"
        case .rivianAppNotInstalled:
            return "Rivian app not installed or doesn't support deep linking"
        case .rivianIntentNotSupported:
            return "Rivian app doesn't support climate control intents"
        }
    }
}

// MARK: - App Shortcuts

extension SkylightShortcuts {
    static var climateShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: StartRivianClimateIntent(),
                phrases: [
                    "Start my Rivian climate",
                    "Warm up my \(.applicationName) Rivian",
                    "Start climate control in \(.applicationName)"
                ],
                shortTitle: "Start Climate",
                systemImageName: "car.fill"
            )
        ]
    }
}
