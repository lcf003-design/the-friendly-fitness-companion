import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - Core Daily Log
@Model
class DailyLog {
    @Attribute(.unique) var id: String // Formatted as "YYYY-MM-DD"
    var date: Date
    
    var totalVolume: Double
    var maxMotorUnitRecruitment: Double
    
    @Relationship(deleteRule: .cascade) var workouts: [WorkoutEntry] = []
    @Relationship(deleteRule: .cascade) var progressPhotos: [ProgressPhoto] = []
    @Relationship(deleteRule: .cascade) var bodyMeasurements: [BodyMeasurement] = []
    @Relationship(deleteRule: .cascade) var foodEntries: [FoodEntry] = []
    
    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = formatter.string(from: date)
        self.date = date
        self.totalVolume = 0
        self.maxMotorUnitRecruitment = 0
    }
}

// MARK: - The Forge Entries
@Model
class WorkoutEntry {
    var id: UUID
    var exerciseName: String
    var timestamp: Date
    
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet] = []
    var dailyLog: DailyLog?
    
    var equipmentBrand: String?
    var resistanceType: String?
    
    init(exerciseName: String) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.timestamp = Date()
    }
}

@Model
class ExerciseSet {
    var id: UUID
    var weight: Double
    var unit: String // "lbs" or "kg"
    
    // Core Heavy Duty Rep Tracking
    var baseReps: Int
    var restPauseReps: [Int] // Tracks the reps achieved after each 15s rest pause e.g., [2, 1]
    
    var rpe: Double // 1.0 - 10.0
    var forcedReps: Bool // Deprecated
    var negatives: Bool // Deprecated
    
    var forcedRepsCount: Int
    var negativesCount: Int
    var isWarmup: Bool
    
    var motorUnitRecruitment: Double // Calculated Henneman Output (0.0 - 1.0)
    
    var workoutEntry: WorkoutEntry?
    var isAbsoluteFailure: Bool?
    
    init(weight: Double, unit: String = "lbs", baseReps: Int, restPauseReps: [Int] = [], rpe: Double, forcedReps: Bool = false, negatives: Bool = false, forcedRepsCount: Int = 0, negativesCount: Int = 0, isWarmup: Bool = false, recruitment: Double, isAbsoluteFailure: Bool? = false) {
        self.id = UUID()
        self.weight = weight
        self.unit = unit
        self.baseReps = baseReps
        self.restPauseReps = restPauseReps
        self.rpe = rpe
        self.forcedReps = forcedReps
        self.negatives = negatives
        self.forcedRepsCount = forcedRepsCount
        self.negativesCount = negativesCount
        self.isWarmup = isWarmup
        self.motorUnitRecruitment = recruitment
        self.isAbsoluteFailure = isAbsoluteFailure
    }
    
    // Helper to calculate total reps in the set
    var totalReps: Int {
        return baseReps + restPauseReps.reduce(0, +) + forcedRepsCount + negativesCount
    }
    
    // Helper to format the display string (e.g., "8 + 2 + 1")
    var displayReps: String {
        if restPauseReps.isEmpty {
            return "\(baseReps)"
        }
        let pauses = restPauseReps.map { "\($0)" }.joined(separator: " + ")
        return "\(baseReps) + \(pauses)"
    }
}

// MARK: - Routine Templates (The Program Builder)
@Model
class RoutineTemplate {
    var id: UUID
    var name: String // e.g., "Upper Body", "Chest & Back"
    var exercises: [String] // Ordered list of exercise names
    var lastPerformed: Date?
    
    init(name: String, exercises: [String]) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
    }
}

// MARK: - Global App State
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var isDrawerOpen: Bool = false
    @Published var activeRoutine: RoutineTemplate? = nil
    
    // The active queue of exercises to perform
    @Published var forgeQueue: [String] = []
    @Published var useIntensityAdjusted1RM: Bool = false
    
    // Live Workout Engine
    @Published var isWorkoutActive: Bool = false
    @Published var workoutStartTime: Date? = nil
    @Published var showWorkoutSummary: Bool = false
}

// MARK: - Custom User Exercises
@Model
class CustomExercise {
    @Attribute(.unique) var name: String
    
    var equipmentBrand: String?
    var resistanceType: String?
    
    init(name: String) {
        self.name = name
    }
}

// MARK: - User Profile
@Model
class UserProfile {
    @Attribute(.unique) var id: UUID
    var dateOfBirth: Date?
    var heightInCm: Double?
    var activityLevel: String
    
    init(dateOfBirth: Date? = nil, heightInCm: Double? = nil, activityLevel: String = "Sedentary") {
        self.id = UUID()
        self.dateOfBirth = dateOfBirth
        self.heightInCm = heightInCm
        self.activityLevel = activityLevel
    }
}

// MARK: - Progress Photos
@Model
class ProgressPhoto {
    var id: UUID
    var timestamp: Date
    var category: String // "Front", "Side", "Back"
    
    @Attribute(.externalStorage) var imageData: Data
    
    var dailyLog: DailyLog?
    
    init(timestamp: Date = Date(), category: String, imageData: Data) {
        self.id = UUID()
        self.timestamp = timestamp
        self.category = category
        self.imageData = imageData
    }
}

// MARK: - Shopping Item
@Model
class ShoppingItem {
    var id: UUID
    var name: String
    var isChecked: Bool
    var createdAt: Date
    
    init(name: String, isChecked: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isChecked = isChecked
        self.createdAt = Date()
    }
}

// MARK: - Body Measurements
@Model
class BodyMeasurement {
    var id: UUID
    var timestamp: Date
    
    var neckInches: Double?
    var waistInches: Double?
    var chestInches: Double?
    var thighsInches: Double?
    
    var dailyLog: DailyLog?
    
    init(neckInches: Double? = nil, waistInches: Double? = nil, chestInches: Double? = nil, thighsInches: Double? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        self.neckInches = neckInches
        self.waistInches = waistInches
        self.chestInches = chestInches
        self.thighsInches = thighsInches
    }
}

// MARK: - Custom Food
@Model
class CustomFood {
    var id: UUID
    var name: String
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    
    init(name: String, calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.id = UUID()
        self.name = name
        self.caloriesPer100g = calories
        self.proteinPer100g = protein
        self.carbsPer100g = carbs
        self.fatPer100g = fat
    }
}

// MARK: - Custom Recipe
@Model
class CustomRecipe {
    var id: UUID
    var name: String
    var instructions: String
    var ingredients: [String]
    
    init(name: String, instructions: String, ingredients: [String]) {
        self.id = UUID()
        self.name = name
        self.instructions = instructions
        self.ingredients = ingredients
    }
}

// MARK: - Fasting Session
@Model
class FastingSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    
    var duration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
    }
}

// MARK: - Nutrition & Metabolic Tracking
@Model
class FoodEntry {
    var id: UUID
    var name: String
    var calories: Int
    var protein: Int
    var fat: Int
    var carbs: Int
    
    // Electrolytes (mg)
    var sodium: Int
    var potassium: Int
    var magnesium: Int
    
    var timestamp: Date
    
    var dailyLog: DailyLog?
    
    init(name: String, calories: Int, protein: Int, fat: Int, carbs: Int, sodium: Int = 0, potassium: Int = 0, magnesium: Int = 0) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.sodium = sodium
        self.potassium = potassium
        self.magnesium = magnesium
        self.timestamp = Date()
    }
}

@Model
class MetabolicGoal {
    var id: UUID
    var targetWeight: Double
    var dailyCalorieTarget: Int
    var fatPercent: Double
    var proteinPercent: Double
    var carbPercent: Double
    var isAutopilotEnabled: Bool
    var lastUpdated: Date
    
    init(targetWeight: Double = 180.0, dailyCalorieTarget: Int = 2800, fatPercent: Double = 80.0, proteinPercent: Double = 20.0, carbPercent: Double = 0.0, isAutopilotEnabled: Bool = true) {
        self.id = UUID()
        self.targetWeight = targetWeight
        self.dailyCalorieTarget = dailyCalorieTarget
        self.fatPercent = fatPercent
        self.proteinPercent = proteinPercent
        self.carbPercent = carbPercent
        self.isAutopilotEnabled = isAutopilotEnabled
        self.lastUpdated = Date()
    }
}
