import SwiftUI
import SwiftData
import Combine

struct ForgeLogbookView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var exerciseName: String = "Select Movement"
    @State private var weight: String = ""
    @State private var unit: String = "lbs"
    @State private var baseReps: String = ""
    @State private var rpe: Double = 8.0
    
    // Rest-Pause Tracking
    @State private var currentRestPauseExtraReps: String = ""
    @State private var completedRestPauseReps: [Int] = []
    
    @State private var isShowingExercisePicker: Bool = false
    
    // Intensity Modifiers
    @State private var forcedReps: Bool = false
    @State private var negatives: Bool = false
    @State private var restPause: Bool = false
    @State private var restPauseTimer: Int = 15
    @State private var isTimerRunning: Bool = false
    
    // UI Feedback
    @State private var showSuccessFeedback: Bool = false
    
    // Background-Resilient Timer
    @State private var timerEndTime: Date?
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @Environment(\.scenePhase) private var scenePhase
    
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
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.5)
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
                        
                        // Exercise Name Button (Triggers Picker)
                        HStack {
                            Button(action: {
                                isShowingExercisePicker = true
                            }) {
                                HStack {
                                    Text(exerciseName)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right.circle.fill")
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                        .font(.title2)
                                }
                            }
                            
                            // Next Exercise Button if in a routine
                            if !appState.forgeQueue.isEmpty {
                                Button(action: advanceQueue) {
                                    Image(systemName: "forward.end.fill")
                                        .foregroundColor(.black)
                                        .padding(12)
                                        .background(FriendlyTheme.apexGreen)
                                        .clipShape(Circle())
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Weight and Reps
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("WEIGHT")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                    Spacer()
                                    // Unit Toggle
                                    Button(action: {
                                        unit = (unit == "lbs") ? "kg" : "lbs"
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }) {
                                        Text(unit.uppercased())
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(FriendlyTheme.apexGreen.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                TextField("0", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("BASE REPS")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .padding(.top, 4)
                                
                                TextField("0", text: $baseReps)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
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
                        
                        // Rest-Pause Engine
                        VStack(spacing: 12) {
                            // If we have completed some rest pause reps, show them
                            if !completedRestPauseReps.isEmpty {
                                HStack {
                                    Text("REST-PAUSE LOG:")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.mutedAmber)
                                    Spacer()
                                    let log = completedRestPauseReps.map { "\($0)" }.joined(separator: " + ")
                                    Text("+ \(log) reps")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundColor(FriendlyTheme.mutedAmber)
                                }
                            }
                            
                            // Timer Button
                            Button(action: toggleRestPause) {
                                HStack {
                                    Image(systemName: "timer")
                                    Text(isTimerRunning ? "REST: \(restPauseTimer)s" : "START REST-PAUSE")
                                }
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isTimerRunning ? FriendlyTheme.mutedAmber : Color.clear)
                                .foregroundColor(isTimerRunning ? FriendlyTheme.midnightMatte : FriendlyTheme.mutedAmber)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(FriendlyTheme.mutedAmber, lineWidth: isTimerRunning ? 0 : 2)
                                )
                            }
                            
                            // If timer has run at least once or is running, allow logging extra reps
                            if !isTimerRunning && (!completedRestPauseReps.isEmpty || restPause) {
                                HStack {
                                    TextField("Extra Reps", text: $currentRestPauseExtraReps)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color(white: 0.15))
                                        .cornerRadius(12)
                                    
                                    Button(action: logRestPauseRep) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding()
                                            .background(FriendlyTheme.mutedAmber)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.horizontal, 20)
                    
                    // Log Set Button (SwiftData Save)
                    Button(action: saveSet) {
                        Text("LOG SET")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(30)
                            .shadow(color: FriendlyTheme.apexGreen.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 20)
                    
                    // Workout History List
                    let todayLog = getOrCreateTodayLog()
                    if !todayLog.workouts.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TODAY'S FORGE")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .tracking(1.5)
                                .padding(.horizontal, 24)
                            
                            ForEach(todayLog.workouts) { workout in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(workout.exerciseName)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                    
                                    ForEach(Array(workout.sets.enumerated()), id: \.element.id) { index, set in
                                        HStack {
                                            Text("Set \(index + 1)")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(set.weight)) \(set.unit) × \(set.displayReps)")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            if !set.restPauseReps.isEmpty || set.forcedReps || set.negatives {
                                                Image(systemName: "flame.fill")
                                                    .foregroundColor(FriendlyTheme.mutedAmber)
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                                .padding(20)
                                .background(.ultraThinMaterial)
                                .cornerRadius(24)
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onReceive(timer) { _ in
            guard isTimerRunning, let endTime = timerEndTime else { return }
            let remaining = endTime.timeIntervalSinceNow
            
            if remaining <= 0 {
                restPauseTimer = 0
                isTimerRunning = false
                timerEndTime = nil
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else {
                restPauseTimer = Int(ceil(remaining))
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Timer automatically catches up when app is foregrounded because it uses Date()
            }
        }
        .onChange(of: appState.forgeQueue) { oldQueue, newQueue in
            if let first = newQueue.first, exerciseName != first {
                loadExerciseFromQueue(first)
            }
        }
        .onAppear {
            if let first = appState.forgeQueue.first, exerciseName == "Select Movement" {
                loadExerciseFromQueue(first)
            }
        }
        .sheet(isPresented: $isShowingExercisePicker) {
            ExercisePickerView(
                selectedExercise: $exerciseName,
                suggestedWeight: $weight,
                suggestedReps: $baseReps
            )
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
        
        let baseRepCount = Int(baseReps) ?? 0
        let weightAmount = Double(weight) ?? 0.0
        
        let newSet = ExerciseSet(
            weight: weightAmount,
            unit: unit,
            baseReps: baseRepCount,
            restPauseReps: completedRestPauseReps,
            rpe: rpe,
            forcedReps: forcedReps,
            negatives: negatives,
            recruitment: recruitmentPercentage
        )
        
        newSet.workoutEntry = workoutEntry
        workoutEntry.sets.append(newSet)
        modelContext.insert(newSet)
        
        // Update Daily Summary
        let setVolume = Double(newSet.totalReps) * weightAmount
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
        // Reset mini-state for the next set
        completedRestPauseReps.removeAll()
        currentRestPauseExtraReps = ""
        restPause = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccessFeedback = false }
        }
    }
    
    private func logRestPauseRep() {
        if let extra = Int(currentRestPauseExtraReps), extra > 0 {
            completedRestPauseReps.append(extra)
            currentRestPauseExtraReps = ""
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    // MARK: - Resilient Timer Logic
    private func toggleRestPause() {
        if !restPause {
            restPause = true
            isTimerRunning = true
            restPauseTimer = 15
            timerEndTime = Date().addingTimeInterval(15.0)
        } else {
            restPause = false
            isTimerRunning = false
            timerEndTime = nil
        }
    }
    
    // MARK: - Queue Logic
    private func loadExerciseFromQueue(_ exercise: String) {
        exerciseName = exercise
        
        // Auto-load previous performance
        for log in dailyLogs {
            if let workout = log.workouts.first(where: { $0.exerciseName == exercise }),
               let lastSet = workout.sets.last {
                weight = String(Int(lastSet.weight))
                baseReps = String(lastSet.baseReps)
                return
            }
        }
        
        // If no history, clear it
        weight = ""
        baseReps = ""
    }
    
    private func advanceQueue() {
        if !appState.forgeQueue.isEmpty {
            appState.forgeQueue.removeFirst()
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            if appState.forgeQueue.isEmpty {
                appState.activeRoutine = nil
                exerciseName = "Select Movement"
                weight = ""
                baseReps = ""
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
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? FriendlyTheme.apexGreen : Color.clear)
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
    }
}

#Preview {
    ForgeLogbookView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
