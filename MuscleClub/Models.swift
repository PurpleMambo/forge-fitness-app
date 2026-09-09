import SwiftUI
import Foundation
import Observation
import Supabase

// MARK: - Colors
extension Color {
    static let appBg = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
            : UIColor(red: 0.97, green: 0.99, blue: 0.98, alpha: 1)
    })
    static let appAccent = Color.mint
    static let appGold   = Color.mint
}

// MARK: - Background gradient (gives Liquid Glass more to reflect)
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            MeshGradient(width: 3, height: 3, points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ], colors: [
                Color(red: 0.04, green: 0.16, blue: 0.18),  // dark teal top-left
                Color(red: 0.02, green: 0.04, blue: 0.07),  // near-black top-center
                Color(red: 0.03, green: 0.06, blue: 0.13),  // dark navy top-right
                Color(red: 0.05, green: 0.13, blue: 0.15),  // teal-green mid-left
                Color(red: 0.03, green: 0.04, blue: 0.06),  // dark center
                Color(red: 0.02, green: 0.04, blue: 0.10),  // deep navy mid-right
                Color(red: 0.01, green: 0.03, blue: 0.04),  // near-black bottom-left
                Color(red: 0.03, green: 0.10, blue: 0.12),  // subtle teal bottom-center
                Color(red: 0.01, green: 0.02, blue: 0.04)   // near-black bottom-right
            ])
            .ignoresSafeArea()
        } else {
            // Light mode: rich mint + warm cream give the glass real color to refract
            MeshGradient(width: 3, height: 3, points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ], colors: [
                Color(red: 0.62, green: 0.92, blue: 0.85),  // vivid mint top-left
                Color.white,                                  // white top-center
                Color(red: 0.78, green: 0.96, blue: 0.92),  // soft mint top-right
                Color.white,                                  // white mid-left
                Color(red: 0.82, green: 0.97, blue: 0.93),  // mint center
                Color(red: 1.00, green: 0.95, blue: 0.90),  // warm cream mid-right
                Color(red: 0.70, green: 0.94, blue: 0.88),  // mint bottom-left
                Color(red: 1.00, green: 0.97, blue: 0.93),  // warm cream bottom-center
                Color(red: 0.97, green: 0.94, blue: 0.89)   // warm blush bottom-right
            ])
            .ignoresSafeArea()
        }
    }
}

// MARK: - Models
struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double
    let weightUnit: String
    let muscleGroup: String
    let isFocus: Bool
    let sfSymbol: String
    var aliasesText: String = ""
    var instructionSteps: [String] = []
    var primaryMuscles: [String] = []
    var secondaryMuscles: [String] = []
    var equipmentList: [String] = []
    var videoResource: String? = nil

    var weightString: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

struct WorkoutDay: Identifiable {
    let id = UUID()
    let name: String
    let exercises: [Exercise]
    let durationMinutes: Int
    let gymType: String
    let muscleGroups: [String]
}

// MARK: - App State
@Observable
class AppState {
    var welcomeSeen: Bool = UserDefaults.standard.bool(forKey: "welcomeSeen") {
        didSet { UserDefaults.standard.set(welcomeSeen, forKey: "welcomeSeen") }
    }
    var onboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingComplete") {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }
    var userInitials = "GG"
    var planName = "Get Lean"
    var selectedDate = Date()
    var workoutStore = WorkoutStore()
    var showActiveWorkout = false
    var isAuthenticated = false
    var sessionCheckComplete = false
    var remoteWorkout: WorkoutDay? = nil

    @MainActor
    func checkSession() async {
        isAuthenticated = (try? await supabase.auth.session) != nil
        if isAuthenticated {
            welcomeSeen = true
            onboardingComplete = true
        }
        sessionCheckComplete = true
    }

    var todayWorkout: WorkoutDay? {
        if let remote = remoteWorkout { return remote }
        let cal = Calendar.current
        let wd = cal.component(.weekday, from: selectedDate)
        let idx = wd == 1 ? 6 : wd - 2
        guard idx >= 0, idx < 7 else { return nil }
        return WorkoutDay.weekSchedule[idx]
    }
}

// MARK: - Workout Logging

struct LoggedSetEntry: Codable, Identifiable {
    var id = UUID()
    var exerciseName: String
    var reps: Int
    var weight: Double
    var weightUnit: String
    var date: Date
}

@Observable
class WorkoutStore {
    private(set) var entries: [LoggedSetEntry] = []
    private let storageKey = "workout_logged_sets_v1"

    init() { load() }

    func logSet(exercise: Exercise, reps: Int, weight: Double) {
        entries.append(LoggedSetEntry(
            exerciseName: exercise.name,
            reps: reps,
            weight: weight,
            weightUnit: exercise.weightUnit,
            date: Date()
        ))
        save()
    }

    func todayLoggedSets(for exercise: Exercise) -> [LoggedSetEntry] {
        let cal = Calendar.current
        return entries.filter {
            $0.exerciseName == exercise.name && cal.isDateInToday($0.date)
        }
    }

    func totalSetsLogged(for exercise: Exercise) -> Int {
        todayLoggedSets(for: exercise).count
    }

    func isWorkoutCompleted(_ workout: WorkoutDay, on date: Date) -> Bool {
        let cal = Calendar.current
        return workout.exercises.allSatisfy { ex in
            entries.filter {
                $0.exerciseName == ex.name && cal.isDate($0.date, inSameDayAs: date)
            }.count >= ex.sets
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LoggedSetEntry].self, from: data)
        else { return }
        entries = decoded
    }
}

// MARK: - Sample Data
extension WorkoutDay {
    static let pushDay = WorkoutDay(
        name: "Push Day",
        exercises: [
            Exercise(name: "Barbell Bench Press", sets: 3, reps: 10, weight: 22.5, weightUnit: "kg", muscleGroup: "Chest", isFocus: true, sfSymbol: "dumbbell.fill",
                aliasesText: "BB Bench Press, Barbell Press, Chest Press, Flat Bench Press",
                instructionSteps: [
                    "Lie back onto a bench, squeezing your shoulder blades together and pressing your heels firmly into the floor underneath your knees.",
                    "The bench should remain in contact with your head, shoulders, and glutes at all times.",
                    "Grip the barbell just outside shoulder-width so your arms are extended directly over your shoulders when unracked.",
                    "Brace your core by breathing into your stomach and descend the barbell toward your lower chest, keeping elbows at roughly 45° from your torso.",
                    "Lightly touch the middle of your chest, then exhale and press back to the starting position."
                ],
                primaryMuscles: ["Chest"],
                secondaryMuscles: ["Shoulders", "Triceps"],
                equipmentList: ["Barbell", "Flat Bench"],
                videoResource: "bekkpressa með stöng"),
            Exercise(name: "Cable Tricep Pushdown",      sets: 3, reps: 12, weight: 14,   weightUnit: "kg", muscleGroup: "Triceps",  isFocus: false, sfSymbol: "figure.strengthtraining.traditional"),
            Exercise(name: "Machine Fly",                sets: 3, reps: 12, weight: 22,   weightUnit: "kg", muscleGroup: "Chest",    isFocus: false, sfSymbol: "figure.arms.open"),
            Exercise(name: "Dumbbell Skullcrusher",      sets: 2, reps: 8,  weight: 7.5,  weightUnit: "kg", muscleGroup: "Triceps",  isFocus: false, sfSymbol: "dumbbell"),
            Exercise(name: "Hammerstrength Chest Press", sets: 2, reps: 12, weight: 20,   weightUnit: "kg", muscleGroup: "Chest",    isFocus: false, sfSymbol: "figure.strengthtraining.functional"),
        ],
        durationMinutes: 45, gymType: "Large Gym", muscleGroups: ["Chest", "Triceps"]
    )

    static let pullDay = WorkoutDay(
        name: "Pull Day",
        exercises: [
            Exercise(name: "Lat Pulldown", sets: 3, reps: 10, weight: 55, weightUnit: "kg", muscleGroup: "Back", isFocus: true, sfSymbol: "figure.strengthtraining.traditional",
                aliasesText: "Cable Pulldown, Pulldown, Lat Pull",
                instructionSteps: [
                    "Sit at the lat pulldown station and lock your thighs under the pad with feet flat on the floor.",
                    "Grip the bar slightly wider than shoulder-width with an overhand grip.",
                    "Lean back slightly, then pull the bar down to your upper chest by driving your elbows toward the floor and squeezing your lats.",
                    "Hold the contraction for a beat, then slowly return the bar to full arm extension."
                ],
                primaryMuscles: ["Lats", "Rhomboids"],
                secondaryMuscles: ["Biceps", "Rear Deltoids"],
                equipmentList: ["Cable Machine", "Lat Pulldown Bar"]),
            Exercise(name: "Seated Cable Row", sets: 3, reps: 12, weight: 45, weightUnit: "kg", muscleGroup: "Back",      isFocus: false, sfSymbol: "figure.rowing"),
            Exercise(name: "Barbell Curl",     sets: 3, reps: 12, weight: 30, weightUnit: "kg", muscleGroup: "Biceps",    isFocus: false, sfSymbol: "dumbbell.fill"),
            Exercise(name: "Face Pull",        sets: 3, reps: 15, weight: 20, weightUnit: "kg", muscleGroup: "Rear Delt", isFocus: false, sfSymbol: "figure.arms.open"),
        ],
        durationMinutes: 40, gymType: "Large Gym", muscleGroups: ["Back", "Biceps"]
    )

    static let legDay = WorkoutDay(
        name: "Leg Day",
        exercises: [
            Exercise(name: "Back Squat", sets: 4, reps: 8, weight: 80, weightUnit: "kg", muscleGroup: "Quads", isFocus: true, sfSymbol: "figure.strengthtraining.traditional",
                aliasesText: "Squat, BB Squat, Barbell Back Squat",
                instructionSteps: [
                    "Position the barbell across your upper traps, gripping slightly wider than shoulder-width.",
                    "Stand with feet shoulder-width apart, toes turned out 15–30°.",
                    "Brace your core, take a deep breath, and descend by pushing your knees out in line with your toes.",
                    "Lower until your hips reach at least parallel to the floor while keeping your chest tall.",
                    "Drive through your whole foot to return to the starting position, exhaling at the top."
                ],
                primaryMuscles: ["Quadriceps", "Glutes"],
                secondaryMuscles: ["Hamstrings", "Core"],
                equipmentList: ["Barbell", "Squat Rack"]),
            Exercise(name: "Romanian Deadlift", sets: 3, reps: 10, weight: 60,  weightUnit: "kg", muscleGroup: "Hamstrings", isFocus: false, sfSymbol: "figure.strengthtraining.traditional"),
            Exercise(name: "Leg Press",         sets: 3, reps: 12, weight: 120, weightUnit: "kg", muscleGroup: "Quads",      isFocus: false, sfSymbol: "figure.strengthtraining.functional"),
            Exercise(name: "Calf Raise",        sets: 4, reps: 15, weight: 60,  weightUnit: "kg", muscleGroup: "Calves",     isFocus: false, sfSymbol: "figure.walk"),
        ],
        durationMinutes: 50, gymType: "Large Gym", muscleGroups: ["Quads", "Hamstrings"]
    )

    // Mon–Sun (nil = rest day)
    static let weekSchedule: [WorkoutDay?] = [
        .pushDay, .pullDay, .legDay, nil, .pushDay, nil, nil
    ]
}
