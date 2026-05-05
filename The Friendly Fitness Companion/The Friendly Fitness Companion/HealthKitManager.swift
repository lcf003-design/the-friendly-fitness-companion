import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private var healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    @Published var activeCaloriesBurned: Double = 0.0
    @Published var sleepDurationMinutes: Int = 0
    
    // Define the specific types of health data we want to read
    private let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [activeEnergyType, sleepAnalysisType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
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
}
