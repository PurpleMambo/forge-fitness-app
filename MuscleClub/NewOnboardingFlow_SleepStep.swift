import SwiftUI
import DotLottie

struct NewOnboardingFlow_SleepStep: View {
    let model: NewOnboardingFlowViewModel

    @StateObject private var lottie = DotLottieAnimation(
        fileName: "sleep(1)",
        config: AnimationConfig(autoplay: true, loop: true, speed: 1.0)
    )
    @State private var selectedDuration: String = ""
    @State private var appeared = false

    private let sleepOptions: [(label: String, icon: String, id: String)] = [
        ("Less than 5 hours", "moon",          "under5"),
        ("5–6 hours",         "moon.fill",     "5to6"),
        ("6–8 hours",         "star.fill",     "6to8"),
        ("8+ hours",          "moon.zzz.fill", "over8"),
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 0) {
                        lottie.view()
                            .frame(width: 200, height: 200)
                            .padding(.top, 16)
                            .scaleEffect(appeared ? 1 : 0.8)
                            .opacity(appeared ? 1 : 0)

                        VStack(spacing: 6) {
                            Text("Sleep fuels")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(.white)
                            Text("your recovery.")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(Color.appAccent)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .opacity(appeared ? 1 : 0)

                        Text("Poor sleep limits muscle repair and kills motivation. Tell us about yours.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.top, 10)
                            .padding(.horizontal, 32)
                            .opacity(appeared ? 1 : 0)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("How many hours do you typically sleep?")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.bottom, 4)

                            ForEach(sleepOptions, id: \.id) { option in
                                sleepOptionRow(option)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 16)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.6).delay(0.15), value: appeared)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .safeAreaInset(edge: .bottom) { ctaPanel }
        .onAppear {
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

    // MARK: - Option row

    private func sleepOptionRow(_ option: (label: String, icon: String, id: String)) -> some View {
        let isSelected = selectedDuration == option.id
        return Button {
            withAnimation(.snappy(duration: 0.18)) { selectedDuration = option.id }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.appAccent : .white.opacity(0.75))
                    .frame(width: 24)
                Text(option.label)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.appAccent : .white.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .glassEffect(isSelected ? .regular.tint(.appAccent.opacity(0.25)) : .regular, in: .rect(cornerRadius: 18))
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

            Button {
                model.sleepDurationAnswer = selectedDuration
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
            .disabled(selectedDuration.isEmpty)
            .padding(.horizontal, 24)
            .background(Color.appBg)

            Button("Skip for now") {
                model.sleepDurationAnswer = ""
                model.advance()
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(Color.appBg)
        }
    }
}

#Preview("Sleep step") {
    ZStack {
        AppBackground()
        NewOnboardingFlow_SleepStep(model: NewOnboardingFlowViewModel())
    }
    .preferredColorScheme(.dark)
}
