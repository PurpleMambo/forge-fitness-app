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

// let worldClassIcelandLocations: [String] = [
//     "Smáralind", "Laugar", "Mjódd", "Suðurlandsbraut",
//     "Grafarvogur", "Breiðholt", "Garðabær", "Hafnarfjörður",
//     "Mosfellsbær", "Álftanes", "Keflavík", "Akureyri",
//     "Selfoss", "Borgarnes", "Ísafjörður", "Egilsstaðir",
//     "Sauðárkrókur", "Hvolsvöllur", "Höfn í Hornafirði", "Vík"
// ]

let newOnboardingSteps: [NewOnboardingStep] = [
    .init(id: 0, icon: "target",
          title: "What's your top fitness goal?",
          subtitle: "We'll build your entire plan around this.",
          input: .options(["Lift heavier", "Build more muscle", "Get lean and defined", "Lose weight"])),
    .init(id: 25, icon: "person.crop.circle",
          title: "What's your biological sex?",
          subtitle: "Used to assign the right training program for you.",
          input: .options(["Male", "Female"])),
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
    // Replaced by GymSizeStep + EquipmentReviewStep custom screens
    // .init(id: 11, icon: "building.2.fill",
    //       title: "Where do you primarily plan to train?",
    //       subtitle: "Your plan will be built around your setup.",
    //       input: .options(["At a large commercial gym", "At a small gym", "In a garage gym",
    //                        "At home with limited equipment", "I don't have any equipment"])),
    // .init(id: 12, icon: "mappin.circle.fill",
    //       title: "Which gym do you train at?",
    //       subtitle: "Select your main gym.",
    //       input: .options(["World Class", "SportHúsið", "Katla Fitnes", "Other"])),
    // .init(id: 13, icon: "map.fill",
    //       title: "Which World Class location?",
    //       subtitle: "Pick the one you visit most often.",
    //       input: .stringPicker(worldClassIcelandLocations)),
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
        case goalSpeed
        case sleep
        case supplements
        case gymSize
        case equipmentReview
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
    var gymSizeAnswer: String = ""
    var selectedEquipment: Set<String> = []
    var goalSpeedAnswer: String = "Balanced"
    var sleepDurationAnswer: String = ""
    var sleepGoalsAnswer: Set<String> = []
    var supplementsAnswer: String = ""

    // Look up by step ID so the indices stay correct if step order ever changes.
    private var exerciseTypeStepArrIdx: Int {
        newOnboardingSteps.firstIndex(where: { $0.id == 10 }) ?? 11
    }
    private var firstPostGymStepArrIdx: Int {
        newOnboardingSteps.firstIndex(where: { $0.id == 14 }) ?? 12
    }
    private var goalWeightStepArrIdx: Int {
        newOnboardingSteps.firstIndex(where: { $0.id == 5 }) ?? 5
    }
    private var injuriesStepArrIdx: Int {
        newOnboardingSteps.firstIndex(where: { $0.id == 17 }) ?? 17
    }
    private var supplementsStepArrIdx: Int {
        newOnboardingSteps.firstIndex(where: { $0.id == 18 }) ?? 18
    }

    var questionnaireProgress: Double {
        guard case let .questions(i) = phase else { return 1.0 }
        return Double(i) / Double(newOnboardingSteps.count)
    }

    var genderAnswer: String {
        guard answers.count > 1 else { return "" }
        return answers[1]
    }

    var selectedProgramId: UUID {
        genderAnswer == "Female"
            ? UUID(uuidString: "a0000000-0000-0000-0000-000000000002")!
            : UUID(uuidString: "a0000000-0000-0000-0000-000000000001")!
    }

    var firstName: String {
        guard answers.count > 2 else { return "" }
        return answers[2].components(separatedBy: " ").first ?? answers[2]
    }

    func pick(_ answer: String) {
        isGoingBack = false
        guard case let .questions(i) = phase else { return }
        answers.append(answer)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            if i == exerciseTypeStepArrIdx {
                phase = .gymSize
            } else if i == goalWeightStepArrIdx {
                phase = .goalSpeed
            } else if i == injuriesStepArrIdx {
                phase = .sleep
            } else {
                let next = i + 1
                phase = next < newOnboardingSteps.count ? .questions(next) : .calculating
            }
        }
    }

    func advance() {
        isGoingBack = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            switch phase {
            case .questions(let i):
                let next = i + 1
                phase = next < newOnboardingSteps.count ? .questions(next) : .calculating
            case .goalSpeed:        phase = .questions(goalWeightStepArrIdx + 1)
            case .sleep:            phase = .supplements
            case .supplements:      phase = .questions(supplementsStepArrIdx + 1)
            case .gymSize:          phase = .equipmentReview
            case .equipmentReview:  phase = .questions(firstPostGymStepArrIdx)
            case .calculating:      phase = .plan
            case .plan:             phase = .socialProof
            case .socialProof:      phase = .signUp
            case .signUp:           phase = .featureShowcase
            case .featureShowcase:  phase = .commit
            case .commit:           break
            }
        }
    }

    func supplementsPick(_ answer: String) {
        isGoingBack = false
        supplementsAnswer = answer
        answers.append(answer)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            phase = .questions(supplementsStepArrIdx + 1)
        }
    }

    func pickGymSize(_ size: String) {
        isGoingBack = false
        gymSizeAnswer = size
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            phase = .equipmentReview
        }
    }

    func skipGymStep() {
        isGoingBack = false
        gymSizeAnswer = ""
        selectedEquipment = []
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            phase = .questions(firstPostGymStepArrIdx)
        }
    }

    func confirmEquipment(_ equipment: Set<String>) {
        isGoingBack = false
        selectedEquipment = equipment
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            phase = .questions(firstPostGymStepArrIdx)
        }
    }

    func goBack() {
        isGoingBack = true
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            switch phase {
            case .questions(let i):
                guard i > 0 else { return }
                if i == firstPostGymStepArrIdx {
                    phase = .equipmentReview
                } else if i == goalWeightStepArrIdx + 1 {
                    phase = .goalSpeed
                } else if i == injuriesStepArrIdx + 1 {
                    phase = .sleep
                } else if i == supplementsStepArrIdx + 1 {
                    if !answers.isEmpty { answers.removeLast() }
                    phase = .supplements
                } else {
                    if !answers.isEmpty { answers.removeLast() }
                    let prev = i - 1
                    phase = .questions(prev)
                }
            case .goalSpeed:
                if !answers.isEmpty { answers.removeLast() }
                phase = .questions(goalWeightStepArrIdx)
            case .sleep:
                if !answers.isEmpty { answers.removeLast() }
                phase = .questions(injuriesStepArrIdx)
            case .supplements:
                phase = .sleep
            case .gymSize:
                if !answers.isEmpty { answers.removeLast() }
                phase = .questions(exerciseTypeStepArrIdx)
            case .equipmentReview:
                phase = .gymSize
            default:
                break
            }
        }
    }
}

// MARK: - Profile payload

// Mirrors the public.profiles table (profiles.sql) — property names are column names.
struct ProfileUpsert: Encodable {
    let user_id: String
    let full_name: String?
    let gender: String?
    let location: String?
    let fitness_goal: String?
    let current_weight_kg: Int?
    let height_cm: Int?
    let goal_weight_kg: Int?
    let goal_speed: String?
    let training_routine: String?
    let training_history: String?
    let played_sports_before: Bool?
    let plays_sports_currently: Bool?
    let exercise_preference: String?
    let gym_size: String?
    let equipment: [String]
    let training_days_per_week: String?
    let workout_duration: String?
    let work_activity: String?
    let injuries: String?
    let used_supplements: String?
    let sleep_duration: String?
    let sleep_goals: [String]
    let diet_quality: String?
    let food_intolerances: String?
    let meal_regularity: String?
    let wants_notifications: String?
    let calorie_tracking: String?
    let referral_source: String?
}

extension NewOnboardingFlowViewModel {
    // answers[] fills 1:1 with newOnboardingSteps order (the supplements screen
    // appends into step id 18's slot via supplementsPick), so a step's answer
    // lives at its index in the steps array.
    private func answer(stepId: Int) -> String? {
        guard let idx = newOnboardingSteps.firstIndex(where: { $0.id == stepId }),
              idx < answers.count else { return nil }
        return answers[idx]
    }

    private func intAnswer(stepId: Int) -> Int? {
        guard let raw = answer(stepId: stepId) else { return nil }
        // Number-picker answers are formatted "80 kg" / "175 cm"
        return Int(raw.components(separatedBy: " ").first ?? "")
    }

    private func boolAnswer(stepId: Int) -> Bool? {
        guard let raw = answer(stepId: stepId) else { return nil }
        return raw == "Yes"
    }

    func profileUpsert(userId: UUID) -> ProfileUpsert {
        ProfileUpsert(
            user_id: userId.uuidString,
            full_name: answer(stepId: 1),
            gender: answer(stepId: 25),
            location: answer(stepId: 2),
            fitness_goal: answer(stepId: 0),
            current_weight_kg: intAnswer(stepId: 3),
            height_cm: intAnswer(stepId: 4),
            goal_weight_kg: intAnswer(stepId: 5),
            goal_speed: goalSpeedAnswer.isEmpty ? nil : goalSpeedAnswer,
            training_routine: answer(stepId: 6),
            training_history: answer(stepId: 7),
            played_sports_before: boolAnswer(stepId: 8),
            plays_sports_currently: boolAnswer(stepId: 9),
            exercise_preference: answer(stepId: 10),
            gym_size: gymSizeAnswer.isEmpty ? nil : gymSizeAnswer,
            equipment: selectedEquipment.sorted(),
            training_days_per_week: answer(stepId: 14),
            workout_duration: answer(stepId: 15),
            work_activity: answer(stepId: 16),
            injuries: answer(stepId: 17),
            used_supplements: answer(stepId: 18),
            sleep_duration: sleepDurationAnswer.isEmpty ? nil : sleepDurationAnswer,
            sleep_goals: sleepGoalsAnswer.sorted(),
            diet_quality: answer(stepId: 19),
            food_intolerances: answer(stepId: 20),
            meal_regularity: answer(stepId: 21),
            wants_notifications: answer(stepId: 22),
            calorie_tracking: answer(stepId: 23),
            referral_source: answer(stepId: 24)
        )
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
        case .goalSpeed:
            NewOnboardingFlow_GoalSpeedScreen(model: model)
                .transition(slideTransition)
        case .sleep:
            NewOnboardingFlow_SleepStep(model: model)
                .transition(slideTransition)
        case .supplements:
            NewOnboardingFlow_SupplementsStep(model: model)
                .transition(slideTransition)
        case .gymSize:
            NewOnboardingFlow_GymSizeStep(model: model)
                .transition(slideTransition)
        case .equipmentReview:
            NewOnboardingFlow_EquipmentReviewStep(model: model)
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
            SignUpView(onComplete: { model.advance() },
                       programId: model.selectedProgramId,
                       onboarding: model)
                .transition(slideTransition)
        case .featureShowcase:
            NewOnboardingFlow_FeatureShowcaseScreen(model: model)
                .transition(.opacity)
        case .commit:
            NewOnboardingFlow_CommitStepView(model: model) { appState.onboardingComplete = true }
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
