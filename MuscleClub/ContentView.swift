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

    #if DEBUG
    @State private var showDebugSignUp = false
    #endif

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
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            Button("Sign Up →") { showDebugSignUp = true }
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
                .padding(.top, 60)
                .padding(.trailing, 16)
        }
        .fullScreenCover(isPresented: $showDebugSignUp) {
            SignUpView(onComplete: { showDebugSignUp = false })
                .environment(appState)
        }
        #endif
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
