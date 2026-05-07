import SwiftUI
import SwiftData
import Combine

class ExerciseLogViewModel: ObservableObject {
    @Published var weight: String = ""
    @Published var unit: String = UserDefaults.standard.string(forKey: "preferredUnit") ?? "lbs"
    @Published var baseReps: String = ""
    @Published var rpe: Double = 8.0
    @Published var isWarmup: Bool = false
    
    @Published var currentRestPauseExtraReps: String = ""
    @Published var completedRestPauseReps: [Int] = []
    
    @Published var forcedRepsCount: Int = 0
    @Published var negativesCount: Int = 0
    
    @Published var isTimerRunning: Bool = false
    @Published var restPauseTimer: Int = 15
    @Published var timerEndTime: Date?
    
    // Ghost Set tracking
    @Published var previousSetWeight: String?
    @Published var previousSetReps: String?
    @Published var previousSetUnit: String?
    
    // Machine Profile
    @Published var equipmentBrand: String = "Standard"
    @Published var resistanceType: String = "Free Weight"
    
    // Failure Audit
    @Published var isAbsoluteFailure: Bool? = nil
    
    // Progressive Overload Suggestions
    @Published var suggestedWeight: Double?
    @Published var isNewEstimated1RM: Bool = false
    
    // Submission State Enum
    enum SubmissionState {
        case idle, loading, success, error
    }
    @Published var submissionState: SubmissionState = .idle
    @Published var showValidationError: Bool = false
    @Published var validationErrorMessage: String = ""
    
    var recruitmentPercentage: Double {
        if isWarmup { return 0.0 }
        var base = min(rpe / 10.0, 0.90)
        if forcedRepsCount > 0 { base += 0.05 }
        if negativesCount > 0 { base += 0.05 }
        if !completedRestPauseReps.isEmpty || isTimerRunning { base += 0.05 }
        return min(base, 1.0)
    }
    
    func resetAfterSuccess() {
        completedRestPauseReps.removeAll()
        currentRestPauseExtraReps = ""
        forcedRepsCount = 0
        negativesCount = 0
        isWarmup = false
        isAbsoluteFailure = nil
        submissionState = .idle
    }
    
    func toggleRestPause() {
        if !isTimerRunning {
            isTimerRunning = true
            restPauseTimer = 15
            timerEndTime = Date().addingTimeInterval(15.0)
            HapticManager.shared.light()
        } else {
            isTimerRunning = false
            timerEndTime = nil
        }
    }
    
    func logRestPauseRep() {
        if let extra = Int(currentRestPauseExtraReps), extra > 0 {
            completedRestPauseReps.append(extra)
            currentRestPauseExtraReps = ""
            HapticManager.shared.medium()
        }
    }
    
    // Analyzes the last 3 sessions to suggest progressive overload
    func loadPreviousPerformance(exerciseName: String, dailyLogs: [DailyLog]) {
        // Find last 3 sessions for this exercise
        let pastWorkouts = dailyLogs.compactMap { log in
            log.workouts.first(where: { $0.exerciseName == exerciseName })
        }.prefix(3)
        
        guard let lastWorkout = pastWorkouts.first,
              let lastWorkingSet = lastWorkout.sets.last(where: { !$0.isWarmup }) else { return }
        
        // Populate standard ghost set (LAST)
        previousSetWeight = String(Int(lastWorkingSet.weight))
        previousSetReps = String(lastWorkingSet.baseReps)
        previousSetUnit = lastWorkingSet.unit
        
        weight = previousSetWeight ?? ""
        baseReps = previousSetReps ?? ""
        unit = previousSetUnit ?? "lbs"
        
        // Analyze last 2 sessions for "BEAT IT" rep target logic
        if pastWorkouts.count >= 2 {
            let session1 = pastWorkouts[0].sets.last(where: { !$0.isWarmup })
            let session2 = pastWorkouts[1].sets.last(where: { !$0.isWarmup })
            
            // Heuristic: If they hit >= 8 reps (typical target) in the last 2 sessions, suggest weight bump
            if let s1 = session1, let s2 = session2, s1.baseReps >= 8 && s2.baseReps >= 8 {
                let lowerBodyWords = ["squat", "deadlift", "leg", "calf", "glute", "press"]
                let isLowerBody = lowerBodyWords.contains { exerciseName.lowercased().contains($0) }
                let increment = isLowerBody ? 5.0 : 2.5
                suggestedWeight = lastWorkingSet.weight + increment
                
                // Estimate 1RM (Intensity-Adjusted)
                let effectiveReps = Double(lastWorkingSet.baseReps) + (Double(lastWorkingSet.forcedRepsCount) * 1.5) + (Double(lastWorkingSet.negativesCount) * 2.0)
                let last1RM = lastWorkingSet.weight * (1.0 + (effectiveReps / 30.0))
                
                // Assume if they hit 8 standard reps at the new weight
                let newSuggested1RM = (suggestedWeight ?? 0) * (1.0 + (8.0 / 30.0)) 
                
                if newSuggested1RM > last1RM {
                    isNewEstimated1RM = true
                }
            } else {
                suggestedWeight = lastWorkingSet.weight + 2.5 // Fallback generic progression
            }
        } else {
            suggestedWeight = lastWorkingSet.weight + 2.5 // Fallback if < 2 sessions
        }
    }
}
