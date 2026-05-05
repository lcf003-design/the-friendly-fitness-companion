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

// MARK: - Global App State
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var activeRoutine: RoutineTemplate? = nil
    
    // The active queue of exercises to perform
    @Published var forgeQueue: [String] = []
}
