import SwiftUI
import DotLottie

// MARK: - Main multi-screen sleep step

struct NewOnboardingFlow_SleepStep: View {
    let model: NewOnboardingFlowViewModel

    enum SubPhase { case hero, tracker, duration, goals }

    @State private var subPhase: SubPhase = .hero
    @State private var appeared = false

    var body: some View {
        ZStack {
            SleepGradient()
            switch subPhase {
            case .hero:
                SleepHeroScreen(onContinue: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { subPhase = .tracker }
                }, onBack: model.goBack)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            case .tracker:
                SleepTrackerScreen(onEnable: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { subPhase = .duration }
                }, onSkip: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { subPhase = .duration }
                }, onBack: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { subPhase = .hero }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            case .duration:
                SleepDurationScreen(onContinue: { answer in
                    model.sleepDurationAnswer = answer
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { subPhase = .goals }
                }, onBack: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { subPhase = .tracker }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            case .goals:
                SleepGoalsScreen(onContinue: { goals in
                    model.sleepGoalsAnswer = goals
                    model.advance()
                }, onBack: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { subPhase = .duration }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: subPhase)
    }
}

// MARK: - Sleep gradient background

private struct SleepGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.48, green: 0.15, blue: 0.50),
                Color(red: 0.32, green: 0.18, blue: 0.60),
                Color(red: 0.52, green: 0.30, blue: 0.72),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.appAccent.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 100, y: -80)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color(red: 0.50, green: 0.30, blue: 0.92).opacity(0.40))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -80, y: 100)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shared back button bar

private struct SleepBackBar: View {
    let onBack: () -> Void
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - Shared option row

private struct SleepOptionRow: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.appAccent : .white.opacity(0.75))
                    .frame(width: 26)
                Text(label)
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
}

// MARK: - Screen 1: Hero

private struct SleepHeroScreen: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @StateObject private var lottie = DotLottieAnimation(
        fileName: "sleep(1)",
        config: AnimationConfig(autoplay: true, loop: true, speed: 0.9)
    )
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            SleepBackBar(onBack: onBack)

            Spacer()

            lottie.view()
                .frame(width: 260, height: 260)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.7), value: appeared)

            VStack(spacing: 8) {
                Text("Sleep fuels")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                Text("your recovery.")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.appAccent)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 28)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(duration: 0.7).delay(0.1), value: appeared)

            Text("Poor sleep limits muscle repair and kills motivation. Let's understand your sleep habits.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 12)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.7).delay(0.2), value: appeared)

            Spacer()

            Button("Tell us about your sleep") { onContinue() }
                .buttonStyle(.glassProminent)
                .tint(.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.7).delay(0.3), value: appeared)
        }
        .onAppear {
            withAnimation { appeared = true }
            _ = lottie.play()
        }
    }
}

// MARK: - Screen 2: Enable Sleep Tracker

private struct SleepTrackerScreen: View {
    let onEnable: () -> Void
    let onSkip: () -> Void
    let onBack: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            SleepBackBar(onBack: onBack)

            ScrollView {
                VStack(spacing: 28) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.appAccent)
                        .padding(.top, 32)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.7), value: appeared)

                    VStack(spacing: 8) {
                        Text("Enable Sleep Tracking")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Sync your sleep data for smarter recovery insights.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.7).delay(0.1), value: appeared)

                    // Apple Health card
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1, green: 0.25, blue: 0.42), Color(red: 0.95, green: 0.15, blue: 0.55)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.white)
                                .font(.title2)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Apple Health")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Sleep data • Read access")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(18)
                    .glassEffect(.regular.tint(.appAccent.opacity(0.1)), in: .rect(cornerRadius: 20))
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.7).delay(0.2), value: appeared)

                    VStack(spacing: 10) {
                        Label("Your data is private and never shared.", systemImage: "lock.fill")
                        Label("Used only to personalise your recovery plan.", systemImage: "checkmark.shield.fill")
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.7).delay(0.25), value: appeared)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 12) {
                Button("Enable Sleep Tracker") { onEnable() }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                Button("Skip for now") { onSkip() }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 28)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(duration: 0.7).delay(0.3), value: appeared)
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Screen 3: Sleep Duration Question

private struct SleepDurationScreen: View {
    let onContinue: (String) -> Void
    let onBack: () -> Void

    @State private var selected: String = ""
    @State private var appeared = false

    private let options: [(id: String, icon: String, label: String)] = [
        ("under6",  "moon",          "Less than 6 hours"),
        ("6to7",    "moon.fill",     "6–7 hours"),
        ("7to9",    "star.fill",     "7–9 hours"),
        ("over9",   "moon.zzz.fill", "More than 9 hours"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            SleepBackBar(onBack: onBack)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("How many hours do you")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Text("typically sleep?")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6), value: appeared)

                    Text("On an average night — not your best or worst.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.6).delay(0.08), value: appeared)

                    VStack(spacing: 10) {
                        ForEach(options, id: \.id) { opt in
                            SleepOptionRow(
                                icon: opt.icon,
                                label: opt.label,
                                isSelected: selected == opt.id,
                                onTap: {
                                    withAnimation(.snappy(duration: 0.18)) { selected = opt.id }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6).delay(0.15), value: appeared)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 12) {
                Button {
                    onContinue(selected)
                } label: {
                    HStack(spacing: 10) {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .fontWeight(.semibold)
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .tint(.appAccent)
                .controlSize(.extraLarge)
                .disabled(selected.isEmpty)
                .padding(.horizontal, 24)

                Button("Skip") { onContinue("") }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 28)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(duration: 0.6).delay(0.2), value: appeared)
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Screen 4: Sleep Goals (multi-select)

private struct SleepGoalsScreen: View {
    let onContinue: (Set<String>) -> Void
    let onBack: () -> Void

    @State private var selected: Set<String> = []
    @State private var appeared = false

    private let goals: [(id: String, icon: String, label: String)] = [
        ("fallAsleep",   "moon.zzz",         "Fall asleep faster"),
        ("stayAsleep",   "moon.stars",        "Stay asleep through the night"),
        ("wakeRefreshed","sunrise.fill",      "Wake up feeling refreshed"),
        ("consistency",  "calendar.badge.clock","Sleep at consistent times"),
        ("lessStress",   "brain.head.profile","Reduce stress before bed"),
        ("trackQuality", "waveform.path.ecg", "Track my sleep quality"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            SleepBackBar(onBack: onBack)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("What are your")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Text("sleep goals?")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6), value: appeared)

                    Text("Select all that apply. We'll build these into your recovery plan.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.6).delay(0.08), value: appeared)

                    VStack(spacing: 10) {
                        ForEach(goals, id: \.id) { goal in
                            SleepOptionRow(
                                icon: goal.icon,
                                label: goal.label,
                                isSelected: selected.contains(goal.id),
                                onTap: {
                                    withAnimation(.snappy(duration: 0.18)) {
                                        if selected.contains(goal.id) {
                                            selected.remove(goal.id)
                                        } else {
                                            selected.insert(goal.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6).delay(0.15), value: appeared)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 12) {
                Button {
                    onContinue(selected)
                } label: {
                    HStack(spacing: 10) {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .fontWeight(.semibold)
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .tint(.appAccent)
                .controlSize(.extraLarge)
                .disabled(selected.isEmpty)
                .padding(.horizontal, 24)

                Button("Skip") { onContinue([]) }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 28)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(duration: 0.6).delay(0.2), value: appeared)
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

#Preview("Sleep step") {
    NewOnboardingFlow_SleepStep(model: NewOnboardingFlowViewModel())
        .preferredColorScheme(.dark)
}
