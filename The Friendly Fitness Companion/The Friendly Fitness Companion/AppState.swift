import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var activeRoutine: RoutineTemplate? = nil
    
    // The active queue of exercises to perform
    @Published var forgeQueue: [String] = []
}
