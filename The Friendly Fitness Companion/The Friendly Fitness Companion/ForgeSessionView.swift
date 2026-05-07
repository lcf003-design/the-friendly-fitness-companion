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
                Color(red: 0.1, green: 0.1, blue: 0.1).ignoresSafeArea()
                
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
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(currentExerciseIndex > 0 ? .white : Color.white.opacity(0.3))
                                }
                                .disabled(currentExerciseIndex == 0)
                                
                                Spacer()
                                
                                Text(currentExercise)
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                
                                Spacer()
                                
                                Button(action: nextExercise) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(currentExerciseIndex < appState.forgeQueue.count - 1 ? .white : Color.white.opacity(0.3))
                                }
                                .disabled(currentExerciseIndex >= appState.forgeQueue.count - 1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            
                            // Last Session Pill
                            if let lastStats = lastSessionStats {
                                Button(action: {
                                    // Parse last stats and copy
                                    let parts = lastStats.split(separator: " ")
                                    if let w = Double(parts.first ?? ""), let r = Int(parts.last ?? "") {
                                        weight = w
                                        reps = r
                                        HapticManager.shared.light()
                                    }
                                }) {
                                    Text("Last Session: \(lastStats)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.4))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color(red: 0.2, green: 0.3, blue: 0.2))
                                        .cornerRadius(20)
                                }
                            }
                            
                            // Clean White Input Form
                            VStack(spacing: 0) {
                                // Weight Row
                                HStack {
                                    Text("Weight")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.black)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button(action: { if weight >= 5 { weight -= 5 }; HapticManager.shared.light() }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.black)
                                                .frame(width: 32, height: 32)
                                                .background(Color(white: 0.9))
                                                .cornerRadius(8)
                                        }
                                        Text("\(Int(weight))")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.black)
                                            .frame(width: 40, alignment: .center)
                                        Button(action: { weight += 5; HapticManager.shared.light() }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.black)
                                                .frame(width: 32, height: 32)
                                                .background(Color(white: 0.9))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color(white: 0.9)).padding(.leading, 20)
                                
                                // Reps Row
                                HStack {
                                    Text("Reps")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.black)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button(action: { if reps > 0 { reps -= 1 }; HapticManager.shared.light() }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.black)
                                                .frame(width: 32, height: 32)
                                                .background(Color(white: 0.9))
                                                .cornerRadius(8)
                                        }
                                        Text("\(reps)")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.black)
                                            .frame(width: 40, alignment: .center)
                                        Button(action: { reps += 1; HapticManager.shared.light() }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.black)
                                                .frame(width: 32, height: 32)
                                                .background(Color(white: 0.9))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color(white: 0.9)).padding(.leading, 20)
                                
                                // Failure Row
                                Toggle(isOn: $isAbsoluteFailure) {
                                    Text("Pushed to Failure")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.black)
                                }
                                .tint(Color(red: 0.3, green: 0.8, blue: 0.4))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .onChange(of: isAbsoluteFailure) { _, val in
                                    if val { HapticManager.shared.heavy() }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            
                            // Log Set Button
                            Button(action: logSet) {
                                Text("Log Set")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(red: 0.3, green: 0.8, blue: 0.4))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            
                            // Minimalist Ledger
                            if let workout = activeWorkout, !workout.sets.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, set in
                                        HStack(spacing: 16) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(Color(white: 0.4))
                                                .frame(width: 20, alignment: .leading)
                                            
                                            Rectangle()
                                                .fill(Color(white: 0.9))
                                                .frame(width: 1, height: 24)
                                            
                                            Text("\(Int(set.weight)) \(set.unit) x \(set.totalReps)")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(.black)
                                            
                                            Spacer()
                                            
                                            if set.isAbsoluteFailure == true {
                                                Text("🔥")
                                                    .font(.system(size: 16))
                                            }
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        
                                        if index < workout.sets.count - 1 {
                                            Divider().background(Color(white: 0.9)).padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
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
                    .foregroundColor(Color(white: 0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        finishSession()
                    }
                    .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.4))
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
