import SwiftUI

// MARK: - Workout Finish Overlay
// Slides up over the dimmed active workout view when the user taps the stop button.
struct WorkoutFinishOverlay: View {
    let workout: WorkoutDay
    let elapsedSeconds: Int
    let workoutStore: WorkoutStore
    var onResume: () -> Void
    var onFinish: () -> Void
    var onDiscard: () -> Void = {}

    @State private var syncAppleHealth = false
    @State private var postStrava      = false
    @State private var postFitbit      = false

    // MARK: - Computed stats

    var durationString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    var exercisesLogged: Int {
        workout.exercises.filter { workoutStore.totalSetsLogged(for: $0) > 0 }.count
    }

    var totalVolume: Double {
        workout.exercises.reduce(0.0) { total, ex in
            total + workoutStore.todayLoggedSets(for: ex)
                .reduce(0.0) { $0 + Double($1.reps) * $1.weight }
        }
    }

    var volumeString: String {
        totalVolume.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f kg", totalVolume)
            : String(format: "%.1f kg", totalVolume)
    }

    var caloriesEstimate: Int { Int(totalVolume * 0.11) }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimming backdrop — tapping it resumes the workout
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onResume() }

            // Dismiss (X) pinned to top-trailing — exits the workout without logging
            VStack {
                HStack {
                    Spacer()
                    Button { onDiscard() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .buttonStyle(.glass)
                    .padding(.trailing, 18)
                    .padding(.top, 56)
                }
                Spacer()
            }

            // Summary panel
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 38, height: 4)
                    .padding(.top, 12)

                VStack(spacing: 20) {
                    // Title
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Great work!")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.appAccent)
                            Text("Log your workout?")
                                .font(.system(size: 22, weight: .bold))
                        }
                        Spacer()
                    }

                    // Stats row — four glass chips
                    HStack(spacing: 8) {
                        statChip(label: "DURATION",  value: durationString,             icon: "timer")
                        statChip(label: "EXERCISES", value: "\(exercisesLogged)",        icon: "dumbbell.fill")
                        statChip(label: "VOLUME",    value: volumeString,                icon: "scalemass.fill")
                        statChip(label: "CALORIES",  value: "\(caloriesEstimate) kcal",  icon: "flame.fill")
                    }

                    // Integration toggles
                    VStack(spacing: 0) {
                        toggleRow(
                            icon: "heart.fill",
                            color: Color(red: 0.90, green: 0.20, blue: 0.35),
                            label: "Apple Health",
                            value: $syncAppleHealth
                        )
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.leading, 54)
                        toggleRow(
                            icon: "bolt.fill",
                            color: Color(red: 0.98, green: 0.42, blue: 0.08),
                            label: "Strava",
                            value: $postStrava
                        )
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.leading, 54)
                        toggleRow(
                            icon: "circle.grid.3x3.fill",
                            color: Color(red: 0.0, green: 0.60, blue: 0.85),
                            label: "Fitbit",
                            value: $postFitbit
                        )
                    }
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))

                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Resume") { onResume() }
                            .buttonStyle(.glass)
                            .frame(maxWidth: .infinity)

                        Button("Log Workout") {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onFinish()
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.appAccent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Sub-views

    func statChip(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.appAccent)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    func toggleRow(icon: String, color: Color, label: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 15))
            Spacer()
            Toggle("", isOn: value)
                .labelsHidden()
                .tint(.appAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    let state = AppState()
    return ZStack {
        AppBackground()
        WorkoutFinishOverlay(
            workout: WorkoutDay.pushDay,
            elapsedSeconds: 935,
            workoutStore: state.workoutStore,
            onResume: {},
            onFinish: {}
        )
    }
    .preferredColorScheme(.dark)
}
