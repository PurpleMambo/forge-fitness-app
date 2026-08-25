import SwiftUI

// MARK: - Main Tab View (native iOS 26 — Liquid Glass tab bar is automatic)
struct MainTabView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        @Bindable var appState = appState
        TabView {
            Tab("Workout", systemImage: "dumbbell.fill") {
                DashboardView()
            }
            Tab("Body", systemImage: "figure.arms.open") {
                PlaceholderTabView(title: "Body", icon: "figure.arms.open")
            }
            Tab("Targets", systemImage: "scope") {
                PlaceholderTabView(title: "Targets", icon: "scope")
            }
            Tab("Log", systemImage: "calendar") {
                PlaceholderTabView(title: "Log", icon: "calendar")
            }
        }
        .tint(.appAccent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            if appState.todayWorkout != nil {
                WorkoutAccessoryView()
                    .tint(.appAccent)
            }
        }
        .fullScreenCover(isPresented: $appState.showActiveWorkout) {
            if let w = appState.todayWorkout {
                ActiveWorkoutView(workout: w, isPresented: $appState.showActiveWorkout)
            }
        }
    }
}

struct PlaceholderTabView: View {
    let title: String; let icon: String
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 14) {
                    Image(systemName: icon).font(.system(size: 52)).foregroundColor(.appAccent.opacity(0.5))
                    Text(title).font(.system(size: 22, weight: .bold))
                    Text("Coming soon").font(.system(size: 14)).foregroundColor(.secondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Workout Accessory (music-player mini-bar pattern)
private struct WorkoutAccessoryView: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @Environment(AppState.self) private var appState

    var body: some View {
        if placement == .inline {
            inlineBar
        } else {
            expandedBar
        }
    }

    private var inlineBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appAccent)

            if let w = appState.todayWorkout {
                Text(w.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }

            Spacer()

            Button { appState.showActiveWorkout = true } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
            }
            .buttonStyle(.glassProminent)
            .tint(.appAccent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var expandedBar: some View {
        Button { appState.showActiveWorkout = true } label: {
            Text("Start Workout")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .tint(.appAccent)
    }
}

// MARK: - Animated checkmark for completed workout days
private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY * 0.85))
        p.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

private struct AnimatedCheckmark: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        CheckmarkShape()
            .trim(from: 0, to: progress)
            .stroke(
                Color(red: 0.3, green: 0.85, blue: 0.45),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 12, height: 9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45).delay(0.05)) {
                    progress = 1
                }
            }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @Environment(AppState.self) var appState
    @Namespace private var dayNamespace
    private let cal = Calendar.current
    @State private var setupExercise: Exercise? = nil

    private static let completedGreen = Color(red: 0.3, green: 0.85, blue: 0.45)

    // MARK: - Completion helpers
    private func isExerciseCompleted(_ ex: Exercise) -> Bool {
        appState.workoutStore.totalSetsLogged(for: ex) >= ex.sets
    }

    private func completedCount(for w: WorkoutDay) -> Int {
        w.exercises.filter { isExerciseCompleted($0) }.count
    }

    private func isWorkoutCompleted(_ workout: WorkoutDay, on date: Date) -> Bool {
        appState.workoutStore.isWorkoutCompleted(workout, on: date)
    }

    // Mon-Sun tuples for current week — carries the full WorkoutDay? for completion checks
    var weekDays: [(date: Date, letter: String, num: String, workout: WorkoutDay?)] {
        let today = Date()
        let wd = cal.component(.weekday, from: today)
        let offset = wd == 1 ? -6 : -(wd - 2)
        let monday = cal.date(byAdding: .day, value: offset, to: today)!
        let letters = ["M","T","W","T","F","S","S"]
        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: monday)!
            return (d, letters[i], String(cal.component(.day, from: d)), WorkoutDay.weekSchedule[i])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        weekStrip.padding(.top, 14)

                        if let w = appState.todayWorkout {
                            workoutCard(w).padding(.top, 24).padding(.horizontal, 18)
                            exerciseSection(w).padding(.top, 16).padding(.horizontal, 18)
                        } else {
                            restCard.padding(.top, 24).padding(.horizontal, 18)
                        }

                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {  } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: 30, height: 30)
                                Text("GG")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            HStack(spacing: 3) {
                                Text("My Plan")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $setupExercise) { ex in
            NavigationStack {
                ExerciseSetupView(
                    exercise: ex,
                    workout: appState.todayWorkout,
                    onStartWorkout: {
                        setupExercise = nil
                        Task {
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            appState.showActiveWorkout = true
                        }
                    }
                )
            }
        }
    }

    // MARK: - Weekday Strip
    var weekStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(weekDays, id: \.date) { item in
                        let selected = cal.isDate(item.date, inSameDayAs: appState.selectedDate)
                        let isToday  = cal.isDateInToday(item.date)
                        let done     = item.workout.map { isWorkoutCompleted($0, on: item.date) } ?? false

                        Button {
                            withAnimation(.spring(response: 0.4)) { appState.selectedDate = item.date }
                        } label: {
                            VStack(spacing: 6) {
                                Text(item.letter)
                                    .font(.caption).fontWeight(.medium)
                                    .foregroundStyle(.secondary)

                                if selected {
                                    Text(item.num)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .glassEffect(.regular.tint(.appAccent).interactive(), in: .circle)
                                        .glassEffectID("daysel", in: dayNamespace)
                                } else {
                                    Text(item.num)
                                        .font(.system(size: 17, weight: .regular))
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(isToday ? AnyShapeStyle(Color.appAccent) : AnyShapeStyle(Color.primary))
                                }

                                // Bottom indicator: animated checkmark if done, dot if workout pending, invisible if rest
                                ZStack {
                                    if done {
                                        AnimatedCheckmark()
                                    } else if item.workout != nil {
                                        Circle()
                                            .fill(Color.appAccent)
                                            .frame(width: 5, height: 5)
                                    }
                                }
                                .frame(width: 14, height: 10)
                            }
                            .frame(width: 50)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Workout Card
    func workoutCard(_ w: WorkoutDay) -> some View {
        let done = completedCount(for: w)
        let allDone = done == w.exercises.count && done > 0
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(w.name).font(.system(size: 28, weight: .heavy))
                    Text("\(w.exercises.count) Exercises · \(w.muscleGroups.count) Muscles")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {  } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.2.squarepath").font(.system(size: 12, weight: .bold))
                            Text("Switch").font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(.glass(.regular.tint(.appAccent)))

                    Button {  } label: { Image(systemName: "ellipsis") }
                        .buttonStyle(.glass)
                }
            }

            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 8) {
                    tagPill(icon: "clock", label: "\(w.durationMinutes)m")
                    tagPill(icon: "building.2.fill", label: w.gymType)
                }
            }

            if done > 0 {
                HStack(spacing: 6) {
                    Image(systemName: allDone ? "checkmark.circle.fill" : "circle.dotted")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(allDone ? Self.completedGreen : .appAccent)
                    Text(allDone ? "Workout Complete!" : "\(done) of \(w.exercises.count) exercises done")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(allDone ? Self.completedGreen : .secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 22))
    }

    func tagPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12))
            Text(label).font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .glassEffect()
    }

    // MARK: - Exercise List
    func exerciseSection(_ w: WorkoutDay) -> some View {
        VStack(spacing: 10) {
            ForEach(w.exercises) { ex in exerciseRow(ex) }

            Button {  } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold)).foregroundColor(.appAccent)
                    Text("Add Exercise").font(.system(size: 15, weight: .semibold)).foregroundColor(.appAccent)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 16)
            }
            .buttonStyle(.glass)
            .padding(.top, 2)
        }
    }

    func exerciseRow(_ ex: Exercise) -> some View {
        let completed = isExerciseCompleted(ex)
        let loggedSets = appState.workoutStore.totalSetsLogged(for: ex)
        return Button { setupExercise = ex } label: {
            HStack(spacing: 14) {
                Image(systemName: completed ? "checkmark.circle.fill" : ex.sfSymbol)
                    .font(.system(size: 22))
                    .foregroundColor(completed ? Self.completedGreen : (ex.isFocus ? .appAccent : .secondary))
                    .frame(width: 58, height: 58)
                    .glassEffect(
                        completed
                            ? .regular.tint(Self.completedGreen)
                            : (ex.isFocus ? .regular.tint(.appAccent) : .regular),
                        in: .rect(cornerRadius: 14)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    if completed {
                        Text("COMPLETED")
                            .font(.system(size: 10, weight: .heavy)).foregroundColor(Self.completedGreen).tracking(1)
                    } else if ex.isFocus {
                        Text("FOCUS EXERCISE")
                            .font(.system(size: 10, weight: .heavy)).foregroundColor(.appGold).tracking(1)
                    }
                    Text(ex.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(completed ? Color.secondary : Color.primary)
                    Text(completed
                         ? "\(loggedSets)/\(ex.sets) sets logged"
                         : "\(ex.sets) sets · \(ex.reps) reps · \(ex.weightString) \(ex.weightUnit)")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: completed ? "checkmark" : "ellipsis").foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .glassEffect(in: .rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .opacity(completed ? 0.72 : 1.0)
    }

    // MARK: - Rest Day Card
    var restCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill").font(.system(size: 46)).foregroundColor(.appAccent.opacity(0.7))
            Text("Rest Day").font(.system(size: 24, weight: .heavy))
            Text("Recovery is part of the program.\nTake it easy today.")
                .font(.system(size: 15)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineSpacing(3)
        }
        .padding(36).frame(maxWidth: .infinity)
        .glassEffect(in: .rect(cornerRadius: 22))
    }

}

#Preview {
    let state = AppState()
    state.onboardingComplete = true
    return MainTabView()
        .environment(state)
        .preferredColorScheme(.dark)
}
