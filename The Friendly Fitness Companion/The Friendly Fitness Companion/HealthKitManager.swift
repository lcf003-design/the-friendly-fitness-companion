import Foundation
import HealthKit
import Combine
import SwiftData

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private var healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    @Published var activeCaloriesBurned: Double = 0.0
    @Published var sleepDurationMinutes: Int = 0
    
    // Define the specific types of health data we want to read
    private let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    
    // Clinical Markers
    private let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    private let bloodPressureSystolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
    private let bloodPressureDiastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    private let bloodGlucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
    private let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            activeEnergyType, sleepAnalysisType,
            restingHeartRateType, bloodPressureSystolicType,
            bloodPressureDiastolicType, bloodGlucoseType, bodyMassType
        ]
        let typesToWrite: Set<HKSampleType> = [HKObjectType.workoutType()]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.fetchTodayActiveEnergy()
                    self?.fetchLastNightSleep()
                } else {
                    self?.isAuthorized = false
                    if let error = error {
                        print("HealthKit Authorization Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func fetchTodayActiveEnergy() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch Active Energy: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.activeCaloriesBurned = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        healthStore.execute(query)
    }
    
    func fetchLastNightSleep() {
        // Look back 24 hours to capture sleep from the previous night
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            
            guard let categorySamples = samples as? [HKCategorySample], error == nil else {
                print("Failed to fetch Sleep data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            var totalSleepMinutes: Double = 0
            
            for sample in categorySamples {
                // value == 0 typically indicates InBed, value == 1 indicates Asleep
                // For this MVP, we will count total Asleep time
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleepMinutes += sample.endDate.timeIntervalSince(sample.startDate) / 60
                }
            }
            
            DispatchQueue.main.async {
                self?.sleepDurationMinutes = Int(totalSleepMinutes)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Clinical Data Polling
    func pollClinicalData(modelContext: SwiftData.ModelContext, dailyLog: DailyLog) {
        guard isAuthorized else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Fetch Weight
        let weightQuery = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let weight = sample.quantity.doubleValue(for: HKUnit.pound())
                DispatchQueue.main.async {
                    if !dailyLog.bodyMeasurements.contains(where: { abs(($0.bodyWeight ?? 0) - weight) < 0.1 }) {
                        let measurement = BodyMeasurement(bodyWeight: weight, timestamp: sample.endDate)
                        dailyLog.bodyMeasurements.append(measurement)
                        try? modelContext.save()
                    }
                }
            }
        }
        
        // Fetch Blood Glucose
        let glucoseQuery = HKSampleQuery(sampleType: bloodGlucoseType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let glucose = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
                DispatchQueue.main.async {
                    let record = HealthRecord(timestamp: sample.endDate)
                    record.bloodGlucose = glucose
                    record.notes = "Apple Health Sync"
                    modelContext.insert(record)
                    try? modelContext.save()
                }
            }
        }
        
        // Fetch RHR
        let rhrQuery = HKSampleQuery(sampleType: restingHeartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let rhr = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                DispatchQueue.main.async {
                    let record = HealthRecord(timestamp: sample.endDate)
                    record.restingHeartRate = rhr
                    record.notes = "Apple Health Sync"
                    modelContext.insert(record)
                    try? modelContext.save()
                }
            }
        }
        
        // Fetch BP
        let bpSystolicQuery = HKSampleQuery(sampleType: bloodPressureSystolicType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, sysSamples, _ in
            let bpDiastolicQuery = HKSampleQuery(sampleType: self.bloodPressureDiastolicType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, diaSamples, _ in
                if let sysSample = sysSamples?.first as? HKQuantitySample,
                   let diaSample = diaSamples?.first as? HKQuantitySample,
                   sysSample.startDate == diaSample.startDate {
                    let sys = sysSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                    let dia = diaSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                    DispatchQueue.main.async {
                        let record = HealthRecord(timestamp: sysSample.endDate)
                        record.bloodPressureSystolic = sys
                        record.bloodPressureDiastolic = dia
                        record.notes = "Apple Health Sync"
                        modelContext.insert(record)
                        try? modelContext.save()
                    }
                }
            }
            self.healthStore.execute(bpDiastolicQuery)
        }
        
        healthStore.execute(weightQuery)
        healthStore.execute(glucoseQuery)
        healthStore.execute(rhrQuery)
        healthStore.execute(bpSystolicQuery)
    }
    
    // Save workout to Apple Health
    func saveWorkout(workout: WorkoutEntry, startDate: Date, endDate: Date) {
        guard isAuthorized else { return }
        
        // Calculate total sets and volume
        let totalSets = workout.sets.count
        let totalVolume = workout.sets.reduce(0) { $0 + ($1.weight * Double($1.totalReps)) }
        
        // Custom metadata mapping
        let metadata: [String: Any] = [
            HKMetadataKeyIndoorWorkout: true,
            "TotalVolumeLbs": totalVolume,
            "TotalSets": totalSets,
            "ExerciseName": workout.exerciseName
        ]
        
        let hkWorkout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: nil, // Could be estimated based on volume
            totalDistance: nil,
            device: HKDevice.local(),
            metadata: metadata
        )
        
        healthStore.save(hkWorkout) { success, error in
            if success {
                print("Successfully saved workout '\(workout.exerciseName)' to HealthKit.")
            } else {
                print("Failed to save workout to HealthKit: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
