import SwiftUI
import UIKit

// MARK: - Data

enum GymSizeOption: String, CaseIterable, Identifiable {
    case large       = "Large Gym"
    case small       = "Small Gym"
    case garage      = "Garage Gym"
    case home        = "At Home"
    case noEquipment = "Without Equipment"
    case custom      = "Custom"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .large:       return "Full fitness clubs such as Anytime, Planet Fitness, Golds, 24-Hour, Equinox."
        case .small:       return "Compact public gyms with limited equipment."
        case .garage:      return "Barbells, squat rack, dumbbells, etc."
        case .home:        return "Limited equipment such as bands and dumbbells."
        case .noEquipment: return "Workout anywhere with bodyweight only exercises."
        case .custom:      return "Start from scratch and build your own equipment list."
        }
    }
}

// MARK: - View

struct NewOnboardingFlow_GymSizeStep: View {
    let model: NewOnboardingFlowViewModel

    @State private var selected: GymSizeOption? = nil
    @State private var appeared = false

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                gymEquipmentNavBar(
                    onBack: model.goBack,
                    onSkip: { model.skipGymStep() }
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Where will you Work Out?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.primary)

                            Text("We'll compile your equipment list based on the location you pick.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(duration: 0.6), value: appeared)

                        optionList
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(duration: 0.6).delay(0.1), value: appeared)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
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

    // MARK: - Option list (single glass container with dividers)

    private var optionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(GymSizeOption.allCases.enumerated()), id: \.element.id) { index, option in
                gymSizeRow(option)

                if index < GymSizeOption.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.09))
                        .frame(height: 0.5)
                        .padding(.leading, 16)
                }
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    // MARK: - Option row

    private func gymSizeRow(_ option: GymSizeOption) -> some View {
        let isSelected = selected == option
        return Button {
            haptic.impactOccurred()
            withAnimation(.snappy(duration: 0.18)) { selected = option }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.rawValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(option.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.appAccent : .secondary)
                    .animation(.snappy(duration: 0.18), value: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                guard let sel = selected else { return }
                model.pickGymSize(sel.rawValue)
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
            .disabled(selected == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(Color.appBg)
        }
    }
}

// MARK: - Shared nav bar (used by both gym equipment screens)

@ViewBuilder
func gymEquipmentNavBar(onBack: @escaping () -> Void, onSkip: @escaping () -> Void) -> some View {
    HStack {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
        }
        .buttonStyle(.glass)

        Spacer()

        Text("Available Equipment")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.primary)

        Spacer()

        Button("Skip", action: onSkip)
            .buttonStyle(.glass)
            .font(.system(size: 14, weight: .semibold))
    }
}

// MARK: - Preview

#Preview("Gym Size Step") {
    ZStack {
        AppBackground()
        NewOnboardingFlow_GymSizeStep(model: NewOnboardingFlowViewModel())
    }
    .preferredColorScheme(.dark)
}
