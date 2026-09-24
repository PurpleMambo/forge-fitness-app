import SwiftUI
import StoreKit

struct MuscleClubPaywallView: View {
    let onDismiss: () -> Void
    var onboardingName: String = ""
    var onboardingGoal: String = ""
    var onboardingCurrentWeight: String = ""
    var onboardingGoalWeight: String = ""
    var goalSpeed: String = "Balanced"

    @Environment(StoreVM.self) private var storeVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var didComplete = false
    @State private var showOfferCodeRedemption = false

    enum PaywallPlan { case yearly, weekly }

    // MARK: - Products

    private var yearlyProduct: Product? {
        storeVM.subscriptions.first { $0.id == "themuscleclub.subscription.yearly" }
    }

    private var weeklyProduct: Product? {
        storeVM.subscriptions.first { $0.id == "themuscleclub.subscription.weekly" }
    }

    private var selectedProduct: Product? {
        selectedPlan == .yearly ? yearlyProduct : weeklyProduct
    }

    private var yearlyHasTrial: Bool {
        yearlyProduct?.subscription?.introductoryOffer != nil
    }

    private var yearlyMonthlyEquivalent: String {
        guard let p = yearlyProduct else { return "$8.25" }
        let monthly = NSDecimalNumber(decimal: p.price).doubleValue / 12.0
        return String(format: "$%.2f", monthly)
    }

    private var yearlyDisplayPrice: String { yearlyProduct?.displayPrice ?? "$99.00" }
    private var weeklyDisplayPrice: String { weeklyProduct?.displayPrice ?? "$3.99" }

    // MARK: - Personalization

    private var firstName: String {
        let first = onboardingName.components(separatedBy: " ").first ?? onboardingName
        return first.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var goalTimelineWeeks: Int {
        switch goalSpeed {
        case "Fast": return 8
        case "Slow": return 20
        default: return 12
        }
    }

    private var projectedDate: String {
        guard let date = Calendar.current.date(byAdding: .weekOfYear, value: goalTimelineWeeks, to: Date()) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }

    private var currentWeightVal: Int {
        Int(onboardingCurrentWeight.components(separatedBy: " ").first ?? "") ?? 0
    }

    private var goalWeightVal: Int {
        Int(onboardingGoalWeight.components(separatedBy: " ").first ?? "") ?? 0
    }

    private var goalPrediction: String {
        switch onboardingGoal {
        case "Lift heavier":
            return "Your strength will improve noticeably in \(goalTimelineWeeks) weeks — by \(projectedDate)."
        case "Build more muscle":
            let diff = goalWeightVal - currentWeightVal
            if diff > 0 {
                return "You're on track to gain \(diff) kg of lean muscle by \(projectedDate)."
            }
            return "You'll build serious size and strength by \(projectedDate)."
        case "Get lean and defined":
            return "You'll be visibly leaner and defined by \(projectedDate)."
        case "Lose weight":
            let diff = currentWeightVal - goalWeightVal
            if diff > 0 {
                return "You can drop \(diff) kg, reaching \(goalWeightVal) kg by \(projectedDate)."
            }
            return "You'll hit your goal weight by \(projectedDate)."
        default:
            return "Your transformation starts the moment you begin."
        }
    }

    private var goalIcon: String {
        switch onboardingGoal {
        case "Lift heavier":         return "dumbbell.fill"
        case "Build more muscle":    return "figure.strengthtraining.traditional"
        case "Get lean and defined": return "flame.fill"
        case "Lose weight":          return "scalemass.fill"
        default:                     return "star.fill"
        }
    }

    // MARK: - Features

    private let features: [(icon: String, text: String)] = [
        ("bolt.fill",                           "Personalized training plan"),
        ("chart.line.uptrend.xyaxis",           "Auto progressive overload"),
        ("play.rectangle.fill",                 "Video exercise guides"),
        ("arrow.trianglehead.2.clockwise",      "Recovery-aware scheduling"),
        ("chart.bar.fill",                      "Workout history & stats"),
        ("figure.strengthtraining.traditional", "Unlimited workouts"),
        ("medal.fill",                          "Priority coach support"),
    ]

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection(geo: geo)

                        VStack(spacing: 16) {
                            if !onboardingGoal.isEmpty {
                                goalCard
                            }
                            planSection
                            featuresSection
                            finePrint.padding(.top, 4)
                            legalRow.padding(.top, 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 160)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)

            pinnedCTABar
        }
        .ignoresSafeArea()
        .onChange(of: storeVM.hasActiveSubscription) { _, active in
            if active { complete() }
        }
        .alert("Purchase failed", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
        .offerCodeRedemption(isPresented: $showOfferCodeRedemption) { result in
            if case .success = result {
                Task {
                    await storeVM.updateCustomerProductStatus()
                    if storeVM.hasActiveSubscription { complete() }
                }
            }
        }
    }

    // MARK: - Completion

    private func complete() {
        guard !didComplete else { return }
        didComplete = true
        onDismiss()
    }

    // MARK: - Hero

    private func heroSection(geo: GeometryProxy) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image("gillz_paywall")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height * 0.60)
                .clipped()
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [.black.opacity(0.35), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 140)
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.50),
                            .init(color: .white.opacity(0.28), location: 0.82),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 14) {
                // Badge — always shows over the image so white text reads well here
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.appAccent)
                    Text("MUSCLE CLUB PRO")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2.5)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .glassEffect(.regular.tint(.appAccent), in: .rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    if !firstName.isEmpty {
                        Text("YOUR PLAN IS READY,")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.65) : .black.opacity(0.55))
                            .tracking(2)
                    }
                    Text(firstName.isEmpty ? "GET STARTED." : firstName.uppercased() + ".")
                        .font(.system(size: 52, weight: .black))
                        .italic()
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .tracking(-0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .frame(height: geo.size.height * 0.60)
    }

    // MARK: - Goal card

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: goalIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 28, height: 28)
                    .glassEffect(.regular.tint(.appAccent), in: .circle)

                Text("YOUR PROJECTED RESULT")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Color.appGold)
                    .tracking(1.5)
            }

            Text(goalPrediction)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 5) {
                Image(systemName: "figure.run")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appAccent)
                Text("\(goalTimelineWeeks)-week plan · \(goalSpeed) pace")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(.appAccent.opacity(0.12)), in: .rect(cornerRadius: 20))
    }

    // MARK: - Plan cards

    private var planSection: some View {
        VStack(spacing: 10) {
            // Extra top padding so the floating badge has room above the card
            planCard(
                plan: .yearly,
                title: "Annual",
                badge: yearlyHasTrial ? "3 DAYS FREE" : "BEST VALUE",
                priceMain: yearlyDisplayPrice,
                priceSub: "per year",
                detail: yearlyHasTrial
                    ? "3 days free · ≈ \(yearlyMonthlyEquivalent)/month"
                    : "≈ \(yearlyMonthlyEquivalent)/month"
            )
            .padding(.top, 10)

            planCard(
                plan: .weekly,
                title: "Weekly",
                badge: nil,
                priceMain: weeklyDisplayPrice,
                priceSub: "per week",
                detail: "No commitment. Cancel anytime."
            )
        }
    }

    private func planCard(
        plan: PaywallPlan,
        title: String,
        badge: String?,
        priceMain: String,
        priceSub: String,
        detail: String
    ) -> some View {
        let selected = selectedPlan == plan
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 14) {
                // Radio indicator — accent fill + white dot when selected
                ZStack {
                    Circle()
                        .stroke(.primary.opacity(selected ? 0 : 0.25), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle().fill(Color.appAccent).frame(width: 22, height: 22)
                        Circle().fill(.white).frame(width: 9, height: 9)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(selected ? Color.white.opacity(0.75) : Color.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(priceMain)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                    Text(priceSub)
                        .font(.system(size: 11))
                        .foregroundStyle(selected ? Color.white.opacity(0.70) : Color.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        // Unselected: subtle white-tinted glass so the card reads on any background.
        // Selected: brand-accent tint for clear visual weight.
        .glassEffect(
            selected
                ? .regular.tint(.appAccent)
                : .regular.tint(colorScheme == .dark ? .white.opacity(0.08) : .clear),
            in: .rect(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    selected ? Color.appAccent.opacity(0.85) : .primary.opacity(0.12),
                    lineWidth: selected ? 2 : 1
                )
        )
        // Badge floats above the card's top-trailing corner — not clipped by any container
        .overlay(alignment: .topTrailing) {
            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.88, blue: 0.38),
                                    Color(red: 0.90, green: 0.62, blue: 0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                    .shadow(color: .black.opacity(0.30), radius: 2, x: 0, y: 2)
                    .shadow(color: Color(red: 0.90, green: 0.62, blue: 0.04).opacity(0.45), radius: 5, x: 0, y: 3)
                    .offset(x: -14, y: -10)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: selected)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Everything included")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.appGold)
                .padding(.bottom, 14)

            ForEach(Array(features.enumerated()), id: \.offset) { i, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 28, height: 28)
                        .glassEffect(.regular.tint(.appAccent), in: .circle)

                    Text(feature.text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.appAccent)
                }
                .padding(.vertical, 12)

                if i < features.count - 1 {
                    Rectangle()
                        .fill(.primary.opacity(0.08))
                        .frame(height: 1)
                }
            }
        }
        .padding(18)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    // MARK: - Pinned CTA

    private var pinnedCTABar: some View {
        VStack(spacing: 10) {
            ctaButton.padding(.horizontal, 20)

            if yearlyHasTrial && selectedPlan == .yearly {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.appAccent)
                    Text("No payment due today · then \(yearlyDisplayPrice)/year")
                        .foregroundStyle(.primary)
                }
                .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.appBg.opacity(0), Color.appBg.opacity(0.95), Color.appBg],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var ctaButton: some View {
        let isBusy = isProcessing || storeVM.isLoading
        return Button {
            guard !isBusy else { return }
            guard let product = selectedProduct else { return }
            isProcessing = true
            Task {
                do {
                    let transaction = try await storeVM.purchase(product)
                    isProcessing = false
                    if transaction != nil { complete() }
                } catch {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        } label: {
            ZStack {
                if isBusy {
                    ProgressView().tint(.white)
                } else {
                    // White text on the crimson button is readable in both modes
                    Text(selectedPlan == .yearly && yearlyHasTrial ? "Start free trial" : "Start training")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .buttonStyle(.glassProminent)
        .tint(.appAccent)
        .disabled(isBusy)
    }

    // MARK: - Fine print + legal

    private var finePrint: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.shield").font(.caption)
            Text("Secure payment · Cancel anytime").font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    private var legalRow: some View {
        HStack(spacing: 20) {
            Button {
                Task { await storeVM.refreshEntitlements() }
            } label: {
                Text("Restore purchases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .underline()
            }
            .buttonStyle(.plain)

            Button {
                showOfferCodeRedemption = true
            } label: {
                Text("Redeem code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Dark — with onboarding data") {
    MuscleClubPaywallView(
        onDismiss: {},
        onboardingName: "Gísli",
        onboardingGoal: "Build more muscle",
        onboardingCurrentWeight: "80 kg",
        onboardingGoalWeight: "88 kg",
        goalSpeed: "Balanced"
    )
    .environment(StoreVM())
    .preferredColorScheme(.dark)
}

#Preview("Light — with onboarding data") {
    MuscleClubPaywallView(
        onDismiss: {},
        onboardingName: "Gísli",
        onboardingGoal: "Build more muscle",
        onboardingCurrentWeight: "80 kg",
        onboardingGoalWeight: "88 kg",
        goalSpeed: "Balanced"
    )
    .environment(StoreVM())
    .preferredColorScheme(.light)
}
