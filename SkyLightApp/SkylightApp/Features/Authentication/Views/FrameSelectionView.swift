import SwiftUI

struct FrameSelectionView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            Group {
                if authManager.availableFrames.isEmpty {
                    emptyState
                } else {
                    frameList
                }
            }
            .navigationTitle("Select Household")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authManager.logout()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private var frameList: some View {
        List(authManager.availableFrames) { frame in
            Button {
                authManager.selectFrame(frame)
            } label: {
                FrameRow(frame: frame)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Households Found", systemImage: "house.slash")
        } description: {
            Text("We couldn't find any Skylight devices associated with your account.")
        } actions: {
            Button("Try Again") {
                Task {
                    try? await authManager.refreshTokenIfNeeded()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

struct FrameRow: View {
    let frame: Frame

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(frame.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    if let timezone = frame.timezone {
                        Label(timezoneAbbreviation(from: timezone), systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private func timezoneAbbreviation(from identifier: String) -> String {
        TimeZone(identifier: identifier)?.abbreviation() ?? identifier
    }
}

#Preview {
    FrameSelectionView()
        .environmentObject(AuthenticationManager.shared)
}
