import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
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
