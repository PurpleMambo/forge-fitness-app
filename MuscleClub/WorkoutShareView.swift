import SwiftUI

// MARK: - Workout Share View
// Full-screen modal presenting shareable workout cards.
// Swiping switches between card styles; bottom row has Stories + More share targets.
struct WorkoutShareView: View {
    let workout: WorkoutDay
    let elapsedSeconds: Int
    let workoutStore: WorkoutStore
    var onDismiss: () -> Void

    @State private var selectedCard = 0

    private let completedAt = Date()

    // MARK: - Computed

    var durationString: String {
        let mins = elapsedSeconds / 60
        let hrs  = mins / 60
        if hrs > 0 { return "\(hrs)h \(mins % 60)m" }
        return mins > 0 ? "\(mins)m" : "< 1m"
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return "\(f.string(from: completedAt)) · \(durationString)"
    }

    var totalVolume: Double {
        workout.exercises.reduce(0.0) { sum, ex in
            sum + workoutStore.todayLoggedSets(for: ex)
                .reduce(0.0) { $0 + Double($1.reps) * $1.weight }
        }
    }

    var caloriesEstimate: Int { Int(totalVolume * 0.11) }

    var loggedExercises: [Exercise] {
        workout.exercises.filter { workoutStore.totalSetsLogged(for: $0) > 0 }
    }

    var shareText: String {
        let names = loggedExercises.map { $0.name }.joined(separator: ", ")
        return """
        Finished \(workout.name) 💪
        Duration: \(durationString) · Calories: \(caloriesEstimate) kcal · Volume: \(String(format: "%.0f", totalVolume)) kg
        Exercises: \(names)
        """
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            VStack(spacing: 0) {
                navBar

                // Swipeable cards
                TabView(selection: $selectedCard) {
                    WorkoutShareCard(
                        workout: workout,
                        dateString: dateString,
                        caloriesEstimate: caloriesEstimate,
                        totalVolume: totalVolume,
                        loggedExercises: loggedExercises,
                        style: .detailed
                    )
                    .padding(.horizontal, 28)
                    .tag(0)

                    WorkoutShareCard(
                        workout: workout,
                        dateString: dateString,
                        caloriesEstimate: caloriesEstimate,
                        totalVolume: totalVolume,
                        loggedExercises: loggedExercises,
                        style: .minimal
                    )
                    .padding(.horizontal, 28)
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                pageDots
                    .padding(.top, 20)

                Spacer()
            }

            shareButtons
                .padding(.bottom, 52)
        }
    }

    // MARK: - Nav bar

    var navBar: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    selectedCard = selectedCard == 0 ? 1 : 0
                }
            } label: {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 15, weight: .bold))
            }
            .buttonStyle(.glass)

            Spacer()

            Text("Pick a card to share")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.glass)
            .tint(.appAccent)
        }
        .padding(.horizontal, 18)
        .padding(.top, 60)
        .padding(.bottom, 28)
    }

    // MARK: - Page dots

    var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .fill(selectedCard == i ? Color.primary : Color.secondary.opacity(0.35))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: selectedCard)
            }
        }
    }

    // MARK: - Share buttons

    var shareButtons: some View {
        HStack(spacing: 48) {
            // Instagram Stories
            VStack(spacing: 8) {
                Button {} label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.33, blue: 0.22),
                                        Color(red: 0.86, green: 0.18, blue: 0.56),
                                        Color(red: 0.54, green: 0.18, blue: 0.90)
                                    ],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                Text("Stories")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // System share sheet
            VStack(spacing: 8) {
                ShareLink(item: shareText) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.10))
                            .frame(width: 58, height: 58)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)
                Text("More")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Share Card

struct WorkoutShareCard: View {
    let workout: WorkoutDay
    let dateString: String
    let caloriesEstimate: Int
    let totalVolume: Double
    let loggedExercises: [Exercise]

    enum Style { case detailed, minimal }
    let style: Style

    var volumeString: String {
        totalVolume.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", totalVolume)
            : String(format: "%.1f", totalVolume)
    }

    var exerciseNamesString: String {
        loggedExercises.map { $0.name }.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header: brand logo + date/duration
            HStack(alignment: .center) {
                Text("LIFT")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(3)
                    .foregroundColor(.white)
                Spacer()
                Text(dateString)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            // Muscle icons
            HStack(spacing: -20) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary.opacity(0.65))
                    .scaleEffect(x: -1)
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, style == .minimal ? 22 : 14)

            // Workout name
            Text(workout.name)
                .font(.system(size: style == .minimal ? 32 : 26, weight: .heavy).italic())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
                .padding(.horizontal, 18)

            // Stats
            HStack(spacing: 0) {
                statBlock("Calories", value: "\(caloriesEstimate)", unit: "kcal")
                Spacer()
                statBlock("Volume", value: volumeString, unit: "kg")
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            // Exercise strip + names (detailed only)
            if style == .detailed && !loggedExercises.isEmpty {
                HStack(spacing: 3) {
                    ForEach(loggedExercises.prefix(3)) { ex in
                        ZStack {
                            Rectangle()
                                .fill(Color(red: 0.12, green: 0.08, blue: 0.18))
                            Image(systemName: ex.sfSymbol)
                                .font(.system(size: 22))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .frame(height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                Text(exerciseNamesString)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
            }

            Spacer().frame(height: 20)
        }
        .background(Color(red: 0.10, green: 0.07, blue: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }

    func statBlock(_ label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold))
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let state = AppState()
    return WorkoutShareView(
        workout: WorkoutDay.pushDay,
        elapsedSeconds: 935,
        workoutStore: state.workoutStore,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
