import Foundation

struct ExerciseDefinition {
    let name: String
    let proTip: String
}

struct ExerciseLibrary {
    static let hitMovements: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Leg Press", proTip: "Drive out of the hole without locking the knees. Focus on a 4-second controlled negative."),
        ExerciseDefinition(name: "Hack Squat", proTip: "Keep the lower back pinned. Do not pause at the top or bottom; maintain continuous tension."),
        ExerciseDefinition(name: "Leg Extension", proTip: "Pause and flex forcefully at the top. Lower the weight under strict 4-second control."),
        ExerciseDefinition(name: "Lying Leg Curl", proTip: "Squeeze at peak contraction. The negative must be twice as slow as the positive."),
        ExerciseDefinition(name: "Machine Chest Press", proTip: "Pre-exhaust with Pec Deck. Keep elbows slightly flared and push until absolute failure."),
        ExerciseDefinition(name: "Incline Machine Press", proTip: "Isolate the upper pecs. If you hit failure, utilize a rest-pause of exactly 15 seconds."),
        ExerciseDefinition(name: "Pec Deck Fly", proTip: "Keep arms locked in a slight bend. Squeeze the pecs together for a full second at peak contraction."),
        ExerciseDefinition(name: "Dumbbell Pullover", proTip: "Drop the hips to maximize the stretch. Pull through using only the lats, not the triceps."),
        ExerciseDefinition(name: "Lat Pulldown", proTip: "Pull with the elbows, not the hands. Hold the contraction at the bottom before a 4-second negative."),
        ExerciseDefinition(name: "Machine Row", proTip: "Pin the chest to the pad. Do not use momentum; squeeze the scapula together at the peak."),
        ExerciseDefinition(name: "Lateral Raise", proTip: "Lead with the elbows, keeping the pinkies slightly elevated. Strict isolation is critical."),
        ExerciseDefinition(name: "Shoulder Press", proTip: "Stop an inch short of lockout to maintain tension on the deltoids. Lower slowly.")
    ]
    
    static func getTip(for name: String) -> String? {
        return hitMovements.first { $0.name.lowercased() == name.lowercased() }?.proTip
    }
}
