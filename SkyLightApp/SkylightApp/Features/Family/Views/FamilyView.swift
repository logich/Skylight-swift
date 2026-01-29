import SwiftUI

struct FamilyView: View {
    @StateObject private var viewModel = FamilyViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.members.isEmpty {
                    loadingView
                } else if viewModel.members.isEmpty && viewModel.devices.isEmpty {
                    emptyState
                } else {
                    contentList
                }
            }
            .navigationTitle("Family")
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading family...")
            Spacer()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Family Members", systemImage: "person.3")
        } description: {
            Text("Family members from your Skylight will appear here.")
        }
    }

    private var contentList: some View {
        List {
            if !viewModel.familyMembers.isEmpty {
                Section("Family Members") {
                    ForEach(viewModel.familyMembers) { member in
                        FamilyMemberRow(member: member)
                    }
                }
            }

            if !viewModel.devices.isEmpty {
                Section("Devices") {
                    ForEach(viewModel.devices) { device in
                        DeviceRow(device: device)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 16) {
            avatarView

            Text(member.name)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var avatarView: some View {
        Group {
            if let avatarUrl = member.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(member.displayColor.opacity(0.2))

            Text(member.initials)
                .font(.headline)
                .foregroundStyle(member.displayColor)
        }
    }
}

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: device.systemImage)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Circle()
                        .fill(device.isOnline ? Color.green : Color.red)
                        .frame(width: 8, height: 8)

                    Text(device.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let timezone = device.timezone {
                        Text(timezone)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FamilyView()
        .environmentObject(AuthenticationManager.shared)
}
