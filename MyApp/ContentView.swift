import SwiftUI
import Playgrounds

@main struct MyApp: App {
    @State private var appState = AppState()
    @State private var storeVM = StoreVM()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(storeVM)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        Group {
            if !appState.welcomeSeen {
                WelcomeView()
            } else if appState.onboardingComplete {
                MainTabView()
            } else {
                NewOnboardingFlowView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
        .environment(AppState())
}

#Playground {
    _ = 1 + 2
}
