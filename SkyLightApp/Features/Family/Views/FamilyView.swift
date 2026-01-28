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
            if !viewModel.parents.isEmpty {
                Section("Parents") {
                    ForEach(viewModel.parents) { member in
                        FamilyMemberRow(member: member)
                    }
                }
            }

            if !viewModel.children.isEmpty {
                Section("Children") {
                    ForEach(viewModel.children) { member in
                        FamilyMemberRow(member: member)
                    }
                }
            }

            if !viewModel.others.isEmpty {
                Section("Others") {
                    ForEach(viewModel.others) { member in
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.headline)

                    if member.isAdmin == true {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if let email = member.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let points = member.rewardPoints, points > 0 {
                    Label("\(points) points", systemImage: "star.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

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
                .fill(Color.blue.opacity(0.2))

            Text(member.initials)
                .font(.headline)
                .foregroundStyle(.blue)
        }
    }
}

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: device.deviceType.systemImage)
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
                        .fill(device.deviceStatus.isOnline ? Color.green : Color.red)
                        .frame(width: 8, height: 8)

                    Text(device.deviceStatus.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let version = device.firmwareVersion {
                        Text("v\(version)")
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
