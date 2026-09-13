import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) var appState
    @Environment(ProgramService.self) var programService
    @Environment(\.colorScheme) private var colorScheme
    @State private var showLogin = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppBackground()

            // Photo layer — scaledToFill at 70 % screen height, right-anchored so
            // the left background is what gets cropped, keeping the person prominent.
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Image("gillz_light")
                        .resizable()
                        .scaledToFill()
                        // 1. Constrain only height — image expands horizontally at its aspect ratio
                        .frame(height: geo.size.height * 0.70)
                        // 2. Clip to screen width, trailing-aligned → left side crops
                        .frame(width: geo.size.width, alignment: .trailing)
                        .clipped()
                        // Subtle top vignette so status-bar area reads cleanly
                        .overlay(alignment: .top) {
                            LinearGradient(
                                colors: [.black.opacity(colorScheme == .dark ? 0.30 : 0.10), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 130)
                        }
                        // Mask fades the bottom of the photo to transparent so the
                        // AppBackground bleeds through seamlessly in any colour scheme
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .white,               location: 0),
                                    .init(color: .white,               location: 0.50),
                                    .init(color: .white.opacity(0.35), location: 0.82),
                                    .init(color: .clear,               location: 1.0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .top)

            // Content — anchored to bottom, overlapping the image fade zone
            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 24) {
                    // Branding badge
                    HStack(spacing: 7) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.appAccent)
                        Text("MUSCLE CLUB")
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.tint(.appAccent))

                    // Headline
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BUILD THE\nBODY YOU\nWANT.")
                            .font(.system(size: 46, weight: .heavy))
                            .tracking(1)
                            .lineSpacing(3)

                        Text("Your personal strength program,\nbuilt to get you results.")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }

                    // CTAs
                    VStack(spacing: 18) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.welcomeSeen = true
                            }
                        } label: {
                            Text("Let's Get Started")
                                .font(.system(size: 19, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.appAccent)

                        Button("Already have an account?") {
                            showLogin = true
                        }
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 56)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 32)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.65).delay(0.15)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView(onComplete: { showLogin = false })
                .environment(appState)
                .environment(programService)
        }
    }
}

#Preview("Dark") {
    WelcomeView()
        .environment(AppState())
        .environment(ProgramService())
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    WelcomeView()
        .environment(AppState())
        .environment(ProgramService())
        .preferredColorScheme(.light)
}
