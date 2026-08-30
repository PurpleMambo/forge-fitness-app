import Foundation
import Observation
import Supabase

// MARK: - Insert payloads

private struct LoggedSetInsert: Encodable {
    let user_id: String
    let exercise_id: String
    let workout_template_id: String
    let reps: Int
    let weight_kg: Double
}

private struct UserProgramInsert: Encodable {
    let user_id: String
    let program_id: String
    let current_week: Int
}

// MARK: - ProgramService

@Observable
@MainActor
final class ProgramService {
    private(set) var programs: [RemoteProgram] = []
    private(set) var isLoading = false
    private(set) var error: String?

    private(set) var userProgram: RemoteUserProgram?
    private(set) var templates: [RemoteWorkoutTemplate] = []
    private var exerciseCache: [UUID: [RemoteWorkoutExercise]] = [:]

    // MARK: - Bootstrap

    func loadAll() async {
        isLoading = true
        error = nil
        do {
            async let p = fetchPrograms()
            async let u = fetchUserProgram()
            programs    = try await p
            userProgram = try await u
            if let up = userProgram {
                templates = try await fetchTemplates(programId: up.programId)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Today's workout

    func todayTemplate(for date: Date = .now) -> RemoteWorkoutTemplate? {
        let weekday = Calendar.current.component(.weekday, from: date)
        let dayName = dayOfWeek(from: weekday)
        let week    = userProgram?.currentWeek ?? 1
        return templates.first { $0.dayOfWeek == dayName && $0.weekNumber == week }
    }

    func exercises(for templateId: UUID) async -> [RemoteWorkoutExercise] {
        if let cached = exerciseCache[templateId] { return cached }
        let result = (try? await fetchExercises(templateId: templateId)) ?? []
        exerciseCache[templateId] = result
        return result
    }

    // MARK: - Logging

    func logSet(exerciseId: UUID, templateId: UUID, reps: Int, weightKg: Double) async {
        guard let user = try? await supabase.auth.session.user else { return }
        let entry = LoggedSetInsert(
            user_id: user.id.uuidString,
            exercise_id: exerciseId.uuidString,
            workout_template_id: templateId.uuidString,
            reps: reps,
            weight_kg: weightKg
        )
        _ = try? await supabase.from("logged_sets").insert(entry).execute()
    }

    func todayLoggedSets(exerciseId: UUID, templateId: UUID) async -> [RemoteLoggedSet] {
        guard let user = try? await supabase.auth.session.user else { return [] }
        let startOfDay = Calendar.current.startOfDay(for: .now).ISO8601Format()
        return (try? await supabase
            .from("logged_sets")
            .select()
            .eq("user_id",     value: user.id.uuidString)
            .eq("exercise_id", value: exerciseId.uuidString)
            .gte("logged_at",  value: startOfDay)
            .execute()
            .value) ?? []
    }

    // MARK: - Program assignment

    func assignProgram(programId: UUID) async throws {
        guard let user = try? await supabase.auth.session.user else { return }
        let row = UserProgramInsert(
            user_id: user.id.uuidString,
            program_id: programId.uuidString,
            current_week: 1
        )
        userProgram = try await supabase
            .from("user_programs")
            .upsert(row, onConflict: "user_id,program_id")
            .select()
            .single()
            .execute()
            .value
        templates = try await fetchTemplates(programId: programId)
        exerciseCache.removeAll()
    }

    func advanceWeek() async {
        guard let up = userProgram else { return }
        let maxWeek = templates.map(\.weekNumber).max() ?? 1
        let week    = min(up.currentWeek + 1, maxWeek)
        _ = try? await supabase
            .from("user_programs")
            .update(["current_week": week])
            .eq("id", value: up.id.uuidString)
            .execute()
        userProgram = try? await supabase
            .from("user_programs")
            .select()
            .eq("id", value: up.id.uuidString)
            .single()
            .execute()
            .value
    }

    // MARK: - Private fetches

    private func fetchPrograms() async throws -> [RemoteProgram] {
        try await supabase.from("programs").select().execute().value
    }

    private func fetchUserProgram() async throws -> RemoteUserProgram? {
        guard let user = try? await supabase.auth.session.user else { return nil }
        return try? await supabase
            .from("user_programs")
            .select()
            .eq("user_id", value: user.id.uuidString)
            .limit(1)
            .single()
            .execute()
            .value
    }

    private func fetchTemplates(programId: UUID) async throws -> [RemoteWorkoutTemplate] {
        try await supabase
            .from("workout_templates")
            .select()
            .eq("program_id", value: programId.uuidString)
            .order("week_number")
            .order("sort_order")
            .execute()
            .value
    }

    private func fetchExercises(templateId: UUID) async throws -> [RemoteWorkoutExercise] {
        try await supabase
            .from("workout_exercises")
            .select("*, exercise:exercises(*)")
            .eq("workout_template_id", value: templateId.uuidString)
            .order("sort_order")
            .execute()
            .value
    }

    // MARK: - Helpers

    private func dayOfWeek(from weekday: Int) -> String {
        switch weekday {
        case 1: return "sunday"
        case 2: return "monday"
        case 3: return "tuesday"
        case 4: return "wednesday"
        case 5: return "thursday"
        case 6: return "friday"
        case 7: return "saturday"
        default: return "monday"
        }
    }
}
