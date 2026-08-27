import SwiftUI

// MARK: - Step data

struct NewOnboardingStep: Identifiable {
    let id: Int
    enum Input {
        case options([String])
        case textField(placeholder: String, numeric: Bool = false)
        case numberPicker(min: Int, max: Int, unit: String, defaultValue: Int)
        case stringPicker([String])
    }
    let icon: String
    let title: String
    let subtitle: String
    let input: Input
}

let worldClassIcelandLocations: [String] = [
    "Smáralind", "Laugar", "Mjódd", "Suðurlandsbraut",
    "Grafarvogur", "Breiðholt", "Garðabær", "Hafnarfjörður",
    "Mosfellsbær", "Álftanes", "Keflavík", "Akureyri",
    "Selfoss", "Borgarnes", "Ísafjörður", "Egilsstaðir",
    "Sauðárkrókur", "Hvolsvöllur", "Höfn í Hornafirði", "Vík"
]

let newOnboardingSteps: [NewOnboardingStep] = [
    .init(id: 0, icon: "target",
          title: "What's your top fitness goal?",
          subtitle: "We'll build your entire plan around this.",
          input: .options(["Lift heavier", "Build more muscle", "Get lean and defined", "Lose weight"])),
    .init(id: 1, icon: "person.fill",
          title: "What's your full name?",
          subtitle: "So we can personalise your experience.",
          input: .textField(placeholder: "Your name")),
    .init(id: 2, icon: "location.fill",
          title: "Where are you based?",
          subtitle: "Helps us show you relevant options.",
          input: .textField(placeholder: "City or town")),
    .init(id: 3, icon: "scalemass.fill",
          title: "What's your current weight?",
          subtitle: "In kilograms, approximate.",
          input: .numberPicker(min: 40, max: 200, unit: "kg", defaultValue: 80)),
    .init(id: 4, icon: "ruler.fill",
          title: "What's your height?",
          subtitle: "In centimetres.",
          input: .numberPicker(min: 140, max: 220, unit: "cm", defaultValue: 175)),
    .init(id: 5, icon: "flag.fill",
          title: "What's your goal weight?",
          subtitle: "In kilograms, approximate.",
          input: .numberPicker(min: 40, max: 200, unit: "kg", defaultValue: 75)),
    .init(id: 6, icon: "dumbbell.fill",
          title: "Which best describes your current training routine?",
          subtitle: "Be honest — we'll calibrate from where you are.",
          input: .options(["I'm just getting started", "I struggle with consistency",
                           "I'm coming back after a break", "I strength train consistently"])),
    .init(id: 7, icon: "calendar",
          title: "How long have you been training?",
          subtitle: "Including any past training history.",
          input: .options(["Less than 6 months", "6 months – 1 year", "1–3 years", "3+ years"])),
    .init(id: 8, icon: "sportscourt.fill",
          title: "Have you played any sports before?",
          subtitle: "Sports background shapes how fast you adapt.",
          input: .options(["Yes", "No"])),
    .init(id: 9, icon: "figure.run",
          title: "Are you currently playing any sports?",
          subtitle: "We'll factor this into your recovery planning.",
          input: .options(["Yes", "No"])),
    .init(id: 10, icon: "heart.fill",
          title: "What type of exercise do you enjoy most?",
          subtitle: "We'll lean into what you love.",
          input: .options(["Weight training", "Cardio", "Both equally", "Group classes / team sports"])),
    .init(id: 11, icon: "building.2.fill",
          title: "Where do you primarily plan to train?",
          subtitle: "Your plan will be built around your setup.",
          input: .options(["At a large commercial gym", "At a small gym", "In a garage gym",
                           "At home with limited equipment", "I don't have any equipment"])),
    .init(id: 12, icon: "mappin.circle.fill",
          title: "Which gym do you train at?",
          subtitle: "Select your main gym.",
          input: .options(["World Class", "SportHúsið", "Katla Fitnes", "Other"])),
    .init(id: 13, icon: "map.fill",
          title: "Which World Class location?",
          subtitle: "Pick the one you visit most often.",
          input: .stringPicker(worldClassIcelandLocations)),
    .init(id: 14, icon: "repeat",
          title: "How many days a week can you train?",
          subtitle: "Be realistic — consistency beats intensity.",
          input: .options(["1–2 days a week", "3 days a week", "4 days a week",
                           "5 days a week", "6+ days a week"])),
    .init(id: 15, icon: "clock.fill",
          title: "How long do you want your workouts to be?",
          subtitle: "We'll structure sessions to fit your schedule.",
          input: .options(["30–45 minutes", "45–60 minutes", "60–75 minutes", "75+ minutes"])),
    .init(id: 16, icon: "briefcase.fill",
          title: "Are you physically active at work?",
          subtitle: "Daily movement affects your recovery needs.",
          input: .options(["Mostly sedentary (desk job)", "On my feet, light movement",
                           "Very active (physical labor)"])),
    .init(id: 17, icon: "cross.fill",
          title: "Any injuries or health conditions?",
          subtitle: "We'll work around anything you flag.",
          input: .options(["None", "Yes — minor injury or pain", "Yes — significant issue"])),
    .init(id: 18, icon: "pills.fill",
          title: "Have you ever used supplements?",
          subtitle: "Helps us tailor recovery and nutrition guidance.",
          input: .options(["Yes", "No"])),
    .init(id: 19, icon: "fork.knife",
          title: "How has your diet been recently?",
          subtitle: "No judgment — we'll work from where you are.",
          input: .options(["Pretty poor", "Could be better", "Decent", "Very clean and consistent"])),
    .init(id: 20, icon: "exclamationmark.triangle.fill",
          title: "Any food intolerances or allergies?",
          subtitle: "Select the one that applies most.",
          input: .options(["None", "Lactose intolerant", "Gluten-free", "Nut allergy", "Other"])),
    .init(id: 21, icon: "clock.arrow.circlepath",
          title: "Do you eat regularly throughout the day?",
          subtitle: "Meal timing matters for training performance.",
          input: .options(["Yes, always", "Mostly", "Not really — I skip meals often"])),
    .init(id: 22, icon: "bell.fill",
          title: "Want a workout preview on training days?",
          subtitle: "We'll send a notification before each session.",
          input: .options(["Yes, enable notifications", "Maybe later"])),
    .init(id: 23, icon: "flame.fill",
          title: "Want to track calories burned each workout?",
          subtitle: "Connect Apple Health or input details manually.",
          input: .options(["Yes, connect to Apple Health", "Yes, input details manually", "Maybe later"])),
    .init(id: 24, icon: "megaphone.fill",
          title: "Where did you hear about this coaching?",
          subtitle: "Helps us understand how people find us.",
          input: .options(["Instagram", "A friend or family member", "Google / search", "Other"])),
]

// MARK: - View Model

@Observable
final class NewOnboardingFlowViewModel {
    enum Phase: Equatable {
        case questions(Int)
        case calculating
        case plan
        case socialProof
        case signUp
        case featureShowcase
        case commit
    }

    var phase: Phase = .questions(0)
    var isGoingBack = false
    var answers: [String] = []
    var gymAnswer: String = ""

    // Look up by step ID so the indices stay correct if step order ever changes.
    private var gymStepArrIdx: Int {
        newOnboardingSteps.firstIndex(where: { $0.id == 12 }) ?? 12
    }
    private var wcLocStepArrIdx: Int {
        newOnboardingSteps.firstIndex(where: { $0.id == 13 }) ?? 13
    }

    var questionnaireProgress: Double {
        guard case let .questions(i) = phase else { return 1.0 }
        return Double(i) / Double(newOnboardingSteps.count)
    }

    var firstName: String {
        guard answers.count > 1 else { return "" }
        return answers[1].components(separatedBy: " ").first ?? answers[1]
    }

    func pick(_ answer: String) {
        isGoingBack = false
        guard case let .questions(i) = phase else { return }
        if i == gymStepArrIdx { gymAnswer = answer }
        answers.append(answer)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            var next = i + 1
            // Skip the World Class location step if the user picked a different gym.
            if i == gymStepArrIdx && answer != "World Class" {
                next = wcLocStepArrIdx + 1
            }
            phase = next < newOnboardingSteps.count ? .questions(next) : .calculating
        }
    }

    func advance() {
        isGoingBack = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            switch phase {
            case .questions(let i):
                let next = i + 1
                phase = next < newOnboardingSteps.count ? .questions(next) : .calculating
            case .calculating:      phase = .plan
            case .plan:             phase = .socialProof
            case .socialProof:      phase = .signUp
            case .signUp:           phase = .featureShowcase
            case .featureShowcase:  phase = .commit
            case .commit:           break
            }
        }
    }

    func goBack() {
        isGoingBack = true
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            guard case let .questions(i) = phase, i > 0 else { return }
            if !answers.isEmpty { answers.removeLast() }
            var prev = i - 1
            // Skip back over the World Class location step if gym isn't World Class.
            if prev == wcLocStepArrIdx && gymAnswer != "World Class" {
                prev = gymStepArrIdx
            }
            phase = .questions(prev)
        }
    }
}

// MARK: - Coordinator

struct NewOnboardingFlowView: View {
    @State private var model = NewOnboardingFlowViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AppBackground()
            screenContent
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.phase)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch model.phase {
        case .questions(let i):
            NewOnboardingFlow_QuestionScreen(model: model, step: newOnboardingSteps[i])
                .id(i)
                .transition(slideTransition)
        case .calculating:
            NewOnboardingFlow_CalculatingScreen(model: model)
                .transition(.opacity)
        case .plan:
            NewOnboardingFlow_PlanScreen(model: model)
                .transition(slideTransition)
        case .socialProof:
            NewOnboardingFlow_SocialProofScreen(model: model)
                .transition(.opacity)
        case .signUp:
            SignUpView { model.advance() }
                .transition(slideTransition)
        case .featureShowcase:
            NewOnboardingFlow_FeatureShowcaseScreen(model: model)
                .transition(.opacity)
        case .commit:
            NewOnboardingFlow_CommitStepView { appState.onboardingComplete = true }
                .transition(.opacity)
        }
    }

    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: model.isGoingBack ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: model.isGoingBack ? .trailing : .leading).combined(with: .opacity)
        )
    }
}
