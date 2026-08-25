import SwiftUI

// MARK: - Active Workout (full-screen, launched from Start Workout)
struct ActiveWorkoutView: View {
    let workout: WorkoutDay
    @Binding var isPresented: Bool

    @State private var elapsedSeconds = 0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var selectedExercise: Exercise? = nil
    @State private var showExitAlert = false

    var timeString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            VStack(spacing: 0) {
                topBar
                exerciseList
            }

            floatingStopButton
        }
        .onAppear {
            timerTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if !Task.isCancelled { elapsedSeconds += 1 }
                }
            }
        }
        .onDisappear { timerTask?.cancel() }
        .sheet(item: $selectedExercise) { ex in
            ExerciseWorkoutSheet(exercise: ex)
        }
        .alert("End Workout?", isPresented: $showExitAlert) {
            Button("End Workout", role: .destructive) { isPresented = false }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
        .statusBarHidden()
    }

    // MARK: - Top bar with timer
    var topBar: some View {
        HStack {
            Button { showExitAlert = true } label: {
                Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 9, height: 9)
                Text(timeString)
                    .font(.system(size: 34, weight: .heavy).monospacedDigit())
            }

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis").font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    // MARK: - Exercise list
    var exerciseList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(workout.exercises) { ex in
                    Button { selectedExercise = ex } label: {
                        exerciseRow(ex)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
        }
    }

    func exerciseRow(_ ex: Exercise) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Image(systemName: ex.sfSymbol)
                    .font(.system(size: 26))
                    .foregroundColor(ex.isFocus ? .appAccent : .secondary)
            }
            .frame(width: 70, height: 70)
            .glassEffect(ex.isFocus ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                if ex.isFocus {
                    Text("FOCUS EXERCISE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.appGold)
                        .tracking(1)
                }
                Text(ex.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text("\(ex.sets) sets  ·  \(ex.reps) reps  ·  \(ex.weightString) \(ex.weightUnit)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Floating stop button
    var floatingStopButton: some View {
        Button { showExitAlert = true } label: {
            ZStack {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 62, height: 62)
                    .shadow(color: .appAccent.opacity(0.55), radius: 14, y: 5)
                RoundedRectangle(cornerRadius: 5)
                    .fill(.white)
                    .frame(width: 22, height: 22)
            }
        }
        .padding(.bottom, 48)
    }
}

// MARK: - Exercise Workout Sheet (set tracker, opens when tapping exercise during workout)
struct ExerciseWorkoutSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss

    @State private var warmupReps = 8
    @State private var warmupWeight: Double
    @State private var setReps: [Int]
    @State private var setWeights: [Double]
    @State private var showRepsInfo = true

    init(exercise: Exercise) {
        self.exercise = exercise
        _warmupWeight = State(initialValue: (exercise.weight * 0.5).rounded())
        _setReps = State(initialValue: Array(repeating: exercise.reps, count: exercise.sets))
        _setWeights = State(initialValue: Array(repeating: exercise.weight, count: exercise.sets))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    nameAndHowTo
                    infoPills
                    if exercise.isFocus { focusBanner }
                    setGrid
                    if showRepsInfo {
                        repsInfoCard
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                    }
                    Spacer(minLength: 120)
                }
            }

            // Fade + CTA
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, Color.appBg], startPoint: .top, endPoint: .bottom)
                    .frame(height: 40).allowsHitTesting(false)
                Button("Start Workout") { dismiss() }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Hero
    var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            if let resource = exercise.videoResource,
               let url = Bundle.main.videoURL(named: resource) {
                LoopingVideoPlayer(url: url)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.55)],
                            startPoint: .center, endPoint: .bottom)
                    }
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.15, green: 0.10, blue: 0.25), .black],
                        startPoint: .top, endPoint: .bottom))
                    .frame(height: 240)
                    .overlay {
                        Image(systemName: exercise.sfSymbol)
                            .font(.system(size: 72))
                            .foregroundColor(.white.opacity(0.14))
                    }
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)
            .padding(.top, 16).padding(.trailing, 16)
        }
    }

    var nameAndHowTo: some View {
        HStack(alignment: .center) {
            Text(exercise.name)
                .font(.system(size: 22, weight: .heavy))
            Spacer()
            Button {} label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill").font(.system(size: 10))
                    Text("How-To").font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    var infoPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 8) {
                    pillView("timer", "2:00 rest")
                    pillView("chart.bar.fill", "History")
                    pillView("tablecells", "Plate Calculator")
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.top, 14)
    }

    var focusBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11)).foregroundColor(.appAccent)
                Text("Today's Focus Exercise")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.appAccent)
            }
            Text("Part of a set of key lifts you'll repeat with increasing intensity over the next month.")
                .font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(3)
            Button("Customize") {}
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.appAccent)
                .buttonStyle(.plain)
        }
        .padding(14)
        .glassEffect(.regular.tint(.appAccent), in: .rect(cornerRadius: 14))
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    // MARK: - Set grid
    var setGrid: some View {
        VStack(spacing: 0) {
            // Headers
            HStack {
                Spacer().frame(width: 40)
                Text("Reps")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Text("Weight (kg)")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 10)

            setRow(label: "W", reps: $warmupReps, weight: $warmupWeight,
                   hint: "Bar + Plates", isWarmup: true)

            ForEach(0..<exercise.sets, id: \.self) { i in
                setRow(
                    label: "\(i + 1)",
                    reps: Binding(get: { setReps[i] }, set: { setReps[i] = $0 }),
                    weight: Binding(get: { setWeights[i] }, set: { setWeights[i] = $0 }),
                    hint: nil,
                    isWarmup: false
                )
            }
        }
    }

    func setRow(label: String, reps: Binding<Int>, weight: Binding<Double>,
                hint: String?, isWarmup: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isWarmup ? Color.secondary.opacity(0.2) : Color.appAccent.opacity(0.18))
                    .frame(width: 28, height: 28)
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isWarmup ? .secondary : .appAccent)
            }
            .frame(width: 40)

            // Reps box
            Text("\(reps.wrappedValue)")
                .font(.system(size: 26, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .glassEffect(in: .rect(cornerRadius: 10))

            // Weight box
            VStack(spacing: 2) {
                Text(weight.wrappedValue.truncatingRemainder(dividingBy: 1) == 0
                     ? String(format: "%.0f", weight.wrappedValue)
                     : String(format: "%.1f", weight.wrappedValue))
                    .font(.system(size: 26, weight: .bold))
                if let h = hint {
                    Text(h).font(.system(size: 9)).foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .glassEffect(in: .rect(cornerRadius: 10))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 5)
    }

    func pillView(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .glassEffect()
    }

    // MARK: - Reps & Weight info card (shown on first open)
    var repsInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reps and Weight")
                .font(.system(size: 17, weight: .bold))

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Text("1").font(.system(size: 16, weight: .heavy))
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(setReps.first ?? 10)")
                            .font(.system(size: 30, weight: .heavy))
                        Text("REPS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    let w = setWeights.first ?? exercise.weight
                    Text("/ \(w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)) KILOS")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text("These numbers are based on your fitness baseline and previous workout logs. Adjust them freely — as you log more sessions, your recommendations improve automatically.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            HStack {
                Button("Learn More") {}
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                Spacer()
                Button("Got it") {
                    withAnimation(.spring(response: 0.3)) { showRepsInfo = false }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.appAccent)
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ActiveWorkoutView(workout: WorkoutDay.pushDay, isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
