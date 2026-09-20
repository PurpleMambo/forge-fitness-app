import SwiftUI
import Playgrounds
import GoogleSignIn
import Supabase

@main struct MyApp: App {
    @State private var appState       = AppState()
    @State private var storeVM        = StoreVM()
    @State private var programService = ProgramService()
    @State private var streakService  = StreakService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(storeVM)
                .environment(programService)
                .environment(streakService)
        }
    }
}

// DEBUG — flip to true to land directly on a specific screen. Set back to false before shipping.
private let debugShowRankView   = false
private let debugShowPaywall    = false
private let debugShowDashboard  = false   // ← flip to false before shipping

// Signs out and clears welcomeSeen/onboardingComplete at launch so the full
// Welcome → onboarding → sign-up flow can be tested end to end.
// Only takes effect in Debug builds (#if DEBUG at the call site).
private let debugResetOnboarding = false

struct RootView: View {
    @Environment(AppState.self) var appState
    @Environment(ProgramService.self) var programService
    @Environment(StreakService.self) var streakService

    var body: some View {
        Group {
            if debugShowDashboard {
                MainTabView()
                    .task {
                        await programService.loadForDebug()
                        #if DEBUG
                        streakService.loadMockData(
                            workoutDayNames: Set(programService.templates.map(\.dayOfWeek))
                        )
                        #endif
                    }
            } else if debugShowPaywall {
                MuscleClubPaywallView(
                    onDismiss: {},
                    onboardingName: "Gísli",
                    onboardingGoal: "Build more muscle",
                    onboardingCurrentWeight: "80 kg",
                    onboardingGoalWeight: "88 kg",
                    goalSpeed: "Balanced"
                )
            } else if debugShowRankView {
                RankView()
            } else if !appState.sessionCheckComplete {
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
        .task {
            #if DEBUG
            if debugResetOnboarding {
                try? await supabase.auth.signOut()
                appState.welcomeSeen = false
                appState.onboardingComplete = false
            }
            #endif
            await appState.checkSession()
        }
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
        .environment(StreakService())
}

#Playground {
    _ = 1 + 2
}
