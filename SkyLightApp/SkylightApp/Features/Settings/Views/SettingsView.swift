import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showLogoutConfirmation = false

    // Drive time settings
    @State private var driveTimeAlertsEnabled = SharedDataManager.shared.driveTimeAlertsEnabled
    @State private var bufferTimeMinutes = SharedDataManager.shared.bufferTimeMinutes
    @State private var isRequestingNotificationPermission = false

    var body: some View {
        NavigationStack {
            List {
                timeToLeaveSection

                Section {
                    if let frame = authManager.currentFrame {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(frame.name)
                                    .font(.headline)

                                if let timezone = frame.timezone {
                                    Text(timezone)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        authManager.clearFrameSelection()
                    } label: {
                        Label("Switch Household", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Current Household")
                }

                Section {
                    if let user = authManager.currentUser {
                        HStack {
                            Text("Signed in as")
                            Spacer()
                            Text(user.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Account")
                }

                Section {
                    Link(destination: URL(string: "https://ourskylight.com")!) {
                        Label("Skylight Website", systemImage: "globe")
                    }

                    Link(destination: URL(string: "https://skylight.helpjuice.com")!) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("Resources")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.buildNumber)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("This is an unofficial app using a reverse-engineered API. Not affiliated with Skylight.")
                        .font(.caption)
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .confirmationDialog(
                "Sign Out",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                // Sync state with shared data
                driveTimeAlertsEnabled = SharedDataManager.shared.driveTimeAlertsEnabled
                bufferTimeMinutes = SharedDataManager.shared.bufferTimeMinutes
            }
        }
    }

    // MARK: - Time to Leave Section

    private var timeToLeaveSection: some View {
        Section {
            Toggle(isOn: $driveTimeAlertsEnabled) {
                Label {
                    Text("Drive Time Alerts")
                } icon: {
                    Image(systemName: "car.fill")
                        .foregroundStyle(.blue)
                }
            }
            .disabled(isRequestingNotificationPermission)
            .onChange(of: driveTimeAlertsEnabled) { oldValue, newValue in
                Task {
                    await handleDriveTimeAlertsToggle(enabled: newValue)
                }
            }

            if driveTimeAlertsEnabled {
                Picker(selection: $bufferTimeMinutes) {
                    ForEach(SharedConstants.Defaults.bufferTimeOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                } label: {
                    Label {
                        Text("Buffer Time")
                    } icon: {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundStyle(.orange)
                    }
                }
                .onChange(of: bufferTimeMinutes) { oldValue, newValue in
                    Task {
                        await DriveTimeManager.shared.updateBufferTime(newValue)
                    }
                }
            }
        } header: {
            Text("Time to Leave")
        } footer: {
            Text("Get notified when it's time to leave for events with locations. Buffer time adds extra minutes before the calculated leave time.")
        }
    }

    // MARK: - Actions

    private func handleDriveTimeAlertsToggle(enabled: Bool) async {
        if enabled {
            isRequestingNotificationPermission = true
            defer { isRequestingNotificationPermission = false }

            let authorized = await DriveTimeManager.shared.enableDriveTimeAlerts()
            if !authorized {
                // Reset toggle if permission was denied
                driveTimeAlertsEnabled = false
            }
        } else {
            await DriveTimeManager.shared.disableDriveTimeAlerts()
        }
    }
}

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager.shared)
}
