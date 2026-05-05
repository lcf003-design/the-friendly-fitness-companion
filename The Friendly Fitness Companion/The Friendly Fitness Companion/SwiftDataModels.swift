import Foundation
import SwiftData

// MARK: - Core Daily Log
@Model
class DailyLog {
    @Attribute(.unique) var id: String // Formatted as "YYYY-MM-DD"
    var date: Date
    
    // Summary Metrics
    var totalFatGrams: Double
    var totalProteinGrams: Double
    var totalCarbsGrams: Double
    var totalVolume: Double
    var maxMotorUnitRecruitment: Double
    
    // Relationships (Cascade delete ensures meals/workouts are deleted if the day is deleted)
    @Relationship(deleteRule: .cascade) var meals: [MealEntry] = []
    @Relationship(deleteRule: .cascade) var workouts: [WorkoutEntry] = []
    
    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = formatter.string(from: date)
        self.date = date
        self.totalFatGrams = 0
        self.totalProteinGrams = 0
        self.totalCarbsGrams = 0
        self.totalVolume = 0
        self.maxMotorUnitRecruitment = 0
    }
}

// MARK: - The Kitchen Entries
@Model
class MealEntry {
    var id: UUID
    var name: String
    var tierRawValue: String? // Made optional and deprecated
    var fatGrams: Double
    var proteinGrams: Double
    var carbsGrams: Double
    var containsSeedOils: Bool
    var containsRefinedSugars: Bool
    var timestamp: Date
    
    // Inverse relationship (Optional, helps SwiftData map the graph)
    var dailyLog: DailyLog?
    
    init(name: String, fat: Double, protein: Double, carbs: Double, hasSeedOils: Bool, hasSugars: Bool) {
        self.id = UUID()
        self.name = name
        self.tierRawValue = nil
        self.fatGrams = fat
        self.proteinGrams = protein
        self.carbsGrams = carbs
        self.containsSeedOils = hasSeedOils
        self.containsRefinedSugars = hasSugars
        self.timestamp = Date()
    }
}

// MARK: - The Forge Entries
@Model
class WorkoutEntry {
    var id: UUID
    var exerciseName: String
    var timestamp: Date
    
    // Nested relationship for sets
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet] = []
    var dailyLog: DailyLog?
    
    init(exerciseName: String) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.timestamp = Date()
    }
}

@Model
class ExerciseSet {
    var id: UUID
    var reps: Int
    var weight: Double
    var rpe: Double // 1.0 - 10.0
    var forcedReps: Bool
    var negatives: Bool
    var restPause: Bool
    var motorUnitRecruitment: Double // Calculated Henneman Output (0.0 - 1.0)
    
    var workoutEntry: WorkoutEntry?
    
    init(reps: Int, weight: Double, rpe: Double, forcedReps: Bool, negatives: Bool, restPause: Bool, recruitment: Double) {
        self.id = UUID()
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.forcedReps = forcedReps
        self.negatives = negatives
        self.restPause = restPause
        self.motorUnitRecruitment = recruitment
    }
}
