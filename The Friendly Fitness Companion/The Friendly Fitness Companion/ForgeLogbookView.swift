import SwiftUI
import SwiftData

struct ForgeLogbookView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var exerciseName: String = "Incline Machine Press"
    @State private var weight: String = "225"
    @State private var reps: String = "8"
    @State private var rpe: Double = 8.0
    
    // Intensity Modifiers
    @State private var forcedReps: Bool = false
    @State private var negatives: Bool = false
    @State private var restPause: Bool = false
    @State private var restPauseTimer: Int = 15
    @State private var isTimerRunning: Bool = false
    
    // UI Feedback
    @State private var showSuccessFeedback: Bool = false
    
    // Calculated Henneman Recruitment
    var recruitmentPercentage: Double {
        var base = min(rpe / 10.0, 0.90) // Caps at 90% without intensity techniques
        if forcedReps { base += 0.05 }
        if negatives { base += 0.05 }
        if restPause { base += 0.05 }
        return min(base, 1.0)
    }
    
    // Helper to get or create today's log
    private func getOrCreateTodayLog() -> DailyLog {
        let calendar = Calendar.current
        if let todayLog = dailyLogs.first(where: { calendar.isDateInToday($0.date) }) {
            return todayLog
        } else {
            let newLog = DailyLog()
            modelContext.insert(newLog)
            return newLog
        }
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                        Text("THE FORGE")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(.white)
                        Spacer()
                        
                        if showSuccessFeedback {
                            Text("LOGGED!")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Henneman Meter (Live Feedback)
                    HennemanMeterView(recruitmentLevel: recruitmentPercentage)
                        .padding(.top, -10)
                    
                    // Logging Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("CURRENT SET")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(1.5)
                        
                        // Exercise Name
                        TextField("Exercise Name", text: $exerciseName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        // Weight and Reps
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("WEIGHT (LBS)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("0", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("REPS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("0", text: $reps)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.vertical, 8)
                        
                        // RPE Slider
                        VStack(alignment: .leading) {
                            HStack {
                                Text("PROXIMITY TO FAILURE (RPE)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                Spacer()
                                Text("\(Int(rpe)) / 10")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FriendlyTheme.limeSignal)
                            }
                            
                            Slider(value: $rpe, in: 1...10, step: 1)
                                .accentColor(FriendlyTheme.limeSignal)
                        }
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.vertical, 8)
                        
                        // Heavy Duty Modifiers
                        Text("HEAVY DUTY MODIFIERS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        HStack(spacing: 12) {
                            IntensityButton(title: "FORCED REPS", isSelected: $forcedReps)
                            IntensityButton(title: "NEGATIVES", isSelected: $negatives)
                        }
                        
                        // Rest-Pause Timer Button
                        Button(action: toggleRestPause) {
                            HStack {
                                Image(systemName: "timer")
                                Text(restPause ? (isTimerRunning ? "REST-PAUSE: \(restPauseTimer)s" : "REST-PAUSE LOGGED") : "REST-PAUSE")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(restPause ? FriendlyTheme.mutedAmber : FriendlyTheme.midnightMatte)
                            .foregroundColor(restPause ? FriendlyTheme.midnightMatte : FriendlyTheme.mutedAmber)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(FriendlyTheme.mutedAmber, lineWidth: restPause ? 0 : 2)
                            )
                        }
                    }
                    .padding(24)
                    .background(FriendlyTheme.midnightMatteLight)
                    .cornerRadius(30)
                    .padding(.horizontal, 20)
                    
                    // Log Set Button (SwiftData Save)
                    Button(action: saveSet) {
                        Text("LOG SET")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.5)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - SwiftData Persistence
    private func saveSet() {
        let todayLog = getOrCreateTodayLog()
        
        // Check if workout entry already exists for this exercise today
        let workoutEntry: WorkoutEntry
        if let existingWorkout = todayLog.workouts.first(where: { $0.exerciseName == exerciseName }) {
            workoutEntry = existingWorkout
        } else {
            workoutEntry = WorkoutEntry(exerciseName: exerciseName)
            workoutEntry.dailyLog = todayLog
            todayLog.workouts.append(workoutEntry)
            modelContext.insert(workoutEntry)
        }
        
        let repCount = Int(reps) ?? 0
        let weightAmount = Double(weight) ?? 0.0
        
        let newSet = ExerciseSet(
            reps: repCount,
            weight: weightAmount,
            rpe: rpe,
            forcedReps: forcedReps,
            negatives: negatives,
            restPause: restPause,
            recruitment: recruitmentPercentage
        )
        
        newSet.workoutEntry = workoutEntry
        workoutEntry.sets.append(newSet)
        modelContext.insert(newSet)
        
        // Update Daily Summary
        let setVolume = Double(repCount) * weightAmount
        todayLog.totalVolume += setVolume
        if recruitmentPercentage > todayLog.maxMotorUnitRecruitment {
            todayLog.maxMotorUnitRecruitment = recruitmentPercentage
        }
        
        do {
            try modelContext.save()
            triggerSuccessFeedback()
        } catch {
            print("Failed to save set: \(error.localizedDescription)")
        }
    }
    
    private func triggerSuccessFeedback() {
        // Haptic feedback & UI confirmation
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        withAnimation { showSuccessFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccessFeedback = false }
        }
    }
    
    // MARK: - Timer Logic
    private func toggleRestPause() {
        if !restPause {
            restPause = true
            isTimerRunning = true
            restPauseTimer = 15
            startTimer()
        } else {
            restPause = false
            isTimerRunning = false
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !isTimerRunning || restPauseTimer <= 0 {
                isTimerRunning = false
                timer.invalidate()
            } else {
                restPauseTimer -= 1
            }
        }
    }
}

struct IntensityButton: View {
    var title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? FriendlyTheme.apexGreen : FriendlyTheme.midnightMatte)
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FriendlyTheme.apexGreen, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

#Preview {
    ForgeLogbookView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
