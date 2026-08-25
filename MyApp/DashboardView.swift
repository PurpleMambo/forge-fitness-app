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

    // Compact inline view — shown when user scrolls down and tab bar collapses
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

    // Expanded view — shown above tab bar when at the top
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

// MARK: - Dashboard View
struct DashboardView: View {
    @Environment(AppState.self) var appState
    @Namespace private var dayNamespace
    private let cal = Calendar.current
    @State private var setupExercise: Exercise? = nil

    // Mon-Sun tuples for current week
    var weekDays: [(date: Date, letter: String, num: String, hasWorkout: Bool)] {
        let today = Date()
        let wd = cal.component(.weekday, from: today)
        let offset = wd == 1 ? -6 : -(wd - 2)
        let monday = cal.date(byAdding: .day, value: offset, to: today)!
        let letters = ["M","T","W","T","F","S","S"]
        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: monday)!
            return (d, letters[i], String(cal.component(.day, from: d)), WorkoutDay.weekSchedule[i] != nil)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        weekStrip.padding(.top, 12)

                        if let w = appState.todayWorkout {
                            workoutCard(w).padding(.top, 22).padding(.horizontal, 18)
                            calibrationCard.padding(.top, 14).padding(.horizontal, 18)
                            exerciseSection(w).padding(.top, 14).padding(.horizontal, 18)
                        } else {
                            restCard.padding(.top, 22).padding(.horizontal, 18)
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

    // MARK: - Weekday Strip (GlassEffectContainer enables morphing of the selected day indicator)
    var weekStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(weekDays, id: \.date) { item in
                        let selected = cal.isDate(item.date, inSameDayAs: appState.selectedDate)
                        let isToday  = cal.isDateInToday(item.date)

                        Button {
                            withAnimation(.spring(response: 0.4)) { appState.selectedDate = item.date }
                        } label: {
                            VStack(spacing: 5) {
                                Text(item.letter)
                                    .font(.caption2).fontWeight(.medium)
                                    .foregroundStyle(.secondary)

                                if selected {
                                    Text(item.num)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .glassEffect(.regular.tint(.appAccent).interactive(), in: .circle)
                                        .glassEffectID("daysel", in: dayNamespace)
                                } else {
                                    Text(item.num)
                                        .font(.system(size: 15, weight: .regular))
                                        .frame(width: 36, height: 36)
                                        .foregroundStyle(isToday ? AnyShapeStyle(Color.appAccent) : AnyShapeStyle(Color.primary))
                                }

                                Circle()
                                    .fill(item.hasWorkout ? Color.appAccent : .clear)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(width: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Workout Card (Liquid Glass container for the workout summary)
    func workoutCard(_ w: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(w.name).font(.system(size: 26, weight: .heavy))
                    Text("\(w.exercises.count) Exercises · \(w.muscleGroups.count) Muscles")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    // Switch button — glass tinted with accent
                    Button {  } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.2.squarepath").font(.system(size: 11, weight: .bold))
                            Text("Switch").font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .buttonStyle(.glass(.regular.tint(.appAccent)))

                    Button {  } label: { Image(systemName: "ellipsis") }
                        .buttonStyle(.glass)
                }
            }

            // Tag pills — Liquid Glass capsules (the default shape)
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 8) {
                    tagPill(icon: "clock", label: "\(w.durationMinutes)m")
                    tagPill(icon: "building.2.fill", label: w.gymType)
                }
            }
        }
        .padding(18)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    func tagPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .glassEffect()
    }

    // MARK: - Calibration Card (informational content — uses material, not Liquid Glass)
    var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CALIBRATION")
                .font(.system(size: 10, weight: .heavy)).foregroundColor(.appAccent).tracking(1.5)
            (Text("Your ").foregroundColor(.primary)
             + Text("starting weights").foregroundColor(.appAccent).bold()
             + Text(" are estimates based on the information you provided. Any updates you make during your workout will help calibrate future workouts.").foregroundColor(.secondary))
                .font(.system(size: 13)).lineSpacing(3)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appAccent.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Exercise List
    func exerciseSection(_ w: WorkoutDay) -> some View {
        VStack(spacing: 10) {
            ForEach(w.exercises) { ex in exerciseRow(ex) }

            Button {  } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.appAccent)
                    Text("Add Exercise").font(.system(size: 14, weight: .semibold)).foregroundColor(.appAccent)
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 14)
            }
            .buttonStyle(.glass)
            .padding(.top, 2)
        }
    }

    func exerciseRow(_ ex: Exercise) -> some View {
        Button { setupExercise = ex } label: {
            HStack(spacing: 12) {
                Image(systemName: ex.sfSymbol)
                    .font(.system(size: 20))
                    .foregroundColor(ex.isFocus ? .appAccent : .secondary)
                    .frame(width: 52, height: 52)
                    .glassEffect(ex.isFocus ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    if ex.isFocus {
                        Text("FOCUS EXERCISE")
                            .font(.system(size: 9, weight: .heavy)).foregroundColor(.appGold).tracking(1)
                    }
                    Text(ex.name).font(.system(size: 14, weight: .semibold))
                    Text("\(ex.sets) sets · \(ex.reps) reps · \(ex.weightString) \(ex.weightUnit)")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "ellipsis").foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .glassEffect(in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rest Day Card
    var restCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "moon.stars.fill").font(.system(size: 40)).foregroundColor(.appAccent.opacity(0.7))
            Text("Rest Day").font(.system(size: 22, weight: .heavy))
            Text("Recovery is part of the program.\nTake it easy today.")
                .font(.system(size: 14)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineSpacing(3)
        }
        .padding(32).frame(maxWidth: .infinity)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

}

#Preview {
    let state = AppState()
    state.onboardingComplete = true
    return MainTabView()
        .environment(state)
        .preferredColorScheme(.dark)
}
