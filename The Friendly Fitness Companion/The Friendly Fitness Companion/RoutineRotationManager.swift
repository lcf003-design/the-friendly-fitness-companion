import Foundation

struct RoutineRotationManager {
    static func daysSinceLastHit(for routine: RoutineTemplate) -> Int? {
        guard let lastPerformed = routine.lastPerformed else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPerformed), to: calendar.startOfDay(for: Date()))
        return components.day
    }
    
    static func nextRoutineToHit(routines: [RoutineTemplate]) -> RoutineTemplate? {
        // Find the routine that was performed longest ago, or never performed
        return routines.min { (r1, r2) in
            switch (r1.lastPerformed, r2.lastPerformed) {
            case (nil, nil): return false
            case (nil, _): return true // unperformed routines take priority
            case (_, nil): return false
            case (let d1?, let d2?): return d1 < d2
            }
        }
    }
}
