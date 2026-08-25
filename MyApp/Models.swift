import SwiftUI
import Foundation
import Observation

// MARK: - Colors
extension Color {
    static let appBg     = Color(red: 0.07, green: 0.04, blue: 0.10)
    static let appAccent = Color(red: 0.72, green: 0.16, blue: 0.22)
    static let appGold   = Color(red: 0.95, green: 0.76, blue: 0.28)
}

// MARK: - Background gradient (gives Liquid Glass more to reflect)
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.06, blue: 0.20),
                Color(red: 0.05, green: 0.02, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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
    var onboardingComplete = false
    var userInitials = "GG"
    var planName = "Get Lean"
    var selectedDate = Date()
}

// MARK: - Sample Data
extension WorkoutDay {
    static let pushDay = WorkoutDay(
        name: "Push Day",
        exercises: [
            Exercise(name: "Barbell Bench Press",        sets: 3, reps: 10, weight: 22.5, weightUnit: "kg", muscleGroup: "Chest",    isFocus: true,  sfSymbol: "dumbbell.fill"),
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
            Exercise(name: "Lat Pulldown",     sets: 3, reps: 10, weight: 55, weightUnit: "kg", muscleGroup: "Back",      isFocus: true,  sfSymbol: "figure.strengthtraining.traditional"),
            Exercise(name: "Seated Cable Row", sets: 3, reps: 12, weight: 45, weightUnit: "kg", muscleGroup: "Back",      isFocus: false, sfSymbol: "figure.rowing"),
            Exercise(name: "Barbell Curl",     sets: 3, reps: 12, weight: 30, weightUnit: "kg", muscleGroup: "Biceps",    isFocus: false, sfSymbol: "dumbbell.fill"),
            Exercise(name: "Face Pull",        sets: 3, reps: 15, weight: 20, weightUnit: "kg", muscleGroup: "Rear Delt", isFocus: false, sfSymbol: "figure.arms.open"),
        ],
        durationMinutes: 40, gymType: "Large Gym", muscleGroups: ["Back", "Biceps"]
    )

    static let legDay = WorkoutDay(
        name: "Leg Day",
        exercises: [
            Exercise(name: "Back Squat",        sets: 4, reps: 8,  weight: 80,  weightUnit: "kg", muscleGroup: "Quads",     isFocus: true,  sfSymbol: "figure.strengthtraining.traditional"),
            Exercise(name: "Romanian Deadlift", sets: 3, reps: 10, weight: 60,  weightUnit: "kg", muscleGroup: "Hamstrings",isFocus: false, sfSymbol: "figure.strengthtraining.traditional"),
            Exercise(name: "Leg Press",         sets: 3, reps: 12, weight: 120, weightUnit: "kg", muscleGroup: "Quads",     isFocus: false, sfSymbol: "figure.strengthtraining.functional"),
            Exercise(name: "Calf Raise",        sets: 4, reps: 15, weight: 60,  weightUnit: "kg", muscleGroup: "Calves",    isFocus: false, sfSymbol: "figure.walk"),
        ],
        durationMinutes: 50, gymType: "Large Gym", muscleGroups: ["Quads", "Hamstrings"]
    )

    // Mon–Sun (nil = rest day)
    static let weekSchedule: [WorkoutDay?] = [
        .pushDay, .pullDay, .legDay, nil, .pushDay, nil, nil
    ]
}
