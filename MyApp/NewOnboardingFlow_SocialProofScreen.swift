import SwiftUI

struct NewOnboardingFlow_SocialProofScreen: View {
    let model: NewOnboardingFlowViewModel

    @State private var appeared = false
    @State private var nextEnabled = false

    private let reviews: [(quote: String, author: String, initial: String, isLeading: Bool, delay: Double)] = [
        ("Finally got my bench up 20kg in 8 weeks. The progressive overload is no joke.",
         "kristjan_s", "K", true, 0.10),
        ("I've tried so many apps. This is the first one that actually adapts to me.",
         "jon_b", "J", false, 0.20),
        ("Showed my PT the plan and he said it was better than what he'd written.",
         "arni_t", "A", true, 0.44),
        ("The workout structure finally makes sense. I feel like I know exactly what I'm doing.",
         "siggi_g", "S", false, 0.54),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("Members just like you")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        Text("are getting stronger.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(duration: 0.6), value: appeared)

                    reviewBubble(reviews[0])
                    reviewBubble(reviews[1])

                    // Star card
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))

                        VStack(spacing: 10) {
                            HStack(spacing: 3) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(Color.appGold)
                                        .font(.title3)
                                }
                            }
                            Text("Loved by our community")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("Thousands of members training smarter, building strength, and finally staying consistent.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .glassEffect(.regular.tint(Color.appGold.opacity(0.15)), in: .rect(cornerRadius: 18))

                        Image(systemName: "laurel.trailing")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(duration: 0.6).delay(0.32), value: appeared)

                    reviewBubble(reviews[2])
                    reviewBubble(reviews[3])
                }
                .padding(.horizontal, 24)
                .padding(.top, 48)
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)

            // Pinned CTA
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.clear, Color.appBg],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 32).allowsHitTesting(false)

                Button("Continue") { model.advance() }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .disabled(!nextEnabled)
                    .padding(.horizontal, 24).padding(.bottom, 32)
            }
        }
        .onAppear { withAnimation(.spring(duration: 0.7)) { appeared = true } }
        .task {
            try? await Task.sleep(for: .seconds(2))
            nextEnabled = true
        }
    }

    private func reviewBubble(_ r: (quote: String, author: String, initial: String, isLeading: Bool, delay: Double)) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if !r.isLeading { Spacer(minLength: 48) }

            VStack(alignment: .leading, spacing: 12) {
                Text(r.quote)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: 28, height: 28)
                        Text(r.initial)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text(r.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))

            if r.isLeading { Spacer(minLength: 48) }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(duration: 0.6).delay(r.delay), value: appeared)
    }
}
