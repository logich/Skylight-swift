import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab: Tab = .calendar

    enum Tab: String, CaseIterable {
        case calendar = "Calendar"
        case chores = "Chores"
        case lists = "Lists"
        case family = "Family"
        case settings = "Settings"

        var systemImage: String {
            switch self {
            case .calendar: return "calendar"
            case .chores: return "checkmark.circle"
            case .lists: return "list.bullet"
            case .family: return "person.3"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label(Tab.calendar.rawValue, systemImage: Tab.calendar.systemImage)
                }
                .tag(Tab.calendar)

            ChoresView()
                .tabItem {
                    Label(Tab.chores.rawValue, systemImage: Tab.chores.systemImage)
                }
                .tag(Tab.chores)

            ListsView()
                .tabItem {
                    Label(Tab.lists.rawValue, systemImage: Tab.lists.systemImage)
                }
                .tag(Tab.lists)

            FamilyView()
                .tabItem {
                    Label(Tab.family.rawValue, systemImage: Tab.family.systemImage)
                }
                .tag(Tab.family)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager.shared)
}
