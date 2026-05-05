import Foundation
import FirebaseFirestore

// MARK: - Core Daily Log
/// The root document tying together Nutrition, Workouts, and HealthKit sync data for a given day.
struct DailyLog: Codable, Identifiable {
    @DocumentID var id: String? // Typically formatted as "YYYY-MM-DD"
    var userId: String
    var date: Date
    
    // Kitchen Summary
    var nutritionTotals: NutritionTotals
    
    // Forge Summary
    var workoutSummary: WorkoutSummary
    
    // Health Sync Summary
    var sleepDurationMinutes: Int
    var activeCaloriesBurned: Int
    
    // We can store subcollections for raw meal/workout entries, or arrays if they stay small.
}

struct NutritionTotals: Codable {
    var totalFatGrams: Double
    var totalProteinGrams: Double
    var totalCarbsGrams: Double
    var ratio: Double // Calculated Fat:Protein ratio
    var flags: [String] // e.g., ["Seed Oils Detected", "Refined Sugars Detected"]
}

struct WorkoutSummary: Codable {
    var totalVolume: Double
    var maxMotorUnitRecruitment: Double // 0.0 - 1.0 (100%)
}

// MARK: - The Kitchen Entries
struct MealEntry: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var tier: NutritionTier // "Apex", "Ancestral", "Modern"
    var macros: Macros
    var ingredients: [String]
    var containsSeedOils: Bool
    var containsRefinedSugars: Bool
    var timestamp: Date
}

enum NutritionTier: String, Codable {
    case apex = "Apex"           // Ruminant Meat, Eggs, Butter, Tallow
    case ancestral = "Ancestral" // Fruit, Raw Honey, Dairy
    case modern = "Modern"       // Highly Processed, Seed Oils, Refined Sugars
}

struct Macros: Codable {
    var fat: Double
    var protein: Double
    var carbs: Double
}

// MARK: - The Forge Entries
struct WorkoutEntry: Codable, Identifiable {
    @DocumentID var id: String?
    var exerciseName: String
    var sets: [ExerciseSet]
    var timestamp: Date
}

struct ExerciseSet: Codable {
    var reps: Int
    var weight: Double
    var rpe: Double // Rate of Perceived Exertion (1.0 - 10.0)
    var intensityModifiers: [IntensityModifier] // ["Forced Reps", "Negatives", "Rest-Pause"]
    var motorUnitRecruitment: Double // Calculated based on Henneman Principle (0.0 - 1.0)
}

enum IntensityModifier: String, Codable {
    case forcedReps = "Forced Reps"
    case negatives = "Negatives"
    case restPause = "Rest-Pause"
}
