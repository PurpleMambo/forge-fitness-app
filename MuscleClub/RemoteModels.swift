import Foundation

// MARK: - Remote models (Codable, mirror the Supabase schema)

struct RemoteProgram: Codable, Identifiable {
    let id: UUID
    let name: String
    let nameIs: String
    let gender: String
    let daysPerWeek: Int

    enum CodingKeys: String, CodingKey {
        case id, name, gender
        case nameIs       = "name_is"
        case daysPerWeek  = "days_per_week"
    }
}

struct RemoteWorkoutTemplate: Codable, Identifiable {
    let id: UUID
    let programId: UUID
    let weekNumber: Int
    let dayOfWeek: String
    let name: String
    let nameIs: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case programId   = "program_id"
        case weekNumber  = "week_number"
        case dayOfWeek   = "day_of_week"
        case nameIs      = "name_is"
        case sortOrder   = "sort_order"
    }
}

struct RemoteExercise: Codable, Identifiable {
    let id: UUID
    let nameEn: String
    let nameIs: String
    let muscleGroup: String
    let equipment: [String]
    let instructions: [String]
    let videoUrl: String?
    let thumbnailUrl: String?
    let sfSymbol: String
    let exerciseType: String

    enum CodingKeys: String, CodingKey {
        case id, equipment, instructions
        case nameEn       = "name_en"
        case nameIs       = "name_is"
        case muscleGroup  = "muscle_group"
        case videoUrl     = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case sfSymbol     = "sf_symbol"
        case exerciseType = "exercise_type"
    }

    var isExercise: Bool  { exerciseType == "exercise" }
    var isWarmup:   Bool  { exerciseType == "warmup" }
    var isCardio:   Bool  { exerciseType == "cardio" }
    var isCooldown: Bool  { exerciseType == "cooldown" }
}

struct RemoteWorkoutExercise: Codable, Identifiable {
    let id: UUID
    let workoutTemplateId: UUID
    let exerciseId: UUID
    let sets: Int
    let reps: Int?
    let durationSeconds: Int?
    let restSeconds: Int
    let isFocus: Bool
    let sortOrder: Int
    var exercise: RemoteExercise?

    enum CodingKeys: String, CodingKey {
        case id, sets, reps, exercise
        case workoutTemplateId = "workout_template_id"
        case exerciseId        = "exercise_id"
        case durationSeconds   = "duration_seconds"
        case restSeconds       = "rest_seconds"
        case isFocus           = "is_focus"
        case sortOrder         = "sort_order"
    }
}

struct RemoteUserProgram: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let programId: UUID
    let startedAt: Date
    let currentWeek: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId      = "user_id"
        case programId   = "program_id"
        case startedAt   = "started_at"
        case currentWeek = "current_week"
    }
}

struct RemoteLoggedSet: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let exerciseId: UUID
    let workoutTemplateId: UUID?
    let reps: Int?
    let weightKg: Double?
    let loggedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, reps
        case userId             = "user_id"
        case exerciseId         = "exercise_id"
        case workoutTemplateId  = "workout_template_id"
        case weightKg           = "weight_kg"
        case loggedAt           = "logged_at"
    }
}

// MARK: - Convenience: convert RemoteWorkoutExercise → app Exercise

extension RemoteWorkoutExercise {
    func toExercise() -> Exercise? {
        guard let ex = exercise, ex.isExercise else { return nil }
        return Exercise(
            name: ex.nameEn,
            sets: sets,
            reps: reps ?? 0,
            weight: 0,
            weightUnit: "kg",
            muscleGroup: ex.muscleGroup,
            isFocus: isFocus,
            sfSymbol: ex.sfSymbol,
            instructionSteps: ex.instructions,
            videoResource: ex.videoUrl
        )
    }
}
