import SwiftUI

struct RootGateView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)
            } else if appState.hasRegistered {
                LoginView()
                    .environmentObject(appState)
            } else {
                StartAuthView()
                    .environmentObject(appState)
            }
        }
    }
}
