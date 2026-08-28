import SwiftUI
import UIKit
import DotLottie

struct NewOnboardingFlow_GoalSpeedScreen: View {
    let model: NewOnboardingFlowViewModel

    private enum Speed: String, CaseIterable {
        case slow        = "Slow"
        case recommended = "Balanced"
        case fast        = "Fast"

        var description: String {
            switch self {
            case .slow:        return "A gentle, sustainable pace — great for building long-term habits."
            case .recommended: return "The most balanced approach — motivating and ideal for most members."
            case .fast:        return "An aggressive pace for rapid results. Requires serious discipline."
            }
        }

        var icon: String {
            switch self {
            case .slow:        return "tortoise.fill"
            case .recommended: return "figure.walk"
            case .fast:        return "figure.run"
            }
        }
    }

    @State private var selectedSpeed: Speed = .recommended
    @State private var appeared = false
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("How fast do you want to reach your goal?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        Text("Pick a pace that suits your lifestyle.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .opacity(appeared ? 1 : 0)

                        // Three-animal picker
                        HStack(spacing: 0) {
                            SpeedIconButton(
                                lottieName: "Moody Llama(1)",
                                lottieSpeed: 0.45,
                                label: "Slow",
                                isSelected: selectedSpeed == .slow
                            ) {
                                haptic.impactOccurred()
                                withAnimation(.snappy(duration: 0.2)) { selectedSpeed = .slow }
                            }
                            .frame(maxWidth: .infinity)

                            SpeedIconButton(
                                lottieName: "Health(1)",
                                lottieSpeed: 1.0,
                                label: "Balanced",
                                isSelected: selectedSpeed == .recommended
                            ) {
                                haptic.impactOccurred()
                                withAnimation(.snappy(duration: 0.2)) { selectedSpeed = .recommended }
                            }
                            .frame(maxWidth: .infinity)

                            SpeedIconButton(
                                lottieName: "Lion Running(1)",
                                lottieSpeed: 1.9,
                                label: "Fast",
                                isSelected: selectedSpeed == .fast
                            ) {
                                haptic.impactOccurred()
                                withAnimation(.snappy(duration: 0.2)) { selectedSpeed = .fast }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 32)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.6).delay(0.1), value: appeared)

                        descriptionCard
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(duration: 0.6).delay(0.2), value: appeared)

                        Spacer(minLength: 120)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .safeAreaInset(edge: .bottom) { ctaPanel }
        .onAppear {
            haptic.prepare()
            withAnimation(.spring(duration: 0.7)) { appeared = true }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: model.goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)
            Spacer()
        }
    }

    // MARK: - Description card

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: selectedSpeed.icon)
                    .foregroundStyle(Color.appAccent)
                Text(selectedSpeed.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(selectedSpeed.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(.appAccent.opacity(0.15)), in: .rect(cornerRadius: 18))
        .animation(.easeInOut(duration: 0.2), value: selectedSpeed)
    }

    // MARK: - CTA

    private var ctaPanel: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.appBg.opacity(0), Color.appBg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 36)
            .allowsHitTesting(false)

            Button {
                model.goalSpeedAnswer = selectedSpeed.rawValue
                model.advance()
            } label: {
                HStack(spacing: 10) {
                    Text("Continue")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .fontWeight(.semibold)
                }
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(.appAccent)
            .controlSize(.extraLarge)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(Color.appBg)
        }
    }
}

// MARK: - Speed icon button (plays lottie only when selected)

private struct SpeedIconButton: View {
    let lottieName: String
    let lottieSpeed: Float
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    @StateObject private var animation: DotLottieAnimation

    init(lottieName: String, lottieSpeed: Float, label: String, isSelected: Bool, onTap: @escaping () -> Void) {
        self.lottieName = lottieName
        self.lottieSpeed = lottieSpeed
        self.label = label
        self.isSelected = isSelected
        self.onTap = onTap
        _animation = StateObject(wrappedValue: DotLottieAnimation(
            fileName: lottieName,
            config: AnimationConfig(autoplay: isSelected, loop: true, speed: lottieSpeed)
        ))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                animation.view()
                    .frame(width: 96, height: 96)
                    .opacity(isSelected ? 1.0 : 0.4)
                    .scaleEffect(isSelected ? 1.0 : 0.8)

                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                    .lineLimit(1)
            }
            .animation(.snappy(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .onAppear { applyPlayback(isSelected) }
        .onChange(of: isSelected) { _, newValue in applyPlayback(newValue) }
    }

    private func applyPlayback(_ playing: Bool) {
        if playing { _ = animation.play() }
        else { _ = animation.pause() }
    }
}

#Preview("Goal speed screen") {
    ZStack {
        AppBackground()
        NewOnboardingFlow_GoalSpeedScreen(model: NewOnboardingFlowViewModel())
    }
    .preferredColorScheme(.dark)
}
