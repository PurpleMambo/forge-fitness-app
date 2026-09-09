import SwiftUI
import Playgrounds
import GoogleSignIn

@main struct MyApp: App {
    @State private var appState      = AppState()
    @State private var storeVM       = StoreVM()
    @State private var programService = ProgramService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(storeVM)
                .environment(programService)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) var appState
    @Environment(ProgramService.self) var programService

    var body: some View {
        Group {
            if !appState.sessionCheckComplete {
                AppBackground()
            } else if !appState.welcomeSeen {
                WelcomeView()
            } else if appState.onboardingComplete {
                MainTabView()
                    .task { await programService.loadAll() }
            } else {
                NewOnboardingFlowView()
            }
        }
        .preferredColorScheme(.dark)
        .task { await appState.checkSession() }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .environment(StoreVM())
        .environment(ProgramService())
}

#Playground {
    _ = 1 + 2
}
