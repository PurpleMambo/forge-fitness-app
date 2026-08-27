import SwiftUI
import UIKit

struct NewOnboardingFlow_QuestionScreen: View {
    let model: NewOnboardingFlowViewModel
    let step: NewOnboardingStep

    @State private var textInput = ""
    @State private var selectedOption: String? = nil

    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    private var stepIndex: Int {
        guard case let .questions(i) = model.phase else { return 0 }
        return i
    }

    private var canContinue: Bool {
        switch step.input {
        case .options:    return selectedOption != nil
        case .textField:  return !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // Character limit per field type
    private var charLimit: Int {
        switch step.input {
        case .textField(_, let numeric): return numeric ? 6 : 50
        case .options:                   return 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)

            // All content in ScrollView so keyboard doesn't disrupt the layout
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Icon
                    Image(systemName: step.icon)
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .glassEffect(.regular.tint(.appAccent.opacity(0.35)), in: .circle)

                    // Title
                    Text(step.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtitle
                    Text(step.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.bottom, 4)

                    // Input — options or text field
                    switch step.input {
                    case .options(let opts):
                        VStack(spacing: 10) {
                            ForEach(opts, id: \.self) { opt in
                                optionRow(opt)
                            }
                        }

                    case .textField(let placeholder, let numeric):
                        TextField(placeholder, text: $textInput)
                            .font(.system(size: 22, weight: .semibold))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(numeric ? .never : .words)
                            .keyboardType(numeric ? .decimalPad : .default)
                            .onChange(of: textInput) { _, new in
                                if new.count > charLimit {
                                    textInput = String(new.prefix(charLimit))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .glassEffect(in: .rect(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
        // Single pinned CTA — same for both options and text field modes
        .safeAreaInset(edge: .bottom) {
            ctaPanel
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: model.goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)
            .opacity(stepIndex > 0 ? 1 : 0)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.10)).frame(height: 4)
                    Capsule().fill(Color.appAccent)
                        .frame(width: geo.size.width * model.questionnaireProgress, height: 4)
                        .animation(.spring(response: 0.5), value: model.questionnaireProgress)
                }
            }
            .frame(height: 4)

            Text("\(stepIndex + 1)/\(newOnboardingSteps.count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
                .monospacedDigit()
        }
    }

    // MARK: - Option row (tap to select only — no auto-advance)

    private func optionRow(_ opt: String) -> some View {
        let isSelected = selectedOption == opt
        return Button {
            withAnimation(.snappy(duration: 0.18)) { selectedOption = opt }
        } label: {
            HStack(spacing: 14) {
                Text(opt)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .glassEffect(isSelected ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 18))
        .animation(.snappy(duration: 0.18), value: isSelected)
    }

    // MARK: - Pinned CTA

    private var ctaPanel: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.appBg.opacity(0), Color.appBg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 36)
            .allowsHitTesting(false)

            Button("Continue") {
                haptic.impactOccurred()
                commitAnswer()
            }
            .buttonStyle(.glassProminent)
            .tint(.appAccent)
            .frame(maxWidth: .infinity)
            .disabled(!canContinue)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(Color.appBg)
        }
    }

    // MARK: - Commit

    private func commitAnswer() {
        switch step.input {
        case .options:
            guard let opt = selectedOption else { return }
            selectedOption = nil
            model.pick(opt)
        case .textField:
            let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            textInput = ""
            model.pick(trimmed)
        }
    }
}
