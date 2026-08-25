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

    // MARK: - Weekday Strip (GlassEffectContainer enables morphing of the selected day indicator)
    var weekStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(weekDays, id: \.date) { item in
                        let selected = cal.isDate(item.date, inSameDayAs: appState.selectedDate)
                        let isToday  = cal.isDateInToday(item.date)

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

                                Circle()
                                    .fill(item.hasWorkout ? Color.appAccent : .clear)
                                    .frame(width: 5, height: 5)
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

    // MARK: - Workout Card (Liquid Glass container for the workout summary)
    func workoutCard(_ w: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(w.name).font(.system(size: 28, weight: .heavy))
                    Text("\(w.exercises.count) Exercises · \(w.muscleGroups.count) Muscles")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    // Switch button — glass tinted with accent
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

            // Tag pills — Liquid Glass capsules (the default shape)
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 8) {
                    tagPill(icon: "clock", label: "\(w.durationMinutes)m")
                    tagPill(icon: "building.2.fill", label: w.gymType)
                }
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
        Button { setupExercise = ex } label: {
            HStack(spacing: 14) {
                Image(systemName: ex.sfSymbol)
                    .font(.system(size: 22))
                    .foregroundColor(ex.isFocus ? .appAccent : .secondary)
                    .frame(width: 58, height: 58)
                    .glassEffect(ex.isFocus ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    if ex.isFocus {
                        Text("FOCUS EXERCISE")
                            .font(.system(size: 10, weight: .heavy)).foregroundColor(.appGold).tracking(1)
                    }
                    Text(ex.name).font(.system(size: 16, weight: .semibold))
                    Text("\(ex.sets) sets · \(ex.reps) reps · \(ex.weightString) \(ex.weightUnit)")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "ellipsis").foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .glassEffect(in: .rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
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
