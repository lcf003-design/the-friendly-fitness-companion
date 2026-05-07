import SwiftUI
import SwiftData
import Charts

struct TrainingLedgerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    // Flatten workouts for the ledger view
    var allWorkouts: [(date: Date, workout: WorkoutEntry)] {
        var results: [(Date, WorkoutEntry)] = []
        for log in dailyLogs {
            for workout in log.workouts {
                results.append((log.date, workout))
            }
        }
        return results.sorted(by: { $0.0 > $1.0 })
    }
    
    // Sparkline Chart Data
    struct IntensityPoint: Identifiable {
        let id = UUID()
        let date: Date
        let intensity: Double
    }
    
    var weeklyIntensityData: [IntensityPoint] {
        let sortedLogs = dailyLogs.sorted(by: { $0.date > $1.date }).prefix(7)
        return sortedLogs.map { IntensityPoint(date: $0.date, intensity: $0.maxMotorUnitRecruitment) }.reversed()
    }
    
    // Progression Analytics Module
    @State private var selectedAnalyticsExercise: String = "Leg Press"
    
    var progressionAnalyticsData: [(date: Date, weight: Double, intensity: Double)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var data: [(Date, Double, Double)] = []
        
        for log in dailyLogs where log.date >= thirtyDaysAgo {
            let workoutsForExercise = log.workouts.filter { $0.exerciseName == selectedAnalyticsExercise }
            if !workoutsForExercise.isEmpty {
                var maxWeight: Double = 0
                var peakIntensity: Double = 0
                
                for workout in workoutsForExercise {
                    for set in workout.sets {
                        if set.weight > maxWeight { maxWeight = set.weight }
                        if set.motorUnitRecruitment > peakIntensity { peakIntensity = set.motorUnitRecruitment }
                    }
                }
                
                if maxWeight > 0 || peakIntensity > 0 {
                    data.append((log.date, maxWeight, peakIntensity))
                }
            }
        }
        return data.sorted { $0.0 < $1.0 }
    }
    
    var uniqueExercises: [String] {
        var names: Set<String> = []
        for log in dailyLogs {
            for workout in log.workouts {
                names.insert(workout.exerciseName)
            }
        }
        return Array(names).sorted()
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Organic Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    
                    Spacer()
                    
                    Text("Training Ledger")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.clear) // Balance
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Divider().background(Color.white.opacity(0.1))
                
                if !weeklyIntensityData.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly intensity trend")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Chart {
                            ForEach(weeklyIntensityData) { point in
                                LineMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value("Intensity", point.intensity)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(gradient: Gradient(colors: [FriendlyTheme.limeSignal, FriendlyTheme.apexGreen]), startPoint: .leading, endPoint: .trailing)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                
                                AreaMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value("Intensity", point.intensity)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(gradient: Gradient(colors: [FriendlyTheme.apexGreen.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom)
                                )
                            }
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(height: 60)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    
                    Divider().background(Color.white.opacity(0.1))
                }
                
                if !uniqueExercises.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Progression analytics (30 days)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            Spacer()
                            Picker("Exercise", selection: $selectedAnalyticsExercise) {
                                ForEach(uniqueExercises, id: \.self) { ex in
                                    Text(ex).tag(ex)
                                }
                            }
                            .tint(FriendlyTheme.apexGreen)
                        }
                        
                        if !progressionAnalyticsData.isEmpty {
                            Chart {
                                ForEach(progressionAnalyticsData, id: \.date) { point in
                                    // Intensity Line
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("Intensity", point.intensity)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(FriendlyTheme.limeSignal)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    
                                    // Max Weight Line
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("Weight", point.weight)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(FriendlyTheme.apexGreen)
                                    .lineStyle(StrokeStyle(lineWidth: 3, dash: [5, 5]))
                                }
                            }
                            .chartYScale(range: .plotDimension(padding: 10))
                            .frame(height: 120)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Circle().fill(FriendlyTheme.limeSignal).frame(width: 8, height: 8)
                                    Text("Peak Intensity").font(.system(size: 10, weight: .bold)).foregroundColor(FriendlyTheme.textSecondary)
                                }
                                HStack(spacing: 4) {
                                    Circle().fill(FriendlyTheme.apexGreen).frame(width: 8, height: 8)
                                    Text("Max Weight").font(.system(size: 10, weight: .bold)).foregroundColor(FriendlyTheme.textSecondary)
                                }
                            }
                            .padding(.top, -4)
                        } else {
                            Text("No data for \(selectedAnalyticsExercise) in the last 30 days.")
                                .font(.system(size: 14))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .onAppear {
                        if !uniqueExercises.contains(selectedAnalyticsExercise), let first = uniqueExercises.first {
                            selectedAnalyticsExercise = first
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                }
                
                if allWorkouts.isEmpty {
                    Spacer()
                    Text("No past events")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(allWorkouts, id: \.workout.id) { item in
                                LedgerRowView(date: item.date, workout: item.workout)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .padding(.bottom, 120) // padding for tab bar
                    }
                }
            }
        }
    }
}

struct LedgerRowView: View {
    let date: Date
    let workout: WorkoutEntry
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    @State private var showSummary = false
    
    var isHeavyDuty: Bool {
        workout.sets.contains { $0.isAbsoluteFailure ?? false }
    }
    
    var totalTonnage: Double {
        workout.sets.reduce(Double(0)) { $0 + ($1.weight * Double($1.totalReps)) }
    }
    
    var body: some View {
        Button(action: { showSummary = true }) {
            HStack(spacing: 16) {
                // Icon Background
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(FriendlyTheme.mutedAmber)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.exerciseName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(totalTonnage)) \(preferredUnit)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(FriendlyTheme.calmBlue)
                    
                    if isHeavyDuty {
                        Text("High Intensity")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSummary) {
            // Reusing existing workout summary card or building a dense summary
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                VStack {
                    HStack {
                        Spacer()
                        Text("Workout Summary")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    Text(workout.exerciseName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, set in
                                HStack {
                                    Text("Set \(index + 1)")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text("\(Int(set.weight)) \(preferredUnit) × \(set.totalReps)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if set.isAbsoluteFailure == true {
                                        Text("Failure")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(8)
                                    }
                                    if set.forcedReps {
                                        Image(systemName: "bolt.fill")
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                    }
                                    if set.negatives {
                                        Image(systemName: "arrow.down.to.line.alt")
                                            .foregroundColor(.red)
                                    }
                                    if set.hasRestPause == true {
                                        Image(systemName: "pause.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("\(Int(set.motorUnitRecruitment * 100))%")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(FriendlyTheme.apexGreen.opacity(0.2))
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                        .cornerRadius(4)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
