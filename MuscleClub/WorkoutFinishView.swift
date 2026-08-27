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
            Color.black.opacity(0.6)
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
                // Handle
                Capsule()
                    .fill(.white.opacity(0.18))
                    .frame(width: 38, height: 4)
                    .padding(.top, 12)

                VStack(spacing: 0) {
                    // Title row
                    HStack(alignment: .center) {
                        Text("Finish and log your workout?")
                            .font(.system(size: 19, weight: .bold))
                        Spacer()
                        Button {} label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 20)

                    // Stats bar
                    HStack(spacing: 0) {
                        statColumn(label: "DURATION",  value: durationString)
                        statDivider()
                        statColumn(label: "EXERCISES", value: "\(exercisesLogged)")
                        statDivider()
                        statColumn(label: "VOLUME",    value: volumeString)
                        statDivider()
                        statColumn(label: "CALORIES",  value: "\(caloriesEstimate) kcal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // Divider
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.top, 20)

                    // Integration toggles
                    VStack(spacing: 0) {
                        toggleRow(
                            icon: "heart.fill",
                            color: Color(red: 0.90, green: 0.20, blue: 0.35),
                            label: "Sync to Apple Health",
                            value: $syncAppleHealth
                        )
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.leading, 38)
                        toggleRow(
                            icon: "bolt.fill",
                            color: Color(red: 0.98, green: 0.42, blue: 0.08),
                            label: "Post to Strava",
                            value: $postStrava
                        )
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.leading, 38)
                        toggleRow(
                            icon: "circle.grid.3x3.fill",
                            color: Color(red: 0.0, green: 0.60, blue: 0.85),
                            label: "Post to Fitbit",
                            value: $postFitbit
                        )
                    }
                    .padding(.top, 4)

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
                    .padding(.top, 24)
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(red: 0.08, green: 0.05, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    // MARK: - Sub-views

    func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    func statDivider() -> some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(width: 1, height: 34)
    }

    func toggleRow(icon: String, color: Color, label: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24, alignment: .center)
            Text(label)
                .font(.system(size: 15))
            Spacer()
            Toggle("", isOn: value)
                .labelsHidden()
                .tint(.appAccent)
        }
        .padding(.vertical, 14)
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
