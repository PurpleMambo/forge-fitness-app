import SwiftUI
import DotLottie

struct NewOnboardingFlow_FeatureShowcaseScreen: View {
    let model: NewOnboardingFlowViewModel

    private struct Feature {
        let icon: String
        let title: String
        let description: String
        let tint: Color
    }

    private let features: [Feature] = [
        Feature(icon: "chart.line.uptrend.xyaxis", title: "Progressive Overload",
                description: "Your weights and reps adjust automatically as your strength grows.",
                tint: .appAccent),
        Feature(icon: "repeat", title: "Smart Scheduling",
                description: "A weekly plan that balances push, pull, and legs for maximum recovery.",
                tint: .appGold),
        Feature(icon: "heart.fill", title: "Recovery Tracking",
                description: "Know when to push hard and when to back off — logged automatically.",
                tint: .appAccent),
        Feature(icon: "fork.knife", title: "Nutrition Guidance",
                description: "Calorie and macro targets tailored to your weight and training load.",
                tint: .appGold),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // Badge
                    Text("EXCLUSIVE TO MEMBERS")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(Color.appGold)
                        .padding(.horizontal, 16).padding(.vertical, 7)
                        .glassEffect(.regular.tint(.appGold.opacity(0.2)), in: .capsule)

                    VStack(spacing: 4) {
                        Text(model.firstName.isEmpty ? "Train like a pro." : "\(model.firstName), train like a pro.")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .multilineTextAlignment(.center)

                    Text("Understand your progress, follow your plan, and get insights built for your training.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    // Feature cards — horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(features.indices, id: \.self) { i in
                                featureCard(features[i])
                            }
                            SupplementsFeatureCard()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 2)
                    }
                    .padding(.horizontal, -24)

                    // Disclaimer
                    Text("Results vary. Your plan is personalised based on the information you provided.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)

            // Pinned CTA
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.clear, Color.appBg],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 32).allowsHitTesting(false)

                Button("Commit to my training") { model.advance() }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24).padding(.bottom, 32)
            }
        }
    }

    private func featureCard(_ feature: Feature) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.tint(feature.tint.opacity(0.4)), in: .rect(cornerRadius: 12))

            Spacer(minLength: 0)

            Text(feature.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(feature.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3, reservesSpace: true)
        }
        .frame(width: 150, height: 188, alignment: .topLeading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

// MARK: - Supplements card (uses DotLottie, needs @StateObject so lives in its own struct)

private struct SupplementsFeatureCard: View {
    @StateObject private var lottie = DotLottieAnimation(
        fileName: "Supplements for fines and diets(1)",
        config: AnimationConfig(autoplay: true, loop: true, speed: 0.8)
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            lottie.view()
                .frame(width: 44, height: 44)
                .clipShape(.rect(cornerRadius: 10))

            Spacer(minLength: 0)

            Text("Supplement Stack")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Personalized supplement tips to support your recovery and performance.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3, reservesSpace: true)
        }
        .frame(width: 150, height: 188, alignment: .topLeading)
        .padding(14)
        .glassEffect(.regular.tint(Color.appGold.opacity(0.15)), in: .rect(cornerRadius: 20))
    }
}
