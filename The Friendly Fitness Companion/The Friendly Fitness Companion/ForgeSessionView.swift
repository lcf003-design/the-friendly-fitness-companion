import SwiftUI
import SwiftData

struct ForgeSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
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
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        appState.showLiveForge = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    Spacer()
                    Text("LIVE FORGE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.apexGreen)
                    Spacer()
                    Button(action: finishSession) {
                        Text("FINISH")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if appState.forgeQueue.isEmpty {
                    Spacer()
                    Text("No exercises in queue.")
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                } else {
                    // Exercise Title
                    HStack {
                        Button(action: previousExercise) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(currentExerciseIndex > 0 ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary.opacity(0.3))
                        }
                        .disabled(currentExerciseIndex == 0)
                        
                        Spacer()
                        
                        Text(currentExercise.uppercased())
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                        
                        Spacer()
                        
                        Button(action: nextExercise) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(currentExerciseIndex < appState.forgeQueue.count - 1 ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary.opacity(0.3))
                        }
                        .disabled(currentExerciseIndex >= appState.forgeQueue.count - 1)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Massive Typography Controls
                    HStack(spacing: 40) {
                        // Weight
                        VStack(spacing: 8) {
                            Text("WEIGHT (LBS)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.textSecondary)
                            
                            HStack(spacing: 16) {
                                Button("-") { 
                                    if weight >= 5 { weight -= 5 }
                                    HapticManager.shared.light()
                                }
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                
                                Text("\(Int(weight))")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 120)
                                
                                Button("+") { 
                                    weight += 5
                                    HapticManager.shared.light()
                                }
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 40)
                    
                    // Reps
                    VStack(spacing: 8) {
                        Text("REPS")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        HStack(spacing: 16) {
                            Button("-") { 
                                if reps > 0 { reps -= 1 }
                                HapticManager.shared.light()
                            }
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            
                            Text("\(reps)")
                                .font(.system(size: 64, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 100)
                            
                            Button("+") { 
                                reps += 1
                                HapticManager.shared.light()
                            }
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Failure Toggle
                    VStack(spacing: 16) {
                        Toggle(isOn: $isAbsoluteFailure) {
                            Text("HIT ABSOLUTE FAILURE?")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(1.0)
                                .foregroundColor(isAbsoluteFailure ? FriendlyTheme.limeSignal : .white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: FriendlyTheme.limeSignal))
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isAbsoluteFailure ? FriendlyTheme.limeSignal : Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 24)
                        .onChange(of: isAbsoluteFailure) { _, val in
                            if val {
                                HapticManager.shared.heavy()
                            }
                        }
                        
                        // The Audit
                        Text(isAbsoluteFailure ? "HEAVY DUTY CERTIFIED" : "Push to failure next set for maximum recruitment.")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(isAbsoluteFailure ? FriendlyTheme.limeSignal : FriendlyTheme.textSecondary)
                            .tracking(isAbsoluteFailure ? 2.0 : 0)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Henneman Meter Live
                    VStack(spacing: 8) {
                        let recruitment = calculateRecruitment(weight: weight, reps: reps, isFailure: isAbsoluteFailure)
                        HennemanMeterView(recruitmentLevel: recruitment, isFailure: isAbsoluteFailure)
                            .padding(.horizontal, 24)
                    }
                    
                    // Log Set Button
                    Button(action: logSet) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("LOG SET")
                        }
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(FriendlyTheme.apexGreen)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                        .shadow(color: FriendlyTheme.apexGreen.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if !appState.forgeQueue.isEmpty {
                startNewWorkoutEntry()
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
            unit: "lbs",
            baseReps: reps,
            rpe: isAbsoluteFailure ? 10.0 : 8.0,
            recruitment: recruitment,
            isAbsoluteFailure: isAbsoluteFailure
        )
        
        workout.sets.append(newSet)
        
        // Update DailyLog total volume
        let log = getOrCreateTodayLog()
        log.totalVolume += (weight * Double(reps))
        if recruitment > log.maxMotorUnitRecruitment {
            log.maxMotorUnitRecruitment = recruitment
        }
        
        try? modelContext.save()
        
        HapticManager.shared.success()
        
        // Reset toggle for next set
        isAbsoluteFailure = false
    }
    
    private func finishSession() {
        HapticManager.shared.medium()
        appState.showLiveForge = false
        // Trigger the summary in ForgeLogbookView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.showWorkoutSummary = true
        }
    }
}
