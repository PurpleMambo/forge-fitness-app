import SwiftUI
import Playgrounds

@main struct MyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
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
                OnboardingView()
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
