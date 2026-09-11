import Foundation
import Observation
import Supabase

// MARK: - Streak tracking with rest-day awareness
//
// A streak increments only on scheduled workout days that were logged.
// Rest days are transparent — they neither break nor count toward the streak.
// The effective workout days come from ProgramService.templates (set by DashboardView);
// falls back to Mon/Tue/Wed/Fri if templates haven't loaded yet.

@Observable
@MainActor
final class StreakService {
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = UserDefaults.standard.integer(forKey: "streak_longest") {
        didSet { UserDefaults.standard.set(longestStreak, forKey: "streak_longest") }
    }
    var workoutDayNames: Set<String> = []

    private var loggedDates: Set<String> = []

    // For SwiftUI previews — sets streak without hitting Supabase or UserDefaults
    init(previewStreak: Int) {
        currentStreak = previewStreak
        longestStreak = previewStreak
    }

    init() {}

    // MARK: - Public API

    func loadStreak() async {
        guard (try? await supabase.auth.session) != nil else { return }
        do {
            let rows: [WorkoutLogDate] = try await supabase
                .from("workout_logs")
                .select("logged_date")
                .execute()
                .value
            loggedDates = Set(rows.map { $0.logged_date })
            recompute()
        } catch {
            print("StreakService load error:", error)
        }
    }

    func logWorkout(workoutName: String, durationSeconds: Int, volumeKg: Double, calories: Int) async {
        let today = localDateString()
        // Optimistic update so the UI reacts before the network call completes
        loggedDates.insert(today)
        recompute()

        guard let user = try? await supabase.auth.session.user else { return }
        let row = WorkoutLogInsert(
            user_id: user.id.uuidString,
            logged_date: today,
            workout_name: workoutName,
            duration_seconds: durationSeconds,
            volume_kg: volumeKg,
            calories: calories
        )
        _ = try? await supabase
            .from("workout_logs")
            .upsert(row, onConflict: "user_id,logged_date")
            .execute()
    }

    func refresh() {
        recompute()
    }

    // MARK: - Streak computation

    private func recompute() {
        let days = effectiveWorkoutDays
        let streak = computeStreak(workoutDayNames: days)
        currentStreak = streak
        if streak > longestStreak {
            longestStreak = streak
        }
    }

    private var effectiveWorkoutDays: Set<String> {
        workoutDayNames.isEmpty ? ["monday", "tuesday", "wednesday", "friday"] : workoutDayNames
    }

    // Walk backwards from today. Workout days must be logged to count; rest days are skipped.
    // Today's workout day doesn't break the streak if it hasn't been logged yet (user might still go).
    private func computeStreak(workoutDayNames: Set<String>) -> Int {
        var streak = 0
        let cal = Calendar.current
        var date = Date()

        for _ in 0..<365 {
            let dayName = weekdayName(from: date)
            let isToday = cal.isDateInToday(date)
            let wasLogged = loggedDates.contains(localDateString(from: date))

            if workoutDayNames.contains(dayName) {
                if wasLogged {
                    streak += 1
                } else if !isToday {
                    // Missed a past workout day — streak broken
                    break
                }
                // isToday + not logged yet: don't count, don't break
            }

            date = cal.date(byAdding: .day, value: -1, to: date)!
        }

        return streak
    }

    // MARK: - Helpers

    private func weekdayName(from date: Date) -> String {
        let names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        return names[Calendar.current.component(.weekday, from: date) - 1]
    }

    private func localDateString(from date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Supabase Codable helpers

private struct WorkoutLogDate: Decodable {
    let logged_date: String
}

private struct WorkoutLogInsert: Encodable {
    let user_id: String
    let logged_date: String
    let workout_name: String
    let duration_seconds: Int
    let volume_kg: Double
    let calories: Int
}
