import SwiftUI
import SwiftData
import Combine

struct ForgeLogbookView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var isShowingExercisePicker: Bool = false
    @State private var showSuccessFeedback: Bool = false
    
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
    
    var globalRecruitmentPercentage: Double {
        let today = getOrCreateTodayLog()
        return today.maxMotorUnitRecruitment
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(spacing: 0) {
                // Persistent Header Area
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                        Text("THE LOGBOOK")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundColor(.white)
                        Spacer()
                        
                        if !appState.forgeQueue.isEmpty {
                            Button(action: { appState.forgeQueue.removeAll() }) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Henneman Meter (Pinned)
                    HennemanMeterView(recruitmentLevel: globalRecruitmentPercentage)
                        .padding(.bottom, 8)
                }
                .background(FriendlyTheme.midnightMatte.opacity(0.95))
                .zIndex(1)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // The Journal Queue
                        if !appState.forgeQueue.isEmpty {
                            VStack(spacing: 24) {
                                ForEach(appState.forgeQueue, id: \.self) { exercise in
                                    ExerciseLogCard(exerciseName: exercise, showSuccessFeedback: $showSuccessFeedback)
                                }
                            }
                            .padding(.top, 16)
                        }
                        
                        // Add Exercise Button
                        Button(action: {
                            isShowingExercisePicker = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(appState.forgeQueue.isEmpty ? "ADD EXERCISE TO START" : "ADD EXERCISE")
                            }
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appState.forgeQueue.isEmpty ? AnyShapeStyle(FriendlyTheme.apexGreen.opacity(0.2)) : AnyShapeStyle(.ultraThinMaterial))
                            .foregroundColor(appState.forgeQueue.isEmpty ? FriendlyTheme.apexGreen : .white)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, appState.forgeQueue.isEmpty ? 40 : 0)
                        
                        // Workout History List (Today's Sets)
                        let todayLog = getOrCreateTodayLog()
                        if !todayLog.workouts.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("TODAY'S FORGE")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .tracking(1.5)
                                    .padding(.horizontal, 24)
                                
                                ForEach(todayLog.workouts) { workout in
                                    if !workout.sets.isEmpty {
                                        WorkoutHistoryCard(workout: workout, modelContext: modelContext)
                                    }
                                }
                            }
                            .padding(.top, 30)
                        }
                    }
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Success Overlay
            if showSuccessFeedback {
                VStack {
                    Spacer()
                    Text("SET LOGGED")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(FriendlyTheme.apexGreen)
                        .foregroundColor(.black)
                        .cornerRadius(30)
                        .shadow(color: FriendlyTheme.apexGreen.opacity(0.4), radius: 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                }
                .zIndex(2)
            }
        }
        .sheet(isPresented: $isShowingExercisePicker) {
            ExercisePickerViewAdapter(isShowing: $isShowingExercisePicker)
        }
    }
}

// MARK: - Workout History Card with Deletion
struct WorkoutHistoryCard: View {
    let workout: WorkoutEntry
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(workout.exerciseName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.apexGreen)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            ForEach(Array(workout.sets.enumerated()), id: \.element.id) { index, set in
                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        if set.isWarmup {
                            Text("W\(index + 1)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(FriendlyTheme.mutedAmber)
                                .frame(width: 40, alignment: .leading)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .frame(width: 40, alignment: .leading)
                        }
                        
                        Text("\(Int(set.weight)) \(set.unit) × \(set.displayReps)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(set.isWarmup ? FriendlyTheme.textSecondary : .white)
                            .strikethrough(set.isWarmup, color: FriendlyTheme.textSecondary)
                        
                        if set.forcedRepsCount > 0 {
                            Text("+\(set.forcedRepsCount)F")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(FriendlyTheme.mutedAmber)
                                .padding(4)
                                .background(FriendlyTheme.mutedAmber.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if set.negativesCount > 0 {
                            Text("+\(set.negativesCount)N")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            deleteSet(set)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(FriendlyTheme.textSecondary.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
        .padding(.horizontal, 20)
    }
    
    private func deleteSet(_ set: ExerciseSet) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        workout.sets.removeAll(where: { $0.id == set.id })
        modelContext.delete(set)
        try? modelContext.save()
    }
}

// MARK: - Individual Exercise Card (Premium Redesign)
struct ExerciseLogCard: View {
    let exerciseName: String
    @Binding var showSuccessFeedback: Bool
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var weight: String = ""
    @State private var unit: String = "lbs"
    @State private var baseReps: String = ""
    @State private var rpe: Double = 8.0
    @State private var isWarmup: Bool = false
    
    @State private var currentRestPauseExtraReps: String = ""
    @State private var completedRestPauseReps: [Int] = []
    
    @State private var forcedRepsCount: Int = 0
    @State private var negativesCount: Int = 0
    
    @State private var isTimerRunning: Bool = false
    @State private var restPauseTimer: Int = 15
    @State private var timerEndTime: Date?
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // Ghost Set tracking
    @State private var previousSetWeight: String?
    @State private var previousSetReps: String?
    @State private var previousSetUnit: String?
    
    var recruitmentPercentage: Double {
        if isWarmup { return 0.0 }
        var base = min(rpe / 10.0, 0.90)
        if forcedRepsCount > 0 { base += 0.05 }
        if negativesCount > 0 { base += 0.05 }
        if !completedRestPauseReps.isEmpty || isTimerRunning { base += 0.05 }
        return min(base, 1.0)
    }
    
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
        VStack(alignment: .leading, spacing: 0) {
            // Header: Name & Remove Button
            HStack {
                Text(exerciseName)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .rigid)
                    impact.impactOccurred()
                    appState.forgeQueue.removeAll(where: { $0 == exerciseName })
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(20)
            
            // Premium Ghost Set Display (Industry Standard for Progressive Overload)
            if let prevWeight = previousSetWeight, let prevReps = previousSetReps, let prevUnit = previousSetUnit {
                Button(action: {
                    // Auto-fill from Ghost Set
                    weight = prevWeight
                    baseReps = prevReps
                    unit = prevUnit
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Text("LAST WORKOUT:")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        Text("\(prevWeight) \(prevUnit) × \(prevReps)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Set Type Toggle (Warmup vs Working)
            HStack {
                Text("SET TYPE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .tracking(1.0)
                Spacer()
                
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation { isWarmup = true }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Text("WARMUP")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isWarmup ? FriendlyTheme.mutedAmber : Color.clear)
                            .foregroundColor(isWarmup ? .black : FriendlyTheme.textSecondary)
                    }
                    
                    Button(action: {
                        withAnimation { isWarmup = false }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Text("WORKING")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(!isWarmup ? FriendlyTheme.apexGreen : Color.clear)
                            .foregroundColor(!isWarmup ? .black : FriendlyTheme.textSecondary)
                    }
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Core Inputs (Weight & Reps)
            HStack(spacing: 20) {
                // Weight Column
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("WEIGHT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(1.0)
                        Spacer()
                        Button(action: {
                            unit = (unit == "lbs") ? "kg" : "lbs"
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Text(unit.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FriendlyTheme.apexGreen.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    TextField("0", text: $weight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
                
                Divider().background(Color.white.opacity(0.1)).frame(height: 50)
                
                // Reps Column
                VStack(alignment: .leading, spacing: 8) {
                    Text("REPS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .tracking(1.0)
                        .padding(.top, 4)
                    
                    TextField("0", text: $baseReps)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            
            Divider().background(Color.white.opacity(0.1))
            
            if !isWarmup {
                // Proximity to Failure (RPE)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("PROXIMITY TO FAILURE (RPE)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(1.0)
                        Spacer()
                        Text("\(Int(rpe)) / 10")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(FriendlyTheme.limeSignal)
                    }
                    Slider(value: $rpe, in: 1...10, step: 1)
                        .accentColor(FriendlyTheme.limeSignal)
                }
                .padding(20)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Advanced Modifiers (Forced & Negatives)
                VStack(alignment: .leading, spacing: 16) {
                    Text("BEYOND FAILURE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 16) {
                        StepperRow(title: "FORCED", value: $forcedRepsCount, color: FriendlyTheme.mutedAmber)
                        StepperRow(title: "NEGATIVES", value: $negativesCount, color: .red)
                    }
                }
                .padding(20)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Rest-Pause Engine
                VStack(spacing: 16) {
                    if !completedRestPauseReps.isEmpty {
                        HStack {
                            Text("REST-PAUSE LOG")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .tracking(1.0)
                            Spacer()
                            let log = completedRestPauseReps.map { "\($0)" }.joined(separator: " + ")
                            Text("+ \(log) reps")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(FriendlyTheme.mutedAmber)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: toggleRestPause) {
                            HStack {
                                Image(systemName: "timer")
                                Text(isTimerRunning ? "REST: \(restPauseTimer)s" : "REST-PAUSE")
                            }
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isTimerRunning ? FriendlyTheme.mutedAmber : Color.white.opacity(0.05))
                            .foregroundColor(isTimerRunning ? FriendlyTheme.midnightMatte : .white)
                            .cornerRadius(16)
                        }
                        
                        if !isTimerRunning && !completedRestPauseReps.isEmpty {
                            TextField("Reps", text: $currentRestPauseExtraReps)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .padding(.vertical, 16)
                                .background(Color(white: 0.15))
                                .cornerRadius(12)
                            
                            Button(action: logRestPauseRep) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 50)
                                    .padding(.vertical, 16)
                                    .background(FriendlyTheme.mutedAmber)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            // Log Set Button
            Button(action: saveSet) {
                Text(isWarmup ? "LOG WARMUP" : "LOG WORKING SET")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .tracking(2.0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(isWarmup ? FriendlyTheme.mutedAmber : FriendlyTheme.apexGreen)
                    .foregroundColor(.black)
            }
        }
        .background(Color(white: 0.08)) // Darker, cleaner card background
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 20)
        .onReceive(timer) { _ in
            guard isTimerRunning, let endTime = timerEndTime else { return }
            let remaining = endTime.timeIntervalSinceNow
            
            if remaining <= 0 {
                restPauseTimer = 0
                isTimerRunning = false
                timerEndTime = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                if completedRestPauseReps.isEmpty {
                    completedRestPauseReps.append(0)
                    completedRestPauseReps.removeAll()
                }
            } else {
                restPauseTimer = Int(ceil(remaining))
            }
        }
        .onAppear {
            loadPreviousPerformance()
        }
    }
    
    private func loadPreviousPerformance() {
        for log in dailyLogs {
            if let workout = log.workouts.first(where: { $0.exerciseName == exerciseName }),
               let lastSet = workout.sets.last(where: { !$0.isWarmup }) {
                previousSetWeight = String(Int(lastSet.weight))
                previousSetReps = String(lastSet.baseReps)
                previousSetUnit = lastSet.unit
                
                // Also prepopulate current fields with the last working set
                weight = String(Int(lastSet.weight))
                baseReps = String(lastSet.baseReps)
                unit = lastSet.unit
                return
            }
        }
    }
    
    private func saveSet() {
        guard let wAmount = Double(weight), let bReps = Int(baseReps) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        let todayLog = getOrCreateTodayLog()
        let workoutEntry: WorkoutEntry
        
        if let existingWorkout = todayLog.workouts.first(where: { $0.exerciseName == exerciseName }) {
            workoutEntry = existingWorkout
        } else {
            workoutEntry = WorkoutEntry(exerciseName: exerciseName)
            workoutEntry.dailyLog = todayLog
            todayLog.workouts.append(workoutEntry)
            modelContext.insert(workoutEntry)
        }
        
        let newSet = ExerciseSet(
            weight: wAmount,
            unit: unit,
            baseReps: bReps,
            restPauseReps: completedRestPauseReps.filter { $0 > 0 },
            rpe: isWarmup ? 0.0 : rpe,
            forcedRepsCount: isWarmup ? 0 : forcedRepsCount,
            negativesCount: isWarmup ? 0 : negativesCount,
            isWarmup: isWarmup,
            recruitment: recruitmentPercentage
        )
        
        newSet.workoutEntry = workoutEntry
        workoutEntry.sets.append(newSet)
        modelContext.insert(newSet)
        
        let setVolume = Double(newSet.totalReps) * wAmount
        todayLog.totalVolume += setVolume
        if recruitmentPercentage > todayLog.maxMotorUnitRecruitment {
            todayLog.maxMotorUnitRecruitment = recruitmentPercentage
        }
        
        try? modelContext.save()
        triggerSuccessFeedback()
    }
    
    private func triggerSuccessFeedback() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { showSuccessFeedback = true }
        
        // Reset sub-state
        completedRestPauseReps.removeAll()
        currentRestPauseExtraReps = ""
        forcedRepsCount = 0
        negativesCount = 0
        isWarmup = false // Default back to working set after logging a warmup
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccessFeedback = false }
        }
    }
    
    private func logRestPauseRep() {
        if let extra = Int(currentRestPauseExtraReps), extra > 0 {
            completedRestPauseReps.append(extra)
            currentRestPauseExtraReps = ""
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func toggleRestPause() {
        if !isTimerRunning {
            isTimerRunning = true
            restPauseTimer = 15
            timerEndTime = Date().addingTimeInterval(15.0)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            isTimerRunning = false
            timerEndTime = nil
        }
    }
}

// MARK: - Premium Stepper UI
struct StepperRow: View {
    var title: String
    @Binding var value: Int
    var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(value > 0 ? color : FriendlyTheme.textSecondary)
            
            HStack(spacing: 0) {
                Button(action: {
                    if value > 0 {
                        value -= 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }) {
                    Text("-")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(value > 0 ? .white : .gray)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.05))
                }
                
                Text("\(value)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(value > 0 ? .white : FriendlyTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                
                Button(action: {
                    value += 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Text("+")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.05))
                }
            }
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(value > 0 ? 0.3 : 0.1), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Picker Adapter
struct ExercisePickerViewAdapter: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var appState: AppState
    
    @State private var dummyExercise: String = ""
    @State private var dummyWeight: String = ""
    @State private var dummyReps: String = ""
    
    var body: some View {
        ExercisePickerView(
            selectedExercise: Binding(
                get: { dummyExercise },
                set: { newEx in
                    if !newEx.isEmpty && !appState.forgeQueue.contains(newEx) {
                        appState.forgeQueue.append(newEx)
                    }
                }
            ),
            suggestedWeight: $dummyWeight,
            suggestedReps: $dummyReps
        )
    }
}

#Preview {
    ForgeLogbookView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
