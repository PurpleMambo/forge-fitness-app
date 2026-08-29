import SwiftUI
import DotLottie

struct NewOnboardingFlow_SupplementsStep: View {
    let model: NewOnboardingFlowViewModel

    @StateObject private var lottie = DotLottieAnimation(
        fileName: "Supplements for fines and diets(1)",
        config: AnimationConfig(autoplay: true, loop: true, speed: 0.9)
    )
    @State private var appeared = false
    @State private var selected: String = ""

    private let options: [(id: String, icon: String, label: String, sub: String)] = [
        ("never",       "xmark.circle",       "Never tried them",       "Starting from scratch"),
        ("occasionally","arrow.2.circlepath",  "Occasionally",           "Protein or creatine here and there"),
        ("regularly",   "checkmark.circle",   "Regularly",              "Part of my routine"),
        ("stacked",     "bolt.fill",          "Full stack",             "Pre-workout, BCAAs, the lot"),
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Back bar
                HStack {
                    Button(action: model.goBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.glass)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 4)

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero lottie
                        lottie.view()
                            .frame(width: 280, height: 280)
                            .scaleEffect(appeared ? 1 : 0.8)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(duration: 0.7), value: appeared)
                            .padding(.top, 8)

                        // Headline
                        VStack(spacing: 6) {
                            Text("Supplements")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(.white)
                            Text("& nutrition.")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(Color.appGold)
                        }
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.7).delay(0.08), value: appeared)

                        Text("Have you ever used supplements? We'll tailor your recovery and nutrition guidance.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.top, 10)
                            .padding(.horizontal, 32)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(duration: 0.7).delay(0.12), value: appeared)

                        // Options
                        VStack(spacing: 10) {
                            ForEach(options, id: \.id) { opt in
                                supplementsOptionRow(opt)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.6).delay(0.18), value: appeared)

                        Spacer(minLength: 32)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .safeAreaInset(edge: .bottom) { ctaPanel }
        .onAppear {
            withAnimation { appeared = true }
            _ = lottie.play()
        }
    }

    // MARK: - Option row

    private func supplementsOptionRow(_ opt: (id: String, icon: String, label: String, sub: String)) -> some View {
        let isSelected = selected == opt.id
        return Button {
            withAnimation(.snappy(duration: 0.18)) { selected = opt.id }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: opt.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.appGold : .white.opacity(0.7))
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(opt.label)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(opt.sub)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.appGold : .white.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .glassEffect(isSelected ? .regular.tint(.appGold.opacity(0.2)) : .regular, in: .rect(cornerRadius: 18))
        .animation(.snappy(duration: 0.18), value: isSelected)
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

            VStack(spacing: 12) {
                Button {
                    model.supplementsPick(selected)
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
                .tint(.appGold)
                .controlSize(.extraLarge)
                .disabled(selected.isEmpty)
                .padding(.horizontal, 24)

                Button("Skip for now") {
                    model.supplementsPick("")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 32)
            }
            .background(Color.appBg)
        }
    }
}

#Preview("Supplements step") {
    NewOnboardingFlow_SupplementsStep(model: NewOnboardingFlowViewModel())
        .preferredColorScheme(.dark)
}
