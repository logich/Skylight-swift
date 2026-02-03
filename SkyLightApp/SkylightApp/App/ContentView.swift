import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        Group {
            switch authManager.authState {
            case .unauthenticated:
                LoginView()
            case .authenticated:
                FrameSelectionView()
            case .frameSelected:
                CalendarView()
            }
        }
        .animation(.default, value: authManager.authState)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
}
