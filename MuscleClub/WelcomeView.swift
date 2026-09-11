import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) var appState
    @State private var showLogin = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 64, weight: .heavy))
                        .foregroundColor(.appAccent)

                    Text("MUSCLE CLUB")
                        .font(.system(size: 52, weight: .heavy))
                        .tracking(5)

                    Text("Build the body you want.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 20) {
                    Button("Let's Get Started") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.welcomeSeen = true
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 17, weight: .bold))

                    Button("Already have an account?") {
                        showLogin = true
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 56)
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView(onComplete: { showLogin = false })
                .environment(appState)
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
