import SwiftUI

// MARK: - Step Data
private enum OInputKind {
    case options([String])
    case textField(placeholder: String, numeric: Bool = false)
}

private struct OStep {
    let parts: [(text: String, red: Bool)]
    let input: OInputKind
}

private let steps: [OStep] = [
    // 0 — top goal (existing)
    OStep(parts: [
        ("Hey, it's your coach! I'm excited to kick off your new training plan.\n\nTo start, what's your ", false),
        ("top fitness goal?", true)
    ], input: .options(["Lift heavier", "Build more muscle", "Get lean and defined", "Lose weight"])),

    // 1 — full name (new)
    OStep(parts: [
        ("Great choice! Let's build your profile.\n\nWhat's your ", false),
        ("full name?", true)
    ], input: .textField(placeholder: "Your name")),

    // 2 — location (new)
    OStep(parts: [
        ("Nice to meet you! Where are you ", false),
        ("based?", true)
    ], input: .textField(placeholder: "City or town")),

    // 3 — current weight (new)
    OStep(parts: [
        ("Got it. What's your current ", false),
        ("weight", true),
        (" (kg, approx)?", false)
    ], input: .textField(placeholder: "e.g. 80", numeric: true)),

    // 4 — height (new)
    OStep(parts: [
        ("And your ", false),
        ("height", true),
        (" (cm)?", false)
    ], input: .textField(placeholder: "e.g. 180", numeric: true)),

    // 5 — goal weight (new)
    OStep(parts: [
        ("What's your ", false),
        ("goal weight", true),
        (" (kg, approx)?", false)
    ], input: .textField(placeholder: "e.g. 75", numeric: true)),

    // 6 — strength training routine (existing)
    OStep(parts: [
        ("Good. Which best describes your current strength training ", false),
        ("routine?", true)
    ], input: .options(["I'm just getting started", "I struggle with consistency", "I'm coming back after a break", "I strength train consistently"])),

    // 7 — how long training (new)
    OStep(parts: [
        ("How long have you been ", false),
        ("training?", true)
    ], input: .options(["Less than 6 months", "6 months – 1 year", "1–3 years", "3+ years"])),

    // 8 — past sports (new)
    OStep(parts: [
        ("Have you played any ", false),
        ("sports", true),
        (" before?", false)
    ], input: .options(["Yes", "No"])),

    // 9 — current sports (new)
    OStep(parts: [
        ("Are you currently playing any ", false),
        ("sports?", true)
    ], input: .options(["Yes", "No"])),

    // 10 — exercise type preference (new)
    OStep(parts: [
        ("What type of ", false),
        ("exercise", true),
        (" do you enjoy most?", false)
    ], input: .options(["Weight training", "Cardio", "Both equally", "Group classes / team sports"])),

    // 11 — where to train (existing)
    OStep(parts: [
        ("Got it, we'll tailor your plan to your experience.\n\nNext, ", false),
        ("where", true),
        (" do you primarily plan on training?", false)
    ], input: .options(["At a large commercial gym", "At a small gym", "In a garage gym", "At home with limited equipment", "I don't have any equipment"])),

    // 12 — which gym (new)
    OStep(parts: [
        ("Which ", false),
        ("gym", true),
        (" do you train at?", false)
    ], input: .textField(placeholder: "e.g. World Class, Life, Planet Fitness")),

    // 13 — World Class location (new — optional, instruct N/A)
    OStep(parts: [
        ("If you train at World Class, which ", false),
        ("location", true),
        (" do you use most?", false)
    ], input: .textField(placeholder: "e.g. Smáralind, Laugar — type N/A if not applicable")),

    // 14 — days per week (existing)
    OStep(parts: [
        ("Nice. How many ", false),
        ("days per week", true),
        (" can you usually strength train?", false)
    ], input: .options(["1–2 days a week", "3 days a week", "4 days a week", "5 days a week", "6+ days a week"])),

    // 15 — workout duration (new)
    OStep(parts: [
        ("How long do you want your ", false),
        ("workouts", true),
        (" to be?", false)
    ], input: .options(["30–45 minutes", "45–60 minutes", "60–75 minutes", "75+ minutes"])),

    // 16 — activity at work (new)
    OStep(parts: [
        ("Are you ", false),
        ("physically active", true),
        (" at work?", false)
    ], input: .options(["Mostly sedentary (desk job)", "On my feet, light movement", "Very active (physical labor)"])),

    // 17 — injuries (new)
    OStep(parts: [
        ("Any ", false),
        ("injuries or health conditions", true),
        (" I should know about?", false)
    ], input: .options(["None", "Yes — minor injury or pain", "Yes — significant issue"])),

    // 18 — supplements (new)
    OStep(parts: [
        ("Have you ever used ", false),
        ("supplements?", true)
    ], input: .options(["Yes", "No"])),

    // 19 — diet quality (new)
    OStep(parts: [
        ("How has your ", false),
        ("diet", true),
        (" been recently?", false)
    ], input: .options(["Pretty poor", "Could be better", "Decent", "Very clean and consistent"])),

    // 20 — food intolerances (new)
    OStep(parts: [
        ("Any ", false),
        ("food intolerances or allergies", true),
        ("?", false)
    ], input: .options(["None", "Lactose intolerant", "Gluten-free", "Nut allergy", "Other"])),

    // 21 — eating regularly (new)
    OStep(parts: [
        ("Do you eat ", false),
        ("regularly", true),
        (" throughout the day?", false)
    ], input: .options(["Yes, always", "Mostly", "Not really — I skip meals often"])),

    // 22 — notifications (existing)
    OStep(parts: [
        ("Okay, we'll build your plan around that.\n\nDo you want us to send you a ", false),
        ("preview of your workout", true),
        (" on training days?", false)
    ], input: .options(["Yes, enable notifications", "Maybe later"])),

    // 23 — calorie tracking (existing)
    OStep(parts: [
        ("No worries, you can enable that later.\n\nDo you want to calculate the ", false),
        ("calories you burn", true),
        (" each workout?", false)
    ], input: .options(["Yes, connect to Apple Health", "Yes, input details manually", "Maybe later"])),

    // 24 — referral source (new)
    OStep(parts: [
        ("Almost done! Where did you ", false),
        ("hear about", true),
        (" this coaching?", false)
    ], input: .options(["Instagram", "A friend or family member", "Google / search", "Other"])),
]

// MARK: - OnboardingView
struct OnboardingView: View {
    @Environment(AppState.self) var appState

    enum Phase { case chat, loading, plan, signup, paywall }

    @State private var phase: Phase = .chat
    @State private var step = 0
    @State private var answers: [String] = []
    @State private var textInput = ""
    @State private var showBubble  = false
    @State private var showQ       = true
    @State private var showOptions = true
    @State private var busy        = false
    @Namespace private var bubbleNS

    var body: some View {
        ZStack {
            AppBackground()
            switch phase {
            case .chat:    chatBody.transition(.opacity)
            case .loading: PlanCalculatingView { withAnimation { phase = .plan } }.transition(.opacity)
            case .plan:    PlanSummaryView { withAnimation { phase = .signup } }.transition(.opacity)
            case .signup:  SignUpView { withAnimation { phase = .paywall } }.transition(.opacity)
            case .paywall: ForgePaywallView { appState.onboardingComplete = true }.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
    }

    // MARK: - Chat body
    var chatBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            Spacer()

            // Previous answer bubble — Liquid Glass tinted with accent
            if showBubble, let last = answers.last {
                HStack {
                    Spacer()
                    Text(last)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.horizontal, 18).padding(.vertical, 11)
                        .glassEffect(.regular.tint(.appAccent))
                        .glassEffectTransition(.materialize)
                }
                .padding(.horizontal, 24).padding(.bottom, 28)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity))
            }

            // Question text
            if showQ, step < steps.count {
                questionText(steps[step])
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer(minLength: 40)

            // Input area — options or text field depending on step type
            if showOptions, step < steps.count {
                inputArea(for: steps[step])
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Input area (options or text field)
    @ViewBuilder
    private func inputArea(for s: OStep) -> some View {
        switch s.input {
        case .options(let opts):
            GlassEffectContainer(spacing: 10) {
                VStack(alignment: .trailing, spacing: 10) {
                    ForEach(Array(opts.enumerated()), id: \.offset) { _, opt in
                        HStack {
                            Spacer()
                            Button(opt) { pick(opt) }
                                .buttonStyle(.glass)
                                .glassEffectID(opt, in: bubbleNS)
                        }
                    }
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 52)

        case .textField(let placeholder, let numeric):
            VStack(spacing: 16) {
                TextField(placeholder, text: $textInput)
                    .font(.system(size: 20, weight: .semibold))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(numeric ? .never : .words)
                    .keyboardType(numeric ? .decimalPad : .default)
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .glassEffect(in: .rect(cornerRadius: 14))

                Button("Continue") {
                    pick(textInput.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .buttonStyle(.glassProminent)
                .tint(.appAccent)
                .frame(maxWidth: .infinity)
                .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24).padding(.bottom, 52)
        }
    }

    var topBar: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)
            .opacity(step > 0 ? 1 : 0)

            Spacer()

            Text("FORGE")
                .font(.system(size: 20, weight: .black)).tracking(6)
                .foregroundColor(.white.opacity(0.08))

            Spacer()

            // Balance spacer
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
                .hidden()
                .buttonStyle(.glass)
                .opacity(0)
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }

    private func questionText(_ s: OStep) -> Text {
        s.parts.reduce(Text("")) { acc, part in
            acc + Text(part.text).foregroundColor(part.red ? Color.appAccent : .white)
        }
        .font(.system(size: 28, weight: .bold))
    }

    // MARK: - Actions
    func pick(_ opt: String) {
        guard !busy else { return }
        busy = true
        answers.append(opt)
        textInput = ""
        let isLast = step == steps.count - 1
        withAnimation(.easeInOut(duration: 0.25)) {
            showOptions = false; showQ = false; showBubble = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if isLast { withAnimation { phase = .loading }; busy = false; return }
            step += 1
            withAnimation(.spring(response: 0.5)) { showBubble = true; showQ = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.5)) { showOptions = true }
                busy = false
            }
        }
    }

    func goBack() {
        guard step > 0, !busy else { return }
        busy = true
        withAnimation(.easeInOut(duration: 0.25)) {
            showOptions = false; showQ = false; showBubble = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !answers.isEmpty { answers.removeLast() }
            step -= 1
            textInput = ""
            withAnimation(.spring(response: 0.5)) { showBubble = !answers.isEmpty; showQ = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.5)) { showOptions = true }
                busy = false
            }
        }
    }
}

// MARK: - Plan Calculating View
private struct PlanCalculatingView: View {
    let onComplete: () -> Void

    private let calcSteps = [
        ("person.fill.checkmark",      "Analyzing your fitness profile"),
        ("dumbbell.fill",              "Calibrating starting weights"),
        ("calendar.badge.clock",       "Structuring your training week"),
        ("heart.fill",                 "Optimizing for recovery"),
    ]

    @State private var visibleCount = 0
    @State private var checkedCount = 0
    @State private var showReady = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Animated bolt icon
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.15))
                            .frame(width: 90, height: 90)
                            .scaleEffect(pulseScale)

                        Circle()
                            .fill(Color.appAccent.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseScale)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundColor(.appAccent)
                    }
                    Spacer()
                }
                .padding(.bottom, 44)

                // Heading
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calculating your")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.white)
                    Text("custom plan...")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.appAccent)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)

                // Step checklist
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(calcSteps.enumerated()), id: \.offset) { i, s in
                        if i < visibleCount {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(i < checkedCount ? Color.appAccent : Color.white.opacity(0.08))
                                        .frame(width: 32, height: 32)
                                    if i < checkedCount {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: s.0)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Text(s.1)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(i < checkedCount ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.secondary))
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }

                    if showReady {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.appGold)
                            Text("Your plan is ready!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appGold)
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.18
            }
        }
        .task { await runSequence() }
    }

    private func runSequence() async {
        for i in 0..<calcSteps.count {
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.spring(response: 0.45)) { visibleCount = i + 1 }
            try? await Task.sleep(nanoseconds: 550_000_000)
            withAnimation(.spring(response: 0.35)) { checkedCount = i + 1 }
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        withAnimation(.spring(response: 0.5)) { showReady = true }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        onComplete()
    }
}

// MARK: - Plan Summary View
struct PlanSummaryView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Nav
                    HStack {
                        Button { } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold)) }
                            .buttonStyle(.glass)
                        Spacer()
                        Text("FORGE").font(.system(size: 20, weight: .black)).tracking(6)
                            .foregroundColor(.white.opacity(0.08))
                        Spacer()
                        Image(systemName: "chevron.left").hidden()
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 28)

                    // Plan header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your custom plan")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.appGold).tracking(1)
                        Text("Get Lean")
                            .font(.system(size: 36, weight: .heavy)).foregroundColor(.white)
                        Text("A plan built for consistent progress with automatic progression and recovery-aware training.")
                            .font(.system(size: 15)).foregroundColor(.secondary).lineSpacing(3)
                    }
                    .padding(.horizontal, 24)

                    // Stat cards — Liquid Glass
                    HStack(spacing: 12) {
                        statCard(icon: "repeat", value: "3×", label: "Per week")
                        statCard(icon: "building.2.fill", value: "Gym", label: "Large Gym")
                    }
                    .padding(.horizontal, 24).padding(.top, 22)

                    // Training week
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Your Training Week")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.appGold)
                            Spacer()
                            Image(systemName: "info.circle").foregroundColor(.secondary)
                        }
                        Text("Your week is balanced so you know what to train each day and when to recover.")
                            .font(.system(size: 14)).foregroundColor(.secondary).lineSpacing(3)
                    }
                    .padding(.horizontal, 24).padding(.top, 28)

                    // Day cards — Liquid Glass with tint on active
                    VStack(spacing: 10) {
                        dayCard(day: "Day 1", tag: "First Workout", name: "Push Day",  symbol: "figure.strengthtraining.traditional", active: true)
                        dayCard(day: "Day 2", tag: nil,             name: "Pull Day",  symbol: "figure.strengthtraining.traditional", active: false)
                        dayCard(day: "Day 3", tag: nil,             name: "Leg Day",   symbol: "figure.walk",                         active: false)
                    }
                    .padding(.horizontal, 24).padding(.top, 14)

                    // Why it works
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why this plan works")
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.appGold)
                        benefitRow(icon: "bolt.fill",                      title: "Structured for serious progress",  sub: "Follow a plan built around your goal, experience, schedule, and recovery.")
                        benefitRow(icon: "chart.line.uptrend.xyaxis",      title: "Automatic progressive overload",   sub: "Your reps, sets, and weights adjust as your strength progresses.")
                        benefitRow(icon: "arrow.trianglehead.2.clockwise", title: "Recovery-aware training",          sub: "Your plan adapts each week based on what you log, always moving you forward.")
                    }
                    .padding(.horizontal, 24).padding(.top, 28)

                    VStack(spacing: 6) {
                        Text("🏆").font(.system(size: 32))
                        (Text("Join ").foregroundColor(.secondary)
                         + Text("475k+ members").foregroundColor(.appAccent).bold()
                         + Text(" building strength and training smarter.").foregroundColor(.secondary))
                            .font(.system(size: 14)).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 28).padding(.horizontal, 24)

                    Spacer(minLength: 110)
                }
            }

            // Continue — prominent glass tinted with accent
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.clear, Color.appBg], startPoint: .top, endPoint: .bottom)
                    .frame(height: 40).allowsHitTesting(false)
                Button("Continue", action: onContinue)
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24).padding(.bottom, 32)
            }
        }
    }

    func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(.secondary)
            Text(value).font(.system(size: 24, weight: .heavy)).foregroundColor(.primary)
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .glassEffect(in: .rect(cornerRadius: 14))
    }

    func dayCard(day: String, tag: String?, name: String, symbol: String, active: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    tagChip(day)
                    if let t = tag { tagChip(t) }
                }
                Text(name).font(.system(size: 20, weight: .heavy)).foregroundColor(.primary)
            }
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundColor(active ? .appAccent : .secondary.opacity(0.4))
        }
        .padding(18)
        .glassEffect(active ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 16))
    }

    func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .glassEffect(in: .rect(cornerRadius: 6))
    }

    func benefitRow(icon: String, title: String, sub: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold)).foregroundColor(.appAccent)
                .frame(width: 36, height: 36)
                .glassEffect(.regular.tint(.appAccent), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(.primary)
                Text(sub).font(.system(size: 13)).foregroundColor(.secondary).lineSpacing(2)
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Button { } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold)) }
                            .buttonStyle(.glass)
                        Spacer()
                    }
                    .padding(.bottom, 28)

                    Text("Your custom workout\nprogram is ready")
                        .font(.system(size: 30, weight: .heavy)).foregroundColor(.white).lineSpacing(2)
                    Text("Sign up below to save your profile and start training.")
                        .font(.system(size: 15)).foregroundColor(.secondary).padding(.top, 8)
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 12) {
                    // Social sign-in buttons — glass style
                    GlassEffectContainer(spacing: 8) {
                        VStack(spacing: 10) {
                            Button {  } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "apple.logo").font(.system(size: 16, weight: .semibold))
                                    Text("Sign up with Apple").font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)

                            Button {  } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "g.circle.fill").font(.system(size: 16, weight: .semibold))
                                    Text("Sign up with Google").font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                        }
                    }

                    // Primary CTA — prominent glass with accent tint
                    Button("Continue with Email", action: onComplete)
                        .buttonStyle(.glassProminent)
                        .tint(.appAccent)
                        .frame(maxWidth: .infinity)

                    HStack {
                        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                        Text("OR").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary).padding(.horizontal, 8)
                        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                    }
                    .padding(.vertical, 2)

                    Button("Log in with existing account", action: onComplete)
                        .buttonStyle(.glass)
                        .frame(maxWidth: .infinity)

                    (Text("By signing up, you agree to our ").foregroundColor(.secondary)
                     + Text("Privacy Policy").foregroundColor(.appAccent)
                     + Text(" and ").foregroundColor(.secondary)
                     + Text("Terms & Conditions").foregroundColor(.appAccent))
                        .font(.system(size: 12)).multilineTextAlignment(.center).padding(.top, 6)
                }
                .padding(.horizontal, 24).padding(.bottom, 48)
            }
        }
    }
}
