import SwiftUI

// MARK: - Exercise Setup / Active Workout View
// Setup mode (onStartWorkout provided, no workoutStore): shows reps/weight config + "Start Workout".
// Active mode (workoutStore provided): shows per-set logging, rest timer, haptics.
struct ExerciseSetupView: View {
    let exercise: Exercise
    var workout: WorkoutDay? = nil
    var onStartWorkout: (() -> Void)? = nil
    var workoutStore: WorkoutStore? = nil

    @Environment(\.dismiss) var dismiss

    // MARK: State – Setup
    @State private var warmupReps = 8
    @State private var warmupWeight: Double
    @State private var setReps: [Int]
    @State private var setWeights: [Double]
    @State private var showRepsInfo = true
    @State private var isMuted = false
    @State private var isVideoPlaying = true
    @State private var showHowTo = false
    @State private var extraSets = 0

    // MARK: State – Rest Timer
    @State private var isRestTimerActive = false
    @State private var restSecondsLeft = 60
    @State private var restTimerRunning = false
    @State private var restTimerTask: Task<Void, Never>? = nil

    init(exercise: Exercise,
         workout: WorkoutDay? = nil,
         onStartWorkout: (() -> Void)? = nil,
         workoutStore: WorkoutStore? = nil) {
        self.exercise = exercise
        self.workout = workout
        self.onStartWorkout = onStartWorkout
        self.workoutStore = workoutStore
        _warmupWeight = State(initialValue: (exercise.weight * 0.5).rounded())
        _setReps    = State(initialValue: Array(repeating: exercise.reps,   count: exercise.sets))
        _setWeights = State(initialValue: Array(repeating: exercise.weight, count: exercise.sets))
    }

    // MARK: - Computed

    var isActiveWorkout: Bool { workoutStore != nil }

    var totalSets: Int { exercise.sets + extraSets }

    var loggedSets: [LoggedSetEntry] {
        workoutStore?.todayLoggedSets(for: exercise) ?? []
    }

    var allSetsLogged: Bool { loggedSets.count >= totalSets }

    var restTimeString: String {
        String(format: "%d:%02d", restSecondsLeft / 60, restSecondsLeft % 60)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    nameAndHowTo
                    infoPills
                    if exercise.isFocus { focusBanner }

                    if isActiveWorkout {
                        activeSetGrid
                    } else {
                        setGrid
                        if showRepsInfo {
                            repsInfoCard
                                .padding(.horizontal, 18)
                                .padding(.top, 16)
                        }
                    }

                    Spacer(minLength: 120)
                }
            }

            if isRestTimerActive {
                restTimerOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if isActiveWorkout {
                activeBottomCTA
            } else {
                bottomCTA
            }
        }
        .sheet(isPresented: $showHowTo) {
            ExerciseDetailView(exercise: exercise)
        }
        .onChange(of: showHowTo) { _, showing in
            isVideoPlaying = !showing
        }
        .onDisappear {
            stopRestTimer()
        }
    }

    // MARK: - Logging actions

    func logCurrentSet() {
        guard let store = workoutStore, !allSetsLogged else { return }
        let i = loggedSets.count
        guard i < setReps.count, i < setWeights.count else { return }
        dismissKeyboard()
        store.logSet(exercise: exercise, reps: setReps[i], weight: setWeights[i])
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) {
            isRestTimerActive = true
            restSecondsLeft = 60
            restTimerRunning = true
        }
        startRestTimer()
    }

    func logAllSets() {
        guard let store = workoutStore else { return }
        dismissKeyboard()
        let start = loggedSets.count
        for i in start..<totalSets {
            guard i < setReps.count, i < setWeights.count else { break }
            store.logSet(exercise: exercise, reps: setReps[i], weight: setWeights[i])
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) {
            isRestTimerActive = true
            restSecondsLeft = 60
            restTimerRunning = true
        }
        startRestTimer()
    }

    func startRestTimer() {
        restTimerTask?.cancel()
        restTimerTask = Task {
            while !Task.isCancelled && restSecondsLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                restSecondsLeft -= 1
                if restSecondsLeft == 0 {
                    restTimerRunning = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    func stopRestTimer() {
        restTimerTask?.cancel()
        restTimerRunning = false
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    // MARK: - Hero (video, tappable to pause)

    var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            if let resource = exercise.videoResource,
               let url = Bundle.main.videoURL(named: resource) {
                Button { isVideoPlaying.toggle() } label: {
                    LoopingVideoPlayer(url: url, isMuted: isMuted, isPlaying: isVideoPlaying)
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.5)],
                                startPoint: .center, endPoint: .bottom)
                        }
                        .overlay {
                            if !isVideoPlaying {
                                ZStack {
                                    Color.black.opacity(0.25)
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 52))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                        }
                }
                .buttonStyle(.plain)
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

            HStack(spacing: 10) {
                if exercise.videoResource != nil {
                    Button { isMuted.toggle() } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .buttonStyle(.glass)
                }
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(.glass)
            }
            .padding(.top, 16).padding(.trailing, 16)
        }
    }

    var nameAndHowTo: some View {
        HStack(alignment: .center) {
            Text(exercise.name).font(.system(size: 22, weight: .heavy))
            Spacer()
            Button { showHowTo = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill").font(.system(size: 10))
                    Text("How-To").font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 18).padding(.top, 16)
    }

    var infoPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 8) {
                    pillView("timer", "1:00 rest")
                    pillView("chart.bar.fill", "History")
                    pillView("arrow.left.arrow.right", "Replace")
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.top, 14)
    }

    var focusBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(.appAccent)
                Text("Today's Focus Exercise")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.appAccent)
            }
            Text("Part of a set of key lifts you'll repeat with increasing intensity over the next month.")
                .font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(3)
            Button("Customize") {}
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.appAccent).buttonStyle(.plain)
        }
        .padding(14)
        .glassEffect(.regular.tint(.appAccent), in: .rect(cornerRadius: 14))
        .padding(.horizontal, 18).padding(.top, 14)
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

    // MARK: - Active Workout Set Grid

    var activeSetGrid: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Spacer().frame(width: 40)
                Text("Reps")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Text("Weight (\(exercise.weightUnit))")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 10)

            // Logged sets
            ForEach(Array(loggedSets.enumerated()), id: \.offset) { i, entry in
                loggedSetRow(index: i, entry: entry)
            }

            // Active (next to log)
            if !allSetsLogged {
                activeSetRow(index: loggedSets.count)
            }

            // Future sets
            let futureStart = allSetsLogged ? totalSets : (loggedSets.count + 1)
            if futureStart < totalSets {
                ForEach(futureStart..<totalSets, id: \.self) { i in
                    futureSetRow(index: i)
                }
            }

            // Add Set
            Button {
                extraSets += 1
                setReps.append(exercise.reps)
                setWeights.append(exercise.weight)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.appAccent)
                    Text("Add Set")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appAccent)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
    }

    func loggedSetRow(index: Int, entry: LoggedSetEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.85, blue: 0.45))
            }
            .frame(width: 40)

            Text("\(entry.reps)")
                .font(.system(size: 26, weight: .bold))
                .frame(maxWidth: .infinity).frame(height: 56)
                .glassEffect(in: .rect(cornerRadius: 10))

            let wStr = entry.weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", entry.weight)
                : String(format: "%.1f", entry.weight)
            Text(wStr)
                .font(.system(size: 26, weight: .bold))
                .frame(maxWidth: .infinity).frame(height: 56)
                .glassEffect(in: .rect(cornerRadius: 10))
        }
        .padding(.horizontal, 18).padding(.vertical, 5)
    }

    func activeSetRow(index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.22))
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appAccent)
            }
            .frame(width: 40)

            // Reps text field
            VStack(spacing: 3) {
                Text("Reps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("", value: Binding(
                    get: { index < setReps.count ? setReps[index] : exercise.reps },
                    set: { if index < setReps.count { setReps[index] = $0 } }
                ), format: .number)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.22), lineWidth: 1))
            )

            // Weight text field
            VStack(spacing: 3) {
                Text("Weight (\(exercise.weightUnit))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("", value: Binding(
                    get: { index < setWeights.count ? setWeights[index] : exercise.weight },
                    set: { if index < setWeights.count { setWeights[index] = $0 } }
                ), format: .number)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.22), lineWidth: 1))
            )
        }
        .padding(.horizontal, 18).padding(.vertical, 5)
    }

    func futureSetRow(index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)

            Text(index < setReps.count ? "\(setReps[index])" : "\(exercise.reps)")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).frame(height: 56)

            let w = index < setWeights.count ? setWeights[index] : exercise.weight
            Text(w.truncatingRemainder(dividingBy: 1) == 0
                 ? String(format: "%.0f", w)
                 : String(format: "%.1f", w))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).frame(height: 56)
        }
        .padding(.horizontal, 18).padding(.vertical, 5)
        .opacity(0.45)
    }

    // MARK: - Active Bottom CTA (Log Set / Log All Sets)

    var activeBottomCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, Color.appBg], startPoint: .top, endPoint: .bottom)
                .frame(height: 40).allowsHitTesting(false)
            HStack(spacing: 12) {
                Button("Log All Sets") { logAllSets() }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity)
                    .disabled(allSetsLogged)

                Button("Log Set") { logCurrentSet() }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .disabled(allSetsLogged)
            }
            .padding(.horizontal, 18).padding(.bottom, 32)
        }
    }

    // MARK: - Rest Timer Overlay

    var restTimerOverlay: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Rest")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button {
                    stopRestTimer()
                    withAnimation(.spring(response: 0.35)) { isRestTimerActive = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                }
                .buttonStyle(.glass)
            }

            Text(restTimeString)
                .font(.system(size: 60, weight: .heavy).monospacedDigit())
                .foregroundColor(restSecondsLeft <= 10 ? .appAccent : .primary)
                .contentTransition(.numericText())

            HStack(spacing: 36) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    restSecondsLeft = max(0, restSecondsLeft - 10)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    if restTimerRunning {
                        restTimerTask?.cancel()
                        restTimerRunning = false
                    } else {
                        restTimerRunning = true
                        startRestTimer()
                    }
                } label: {
                    Image(systemName: restTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.appAccent)
                }
                .buttonStyle(.plain)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    restSecondsLeft += 10
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Setup Mode Set Grid (warmup + working sets)

    var setGrid: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer().frame(width: 40)
                Text("Reps").font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Text("Weight (kg)").font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 10)

            setRow(label: "W", reps: $warmupReps, weight: $warmupWeight,
                   hint: "Bar + Plates", isWarmup: true)

            ForEach(0..<exercise.sets, id: \.self) { i in
                setRow(
                    label: "\(i + 1)",
                    reps: Binding(get: { setReps[i] }, set: { setReps[i] = $0 }),
                    weight: Binding(get: { setWeights[i] }, set: { setWeights[i] = $0 }),
                    hint: nil, isWarmup: false
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
                Text(label).font(.system(size: 12, weight: .bold))
                    .foregroundColor(isWarmup ? .secondary : .appAccent)
            }
            .frame(width: 40)

            Text("\(reps.wrappedValue)")
                .font(.system(size: 26, weight: .bold))
                .frame(maxWidth: .infinity).frame(height: 58)
                .glassEffect(in: .rect(cornerRadius: 10))

            VStack(spacing: 2) {
                Text(weight.wrappedValue.truncatingRemainder(dividingBy: 1) == 0
                     ? String(format: "%.0f", weight.wrappedValue)
                     : String(format: "%.1f", weight.wrappedValue))
                    .font(.system(size: 26, weight: .bold))
                if let h = hint { Text(h).font(.system(size: 9)).foregroundStyle(.tertiary) }
            }
            .frame(maxWidth: .infinity).frame(height: 58)
            .glassEffect(in: .rect(cornerRadius: 10))
        }
        .padding(.horizontal, 18).padding(.vertical, 5)
    }

    var repsInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reps and Weight").font(.system(size: 17, weight: .bold))

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.08)).frame(width: 36, height: 36)
                    Text("1").font(.system(size: 16, weight: .heavy))
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(setReps.first ?? 10)").font(.system(size: 30, weight: .heavy))
                        Text("REPS").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                    }
                    let w = setWeights.first ?? exercise.weight
                    Text("/ \(w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)) KILOS")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                }
            }

            Text("These numbers are based on your fitness baseline and previous workout logs. Adjust them freely — as you log more sessions, your recommendations improve automatically.")
                .font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(3)

            HStack {
                Button("Learn More") {}.font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary).buttonStyle(.plain)
                Spacer()
                Button("Got it") {
                    withAnimation(.spring(response: 0.3)) { showRepsInfo = false }
                }
                .font(.system(size: 13, weight: .bold)).foregroundColor(.appAccent).buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Setup Mode CTA

    var bottomCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, Color.appBg], startPoint: .top, endPoint: .bottom)
                .frame(height: 40).allowsHitTesting(false)
            Button("Start Workout") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let onStart = onStartWorkout {
                    onStart()
                } else {
                    dismiss()
                }
            }
            .buttonStyle(.glassProminent)
            .tint(.appAccent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18).padding(.bottom, 32)
        }
    }
}

#Preview {
    ExerciseSetupView(exercise: WorkoutDay.pushDay.exercises[0], workout: WorkoutDay.pushDay)
        .preferredColorScheme(.dark)
}

#Preview("Active Workout") {
    let store = WorkoutStore()
    return ExerciseSetupView(
        exercise: WorkoutDay.pushDay.exercises[2],
        workoutStore: store
    )
    .preferredColorScheme(.dark)
}
