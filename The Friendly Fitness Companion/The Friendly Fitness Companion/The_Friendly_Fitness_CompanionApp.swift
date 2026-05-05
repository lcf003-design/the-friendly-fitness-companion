import SwiftUI
import SwiftData

@main
struct The_Friendly_Fitness_CompanionApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
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
