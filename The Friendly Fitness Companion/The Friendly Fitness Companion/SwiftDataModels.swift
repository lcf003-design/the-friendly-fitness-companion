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
    
    init(weight: Double, unit: String = "lbs", baseReps: Int, restPauseReps: [Int] = [], rpe: Double, forcedReps: Bool = false, negatives: Bool = false, forcedRepsCount: Int = 0, negativesCount: Int = 0, isWarmup: Bool = false, recruitment: Double) {
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
    @Published var activeRoutine: RoutineTemplate? = nil
    
    // The active queue of exercises to perform
    @Published var forgeQueue: [String] = []
    
    // Live Workout Engine
    @Published var isWorkoutActive: Bool = false
    @Published var workoutStartTime: Date? = nil
    @Published var showWorkoutSummary: Bool = false
}

// MARK: - Custom User Exercises
@Model
class CustomExercise {
    @Attribute(.unique) var name: String
    
    init(name: String) {
        self.name = name
    }
}
