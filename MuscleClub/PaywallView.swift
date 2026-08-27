import SwiftUI
import StoreKit

struct MuscleClubPaywallView: View {
    let onDismiss: () -> Void

    @Environment(StoreVM.self) private var storeVM
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var didComplete = false
    @State private var showOfferCodeRedemption = false
    @Namespace private var planNS

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
        guard let p = yearlyProduct else { return "$3.33" }
        let monthly = NSDecimalNumber(decimal: p.price).doubleValue / 12.0
        return String(format: "$%.2f", monthly)
    }

    private var yearlyDisplayPrice: String {
        yearlyProduct?.displayPrice ?? "$39.99"
    }

    private var weeklyDisplayPrice: String {
        weeklyProduct?.displayPrice ?? "$1.99"
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

            RadialGradient(
                colors: [Color.appAccent.opacity(0.22), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 72)

                    planSection
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    featuresSection
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                    finePrint
                        .padding(.top, 18)

                    legalRow
                        .padding(.top, 8)
                        .padding(.bottom, 180)
                }
            }

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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("MUSCLE CLUB")
                .font(.system(size: 22, weight: .black)).tracking(8)
                .foregroundColor(.white.opacity(0.9))

            Text("PRO")
                .font(.system(size: 12, weight: .heavy)).tracking(4)
                .foregroundColor(.appAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(.appAccent), in: .rect(cornerRadius: 16))

            VStack(spacing: 4) {
                Text("Unlock your full")
                Text("training potential")
            }
            .font(.system(size: 32, weight: .heavy))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.top, 6)

            Text("Join athletes who train smarter, not harder.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Plan Cards

    private var planSection: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 12) {
                planCard(
                    plan: .yearly,
                    title: "Annual",
                    badge: yearlyHasTrial ? "3 DAYS FREE" : "BEST VALUE",
                    priceMain: yearlyMonthlyEquivalent,
                    priceSub: "per month",
                    detail: yearlyHasTrial
                        ? "Free for 3 days, then \(yearlyDisplayPrice)/yr"
                        : "\(yearlyDisplayPrice) billed yearly"
                )

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
                ZStack {
                    Circle()
                        .stroke(.white.opacity(selected ? 0 : 0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle().fill(Color.appAccent).frame(width: 22, height: 22)
                        Circle().fill(.white).frame(width: 9, height: 9)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.62))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(priceMain)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(priceSub)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .glassEffect(selected ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 18))
            .glassEffectID(plan == .yearly ? "plan-yearly" : "plan-weekly", in: planNS)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        selected ? Color.appAccent.opacity(0.7) : .white.opacity(0.10),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.appAccent))
                        .offset(x: -14, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: selected)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Everything included")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appGold)
                .padding(.bottom, 16)

            ForEach(Array(features.enumerated()), id: \.offset) { i, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appAccent)
                        .frame(width: 28, height: 28)
                        .glassEffect(.regular.tint(.appAccent), in: .circle)

                    Text(feature.text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appAccent)
                }
                .padding(.vertical, 12)

                if i < features.count - 1 {
                    Rectangle()
                        .fill(.white.opacity(0.08))
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
            ctaButton
                .padding(.horizontal, 20)

            if yearlyHasTrial && selectedPlan == .yearly {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.appAccent)
                    Text("No payment due today")
                        .foregroundColor(.white)
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
                startPoint: .top,
                endPoint: .bottom
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
                    // complete() if purchase returned a transaction directly,
                    // onChange handles the case where hasActiveSubscription fires first.
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
                    Text(selectedPlan == .yearly && yearlyHasTrial ? "Start free trial" : "Start training")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
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
            Image(systemName: "lock.shield")
                .font(.caption)
            Text("Secure payment · Cancel anytime")
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }

    private var legalRow: some View {
        HStack(spacing: 20) {
            Button {
                Task { await storeVM.refreshEntitlements() }
            } label: {
                Text("Restore purchases")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .underline()
            }
            .buttonStyle(.plain)

            Button {
                showOfferCodeRedemption = true
            } label: {
                Text("Redeem code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MuscleClubPaywallView(onDismiss: {})
        .environment(StoreVM())
}
