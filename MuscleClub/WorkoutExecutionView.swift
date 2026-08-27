import SwiftUI

// MARK: - Active Workout (full-screen, launched from Start Workout)
struct ActiveWorkoutView: View {
    let workout: WorkoutDay
    @Binding var isPresented: Bool

    @Environment(AppState.self) var appState

    @State private var elapsedSeconds = 0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var selectedExercise: Exercise? = nil
    @State private var showFinishSheet = false
    @State private var showSummary = false

    var workoutStore: WorkoutStore { appState.workoutStore }

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

            // Finish sheet slides up when stop is tapped
            if showFinishSheet {
                WorkoutFinishOverlay(
                    workout: workout,
                    elapsedSeconds: elapsedSeconds,
                    workoutStore: workoutStore,
                    onResume: {
                        withAnimation(.spring(response: 0.4)) { showFinishSheet = false }
                    },
                    onFinish: {
                        timerTask?.cancel()
                        withAnimation(.spring(response: 0.4)) { showFinishSheet = false }
                        showSummary = true
                    },
                    onDiscard: {
                        timerTask?.cancel()
                        isPresented = false
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
            }
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
            NavigationStack {
                ExerciseSetupView(exercise: ex, workoutStore: workoutStore)
            }
        }
        .fullScreenCover(isPresented: $showSummary) {
            WorkoutSummaryView(
                workout: workout,
                elapsedSeconds: elapsedSeconds,
                workoutStore: workoutStore,
                onDone: { isPresented = false }
            )
        }
        .statusBarHidden()
    }

    // MARK: - Top bar with timer
    var topBar: some View {
        HStack {
            Button {
                timerTask?.cancel()
                isPresented = false
            } label: {
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
        let logged = workoutStore.totalSetsLogged(for: ex)
        let total  = ex.sets
        let done   = logged >= total && logged > 0
        let green  = Color(red: 0.2, green: 0.85, blue: 0.45)

        return HStack(spacing: 14) {
            ZStack {
                Image(systemName: done ? "checkmark" : ex.sfSymbol)
                    .font(.system(size: done ? 22 : 26))
                    .foregroundColor(done ? green : ex.isFocus ? .appAccent : .secondary)
            }
            .frame(width: 70, height: 70)
            .glassEffect(
                done       ? .regular.tint(Color.green) :
                ex.isFocus ? .regular.tint(.appAccent)  : .regular,
                in: .rect(cornerRadius: 14)
            )

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

                if logged > 0 {
                    Text("\(logged)/\(total) sets logged")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(done ? green : .appAccent)
                }
            }

            Spacer()

            Image(systemName: done ? "checkmark.circle.fill" : "ellipsis")
                .font(.system(size: 14))
                .foregroundStyle(done ? AnyShapeStyle(green) : AnyShapeStyle(Color.secondary.opacity(0.4)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Floating stop button
    var floatingStopButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) { showFinishSheet = true }
        } label: {
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

#Preview {
    let state = AppState()
    state.onboardingComplete = true
    return ActiveWorkoutView(workout: WorkoutDay.pushDay, isPresented: .constant(true))
        .environment(state)
        .preferredColorScheme(.dark)
}
