import Foundation
import HealthKit

let startDate = Date()
let endDate = Date()
let metadata: [String: Any] = [:]

let workout1 = HKWorkout(
    activityType: .traditionalStrengthTraining,
    start: startDate,
    end: endDate,
    workoutEvents: nil,
    totalEnergyBurned: nil,
    totalDistance: nil,
    metadata: metadata
)
