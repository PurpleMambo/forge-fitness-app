import SwiftUI
import UIKit
import DotLottie

/// Press-and-hold commitment screen. The screen bleeds crimson as the user
/// charges the ring; at full charge a celebration plays, then the paywall appears.
struct NewOnboardingFlow_CommitStepView: View {
    let onCommitted: () -> Void

    @State private var holdProgress: Double = 0
    @State private var isHolding = false
    @State private var committed = false
    @State private var showCelebration = false
    @State private var celebrationVisible = false
    @State private var holdTask: Task<Void, Never>? = nil
    @State private var showPaywall = false
    @State private var figureScale: CGFloat = 1.0
    @StateObject private var confettiLottie = DotLottieAnimation(
        fileName: "confetti(2)",
        config: AnimationConfig(autoplay: false, loop: false, speed: 1.0)
    )

    private let hapticLight   = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium  = UIImpactFeedbackGenerator(style: .medium)
    private let hapticHeavy   = UIImpactFeedbackGenerator(style: .heavy)
    private let hapticSuccess = UINotificationFeedbackGenerator()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if showCelebration {
                    celebrationView.transition(.opacity)
                } else {
                    commitView(geo: geo).transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showCelebration)
        }
        .ignoresSafeArea()
        .onDisappear { holdTask?.cancel() }
        .fullScreenCover(isPresented: $showPaywall) {
            MuscleClubPaywallView(onDismiss: { onCommitted() })
        }
    }

    // MARK: - Commit view

    private func commitView(geo: GeometryProxy) -> some View {
        ZStack {
            AppBackground()

            // Crimson bleed as ring charges
            Color.appAccent
                .opacity(holdProgress * 0.75)
                .ignoresSafeArea()
                .animation(.linear(duration: 0.05), value: holdProgress)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    // Commitment statement
                    VStack(spacing: 12) {
                        Text("I commit to")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        VStack(spacing: 10) {
                            Text("building my")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            Text("strongest self")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20).padding(.vertical, 7)
                                .background(
                                    Capsule().fill(Color.appAccent.opacity(0.9))
                                )
                            Text("starting today")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)

                    // Animated figure
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                        .scaleEffect(figureScale)
                        .animation(.easeInOut(duration: 0.12), value: figureScale)
                }

                Spacer()

                // Hold button area
                VStack(spacing: 20) {
                    Text(isHolding ? "Charging up…" : "Press and hold to commit")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)

                    holdButton
                }
                .padding(.bottom, geo.safeAreaInsets.bottom + 56)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Hold button

    private var holdButton: some View {
        ZStack {
            // Decorative sparkles
            Image(systemName: "sparkle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
                .offset(x: -76, y: 8)
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
                .offset(x: 18, y: -68)

            Circle()
                .frame(width: 90, height: 90)
                .glassEffect(.regular.tint(.white.opacity(0.2)), in: .circle)

            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(.white, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                .frame(width: 74, height: 74)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: holdProgress)

            Image(systemName: "touchid")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.white)
                .scaleEffect(isHolding ? 0.88 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: isHolding)
        }
        .scaleEffect(isHolding ? 0.93 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isHolding)
        .onLongPressGesture(
            minimumDuration: .infinity,
            pressing: { pressing in
                isHolding = pressing
                if pressing { startHolding() } else { cancelHolding() }
            },
            perform: {}
        )
    }

    // MARK: - Celebration view

    private var celebrationView: some View {
        ZStack {
            Color.appAccent.ignoresSafeArea()

            confettiLottie.view()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 100, weight: .light))
                    .foregroundStyle(.white)
                    .scaleEffect(celebrationVisible ? 1.0 : 0.4)
                    .animation(.spring(response: 0.55, dampingFraction: 0.65), value: celebrationVisible)

                Spacer()

                Text("Let's build it!\nTime to get strong.")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32).padding(.vertical, 26)
                    .frame(maxWidth: .infinity)
                    .glassEffect(.regular.tint(.white.opacity(0.18)), in: .rect(cornerRadius: 30))
                    .padding(.horizontal, 22).padding(.bottom, 80)
                    .opacity(celebrationVisible ? 1 : 0)
                    .offset(y: celebrationVisible ? 0 : 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.78), value: celebrationVisible)
            }
        }
        .onAppear { _ = confettiLottie.play() }
    }

    // MARK: - Hold logic

    private func startHolding() {
        hapticLight.prepare()
        hapticMedium.prepare()
        hapticHeavy.prepare()
        figureScale = 1.05

        holdTask = Task {
            var tick = 0
            let totalTicks = 50
            while !Task.isCancelled, tick <= totalTicks {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled else { break }
                tick += 1
                let p = min(Double(tick) / Double(totalTicks), 1.0)
                await MainActor.run {
                    holdProgress = p
                    figureScale = 1.0 + p * 0.25
                    fireHaptic(progress: p, tick: tick)
                    if p >= 1.0, !committed { committed = true; completeCommit() }
                }
                if p >= 1.0 { break }
            }
        }
    }

    private func cancelHolding() {
        holdTask?.cancel()
        figureScale = 1.0
        guard !committed else { holdTask = nil; return }
        holdTask = Task {
            while !Task.isCancelled {
                let reachedZero = await MainActor.run { () -> Bool in
                    holdProgress = max(0, holdProgress - 0.04)
                    return holdProgress <= 0
                }
                if reachedZero { break }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func fireHaptic(progress: Double, tick: Int) {
        if progress < 0.33 {
            if tick % 5 == 0 { hapticLight.impactOccurred(intensity: 0.25 + progress * 2.0) }
        } else if progress < 0.67 {
            if tick % 3 == 0 { hapticMedium.impactOccurred(intensity: 0.4 + progress * 0.9) }
        } else {
            hapticHeavy.impactOccurred(intensity: 0.55 + progress * 0.45)
        }
    }

    private func completeCommit() {
        holdTask?.cancel()
        hapticSuccess.notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.55)) { showCelebration = true }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            await MainActor.run {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    celebrationVisible = true
                }
            }
            try? await Task.sleep(for: .seconds(1.8))
            await MainActor.run { showPaywall = true }
        }
    }
}
