import SwiftUI

// MARK: - Workout Summary (shown after Log Workout, with confetti celebration)
struct WorkoutSummaryView: View {
    let workout: WorkoutDay
    let elapsedSeconds: Int
    let workoutStore: WorkoutStore
    var onDone: () -> Void

    private let completedAt = Date()

    // MARK: - Computed stats

    var durationString: String {
        let totalMinutes = elapsedSeconds / 60
        let hours = totalMinutes / 60
        let mins  = totalMinutes % 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return totalMinutes > 0 ? "\(totalMinutes)m" : "< 1m"
    }

    var completedAtString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "Today, \(f.string(from: completedAt))"
    }

    var totalVolume: Double {
        workout.exercises.reduce(0.0) { sum, ex in
            sum + workoutStore.todayLoggedSets(for: ex)
                .reduce(0.0) { $0 + Double($1.reps) * $1.weight }
        }
    }

    var caloriesEstimate: Int { Int(totalVolume * 0.11) }

    var volumeString: String {
        totalVolume.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f kg", totalVolume)
            : String(format: "%.1f kg", totalVolume)
    }

    var loggedExercises: [(exercise: Exercise, sets: [LoggedSetEntry])] {
        workout.exercises.compactMap { ex in
            let sets = workoutStore.todayLoggedSets(for: ex)
            return sets.isEmpty ? nil : (ex, sets)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            // Confetti — fires immediately on appear, non-interactive
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerBar
                    heroSection
                    statsRow
                    exerciseSection
                    Spacer(minLength: 120)
                }
            }

            bottomButtons
        }
    }

    // MARK: - Header bar

    var headerBar: some View {
        ZStack {
            Text(completedAtString)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Button {} label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.glass)

                    Button {} label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.glass)
                }
                .padding(.trailing, 18)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 12)
    }

    // MARK: - Hero (muscle icons + workout name + duration)

    var heroSection: some View {
        VStack(spacing: 10) {
            // Two muscle-group icons side by side
            HStack(spacing: -20) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 58))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .scaleEffect(x: -1)
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 58))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .padding(.top, 16)

            Text(workout.name)
                .font(.system(size: 36, weight: .heavy).italic())
                .multilineTextAlignment(.center)

            Text(durationString)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Stats row

    var statsRow: some View {
        HStack(spacing: 0) {
            Spacer()
            statColumn("CALORIES", value: "\(caloriesEstimate) kCal")
            statDivider()
            statColumn("VOLUME", value: volumeString)
            Spacer()
        }
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    func statColumn(_ label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 16, weight: .bold))
        }
        .frame(minWidth: 90)
    }

    func statDivider() -> some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(width: 1, height: 34)
    }

    // MARK: - Exercise breakdown

    var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(loggedExercises.count) Exercises")
                .font(.system(size: 22, weight: .heavy))
                .padding(.horizontal, 18)
                .padding(.top, 32)
                .padding(.bottom, 14)

            ForEach(loggedExercises, id: \.exercise.id) { item in
                exerciseRow(item.exercise, sets: item.sets)
                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.leading, 88)
            }
        }
    }

    func exerciseRow(_ ex: Exercise, sets: [LoggedSetEntry]) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail with green checkmark badge
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: ex.sfSymbol)
                    .font(.system(size: 22))
                    .foregroundColor(ex.isFocus ? .appAccent : .secondary)
                    .frame(width: 56, height: 56)
                    .glassEffect(ex.isFocus ? .regular.tint(.appAccent) : .regular,
                                 in: .rect(cornerRadius: 12))

                ZStack {
                    Circle()
                        .fill(Color(red: 0.15, green: 0.82, blue: 0.40))
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.black)
                }
                .offset(x: 4, y: 4)
            }

            // Name + set lines
            VStack(alignment: .leading, spacing: 3) {
                if ex.isFocus {
                    Text("FOCUS EXERCISE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.appGold)
                        .tracking(1)
                }
                Text(ex.name)
                    .font(.system(size: 15, weight: .semibold))

                ForEach(sets) { set in
                    let w = set.weight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", set.weight)
                        : String(format: "%.1f", set.weight)
                    Text("\(set.reps) reps × \(w) \(set.weightUnit)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Bottom buttons

    var bottomButtons: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, Color.appBg], startPoint: .top, endPoint: .bottom)
                .frame(height: 48).allowsHitTesting(false)
            HStack(spacing: 12) {
                Button("Share") {}
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity)

                Button("Done") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                }
                .buttonStyle(.glassProminent)
                .tint(.appAccent)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 18).padding(.bottom, 32)
        }
    }
}

// MARK: - Confetti

private struct ConfettiPiece: Identifiable {
    let id: Int
    let startXPct: CGFloat
    let endXPct: CGFloat
    let endYPct: CGFloat
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let rotationEnd: Double
    let duration: Double
    let delay: Double
}

struct ConfettiView: View {
    @State private var launched = false

    // Pieces are stable for the lifetime of this view
    private let pieces: [ConfettiPiece] = {
        let colors: [Color] = [
            Color(red: 0.72, green: 0.16, blue: 0.22),  // accent red
            Color(red: 0.20, green: 0.85, blue: 0.45),  // green
            Color(red: 0.95, green: 0.76, blue: 0.28),  // gold
            Color(red: 0.35, green: 0.72, blue: 1.00),  // blue
            Color(red: 1.00, green: 0.38, blue: 0.28),  // orange-red
        ]
        return (0..<90).map { i in
            ConfettiPiece(
                id: i,
                startXPct: CGFloat.random(in: 0.25...0.75),
                endXPct:   CGFloat.random(in: 0.02...0.98),
                endYPct:   CGFloat.random(in: 0.30...1.20),
                color:     colors[Int.random(in: 0..<colors.count)],
                width:     CGFloat.random(in: 6...14),
                height:    CGFloat.random(in: 3...9),
                rotationEnd: Double.random(in: -540...540),
                duration:    Double.random(in: 1.6...3.4),
                delay:       Double.random(in: 0.00...0.55)
            )
        }
    }()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ForEach(pieces) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.width, height: p.height)
                    .rotationEffect(.degrees(launched ? p.rotationEnd : 0))
                    .position(
                        x: (launched ? p.endXPct : p.startXPct) * w,
                        y: launched ? p.endYPct * h : h * 0.22
                    )
                    .opacity(launched ? 0 : 1)
                    .animation(
                        .easeOut(duration: p.duration).delay(p.delay),
                        value: launched
                    )
            }
        }
        .onAppear {
            // One run-loop pass so initial state renders before animation starts
            DispatchQueue.main.async { launched = true }
        }
    }
}

#Preview {
    let state = AppState()
    return WorkoutSummaryView(
        workout: WorkoutDay.pushDay,
        elapsedSeconds: 935,
        workoutStore: state.workoutStore,
        onDone: {}
    )
    .preferredColorScheme(.dark)
}
