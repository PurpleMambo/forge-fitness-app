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

            // Photo layer — scaledToFill at 70 % screen height.
            // Adjust imagePanX to pan left/right:
            //   positive → image shifts right (person appears further right on screen)
            //   negative → image shifts left  (person appears further left on screen)
            GeometryReader { geo in
                let imagePanX: CGFloat = -150
                VStack(spacing: 0) {
                    ZStack {
                        Image("gillz_light")
                            .resizable()
                            .scaledToFill()
                            .frame(height: geo.size.height * 0.70)
                            .offset(x: imagePanX)
                    }
                    .frame(width: geo.size.width, height: geo.size.height * 0.70)
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
//                    // Branding badge
//                    HStack(spacing: 7) {
//                        Image(systemName: "bolt.fill")
//                            .font(.system(size: 12, weight: .bold))
//                            .foregroundStyle(Color.appAccent)
//                        Text("MUSCLE CLUB")
//                            .font(.system(size: 12, weight: .heavy))
//                            .tracking(3)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 10)
//                    .glassEffect(.regular.tint(.appAccent))

                    // Headline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BUILD THE\nBODY YOU\nWANT.")
                            .font(.system(size: 58, weight: .black))
                            .italic()
                            .tracking(-0.5)
                            .lineSpacing(0)
                            .foregroundStyle(.black)

                        Text("YOUR PERSONAL STRENGTH PROGRAM,\nBUILT TO GET YOU RESULTS.")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(.black.opacity(0.5))
                            .lineSpacing(3)
                    }

                    // CTAs
                    VStack(spacing: 18) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.welcomeSeen = true
                            }
                        } label: {
                            Text("Let's Get Started")
                                .font(.system(size: 19, weight: .black))
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
