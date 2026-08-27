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

    // ── DEBUG: flip to false when done testing the paywall ──
    #if DEBUG
    @State private var debugPaywall = true
    #endif

    var body: some View {
        Group {
            #if DEBUG
            if debugPaywall {
                MuscleClubPaywallView { debugPaywall = false; appState.onboardingComplete = true }
            } else {
                routing
            }
            #else
            routing
            #endif
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var routing: some View {
        if !appState.welcomeSeen {
            WelcomeView()
        } else if appState.onboardingComplete {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
}

#Playground {
    _ = 1 + 2
}
