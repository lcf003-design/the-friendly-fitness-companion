import SwiftUI
import SwiftData

struct ForgeSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    @State private var currentExerciseIndex = 0
    @State private var weight: Double = 135
    @State private var reps: Int = 10
    @State private var isAbsoluteFailure: Bool = false
    
    @Query private var dailyLogs: [DailyLog]
    
    // Track the active workout entry to append sets
    @State private var activeWorkout: WorkoutEntry?
    
    private var currentExercise: String {
        if appState.forgeQueue.isEmpty {
            return "No Exercise Selected"
        }
        if currentExerciseIndex < appState.forgeQueue.count {
            return appState.forgeQueue[currentExerciseIndex]
        }
        return appState.forgeQueue.last ?? "No Exercise Selected"
    }
    
    private var lastSessionStats: String? {
        let current = currentExercise
        for log in dailyLogs {
            for workout in log.workouts {
                if let lastSet = workout.sets.reversed().first(where: { $0.workoutEntry?.exerciseName == current || current.contains($0.workoutEntry?.exerciseName ?? "") }) {
                    return "\(Int(lastSet.weight)) \(lastSet.unit) x \(lastSet.totalReps)"
                }
            }
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                if appState.forgeQueue.isEmpty {
                    Text("No exercises in queue.")
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .font(.system(size: 14, weight: .medium))
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Exercise Selector Header
                            HStack {
                                Button(action: previousExercise) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(currentExerciseIndex > 0 ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary.opacity(0.3))
                                }
                                .disabled(currentExerciseIndex == 0)
                                
                                Spacer()
                                
                                Text(currentExercise)
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                
                                Spacer()
                                
                                Button(action: nextExercise) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(currentExerciseIndex < appState.forgeQueue.count - 1 ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary.opacity(0.3))
                                }
                                .disabled(currentExerciseIndex >= appState.forgeQueue.count - 1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            
                            if let lastStats = lastSessionStats {
                                Button(action: {
                                    // Parse last stats and copy (naive parse for prototype)
                                    let parts = lastStats.split(separator: " ")
                                    if let w = Double(parts.first ?? ""), let r = Int(parts.last ?? "") {
                                        weight = w
                                        reps = r
                                        HapticManager.shared.light()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                        Text("Last Session: \(lastStats)")
                                    }
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(FriendlyTheme.apexGreen.opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                            
                            // Clean Logging Input Form
                            VStack(spacing: 0) {
                                // Weight Row
                                HStack {
                                    Text("Weight")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button(action: { if weight >= 5 { weight -= 5 }; HapticManager.shared.light() }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                                .font(.system(size: 24))
                                        }
                                        Text("\(Int(weight))")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 60, alignment: .center)
                                        Button(action: { weight += 5; HapticManager.shared.light() }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(FriendlyTheme.apexGreen)
                                                .font(.system(size: 24))
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                                
                                // Reps Row
                                HStack {
                                    Text("Reps")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button(action: { if reps > 0 { reps -= 1 }; HapticManager.shared.light() }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                                .font(.system(size: 24))
                                        }
                                        Text("\(reps)")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 60, alignment: .center)
                                        Button(action: { reps += 1; HapticManager.shared.light() }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(FriendlyTheme.apexGreen)
                                                .font(.system(size: 24))
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                                
                                // Failure Row
                                Toggle(isOn: $isAbsoluteFailure) {
                                    Text("Pushed to Failure")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .tint(FriendlyTheme.limeSignal)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .onChange(of: isAbsoluteFailure) { _, val in
                                    if val { HapticManager.shared.heavy() }
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            
                            // Log Set Button
                            Button(action: logSet) {
                                Text("Log Set")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(FriendlyTheme.apexGreen)
                                    .foregroundColor(.black)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                            
                            // Minimalist Ledger
                            if let workout = activeWorkout, !workout.sets.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("TODAY'S SETS")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 8)
                                        .padding(.top, 16)
                                    
                                    VStack(spacing: 0) {
                                        ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, set in
                                            HStack {
                                                Text("\(index + 1)")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(FriendlyTheme.textSecondary)
                                                    .frame(width: 24, alignment: .leading)
                                                
                                                Text("\(Int(set.weight)) \(set.unit) × \(set.totalReps)")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                if set.isAbsoluteFailure == true {
                                                    Image(systemName: "flame.fill")
                                                        .foregroundColor(FriendlyTheme.limeSignal)
                                                        .font(.system(size: 14))
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            
                                            if index < workout.sets.count - 1 {
                                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 44)
                                            }
                                        }
                                    }
                                    .background(Color.white.opacity(0.02))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        appState.showLiveForge = false
                    }
                    .foregroundColor(FriendlyTheme.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Logbook")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        finishSession()
                    }
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if !appState.forgeQueue.isEmpty {
                    startNewWorkoutEntry()
                }
            }
        }
    }
    
    private func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            startNewWorkoutEntry()
            HapticManager.shared.light()
        }
    }
    
    private func nextExercise() {
        if currentExerciseIndex < appState.forgeQueue.count - 1 {
            currentExerciseIndex += 1
            startNewWorkoutEntry()
            HapticManager.shared.light()
        }
    }
    
    private func startNewWorkoutEntry() {
        let entry = WorkoutEntry(exerciseName: currentExercise)
        let log = getOrCreateTodayLog()
        log.workouts.append(entry)
        activeWorkout = entry
        try? modelContext.save()
    }
    
    private func getOrCreateTodayLog() -> DailyLog {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        if let existing = dailyLogs.first(where: { $0.id == todayStr }) {
            return existing
        } else {
            let newLog = DailyLog(date: Date())
            modelContext.insert(newLog)
            return newLog
        }
    }
    
    private func calculateRecruitment(weight: Double, reps: Int, isFailure: Bool) -> Double {
        var base = (weight / 300.0) * 0.4
        if isFailure {
            base += 0.6
        } else {
            base += Double(reps) * 0.02
        }
        return min(max(base, 0.0), 1.0)
    }
    
    private func logSet() {
        guard let workout = activeWorkout else { return }
        
        let recruitment = calculateRecruitment(weight: weight, reps: reps, isFailure: isAbsoluteFailure)
        
        let newSet = ExerciseSet(
            weight: weight,
            unit: preferredUnit,
            baseReps: reps,
            rpe: isAbsoluteFailure ? 10.0 : 8.0,
            recruitment: recruitment,
            isAbsoluteFailure: isAbsoluteFailure
        )
        
        workout.sets.append(newSet)
        
        let log = getOrCreateTodayLog()
        log.totalVolume += (weight * Double(reps))
        if recruitment > log.maxMotorUnitRecruitment {
            log.maxMotorUnitRecruitment = recruitment
        }
        
        try? modelContext.save()
        HapticManager.shared.success()
        isAbsoluteFailure = false
    }
    
    private func finishSession() {
        HapticManager.shared.medium()
        appState.showLiveForge = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.showWorkoutSummary = true
        }
    }
}
