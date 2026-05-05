import SwiftUI
import SwiftData

@main
struct The_Friendly_Fitness_CompanionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Inject SwiftData Model Container for our schemas
        .modelContainer(for: [
            DailyLog.self,
            WorkoutEntry.self,
            ExerciseSet.self,
            RoutineTemplate.self
        ])
    }
}
