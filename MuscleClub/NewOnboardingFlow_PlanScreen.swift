import SwiftUI

struct NewOnboardingFlow_PlanScreen: View {
    let model: NewOnboardingFlowViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Nav
                    HStack {
                        Text("MUSCLE CLUB")
                            .font(.system(size: 18, weight: .black)).tracking(5)
                            .foregroundStyle(.white.opacity(0.08))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 32)

                    // Plan header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR CUSTOM PLAN")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.appGold)
                            .tracking(2)

                        Text(planTitle)
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(.white)

                        Text("A plan built for consistent progress with automatic progression and recovery-aware training.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)

                    // Stat cards
                    HStack(spacing: 12) {
                        statCard(icon: "repeat", value: "3×", label: "Per week")
                        statCard(icon: "building.2.fill", value: "Gym", label: "Commercial")
                    }
                    .padding(.horizontal, 24).padding(.top, 22)

                    // Training week
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Your Training Week")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.appGold)
                            Spacer()
                            Image(systemName: "info.circle").foregroundStyle(.secondary)
                        }
                        Text("Your week is balanced so you always know what to train and when to rest.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24).padding(.top, 30)

                    // Day cards
                    VStack(spacing: 10) {
                        dayCard(day: "Day 1", tag: "First Workout", name: "Push Day",
                                symbol: "figure.strengthtraining.traditional", active: true)
                        dayCard(day: "Day 2", tag: nil, name: "Pull Day",
                                symbol: "figure.strengthtraining.traditional", active: false)
                        dayCard(day: "Day 3", tag: nil, name: "Leg Day",
                                symbol: "figure.walk", active: false)
                    }
                    .padding(.horizontal, 24).padding(.top, 14)

                    // Why it works
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why this plan works")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.appGold)
                        benefitRow(icon: "bolt.fill",
                                   title: "Structured for serious progress",
                                   sub: "Follow a plan built around your goal, experience, schedule, and recovery.")
                        benefitRow(icon: "chart.line.uptrend.xyaxis",
                                   title: "Automatic progressive overload",
                                   sub: "Your reps, sets, and weights adjust as your strength grows.")
                        benefitRow(icon: "arrow.trianglehead.2.clockwise",
                                   title: "Recovery-aware training",
                                   sub: "Your plan adapts each week based on what you log.")
                    }
                    .padding(.horizontal, 24).padding(.top, 30)

                    VStack(spacing: 6) {
                        Text("🏆").font(.system(size: 32))
                        (Text("Join ").foregroundStyle(.secondary)
                         + Text("475k+ members").foregroundStyle(Color.appAccent).bold()
                         + Text(" building strength and training smarter.").foregroundStyle(.secondary))
                            .font(.system(size: 14)).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28).padding(.horizontal, 24)

                    Spacer(minLength: 120)
                }
            }

            // Pinned CTA
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.clear, Color.appBg],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 40).allowsHitTesting(false)
                Button("See what's inside") { model.advance() }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24).padding(.bottom, 32)
            }
        }
    }

    private var planTitle: String {
        guard !model.answers.isEmpty else { return "Get Strong" }
        switch model.answers[0] {
        case "Lift heavier":         return "Get Stronger"
        case "Build more muscle":    return "Build Muscle"
        case "Get lean and defined": return "Get Lean"
        case "Lose weight":          return "Lose Weight"
        default:                     return "Get Strong"
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 24, weight: .heavy)).foregroundStyle(.primary)
            Text(label).font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .glassEffect(in: .rect(cornerRadius: 14))
    }

    private func dayCard(day: String, tag: String?, name: String, symbol: String, active: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    chip(day)
                    if let t = tag { chip(t) }
                }
                Text(name).font(.system(size: 20, weight: .heavy)).foregroundStyle(.primary)
            }
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(active ? Color.appAccent : Color.secondary.opacity(0.3))
        }
        .padding(18)
        .glassEffect(active ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 16))
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .glassEffect(in: .rect(cornerRadius: 6))
    }

    private func benefitRow(icon: String, title: String, sub: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.appAccent)
                .frame(width: 36, height: 36)
                .glassEffect(.regular.tint(.appAccent), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(.primary)
                Text(sub).font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(2)
            }
        }
    }
}
