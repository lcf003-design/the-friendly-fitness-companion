import SwiftUI
import SwiftData
import Combine

struct ForgeLogbookView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query private var dailyLogs: [DailyLog]
    
    init() {
        var descriptor = FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 7 // We primarily only need today's log, so 7 is extremely safe and fast
        _dailyLogs = Query(descriptor)
    }
    
    @State private var isShowingExercisePicker: Bool = false
    @State private var swapExerciseIndex: Int? = nil
    @State private var showSuccessFeedback: Bool = false
    
    // Live Timer
    @State private var currentDurationString: String = "00:00"
    let liveTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                        
                    // Live Workout Engine Header
                    if !appState.isWorkoutActive {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            appState.isWorkoutActive = true
                            appState.workoutStartTime = Date()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18))
                                Text("START LIVE WORKOUT")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(2.0)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .shadow(color: FriendlyTheme.apexGreen.opacity(0.3), radius: 10)
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 12)
                    } else {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .opacity(0.8) // Pulse effect would be better, but keeping it simple
                            Text(currentDurationString)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.red)
                                .monospacedDigit()
                            
                            Spacer()
                            
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                appState.showWorkoutSummary = true
                                
                                // HealthKit Bi-Directional Sync
                                let endDate = Date()
                                let startDate = appState.workoutStartTime ?? endDate
                                let todayLog = getOrCreateTodayLog()
                                
                                for workout in todayLog.workouts {
                                    HealthKitManager.shared.saveWorkout(workout: workout, startDate: startDate, endDate: endDate)
                                }
                            }) {
                                Text("FINISH WORKOUT")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                    }
                }
                .background(FriendlyTheme.midnightMatte.opacity(0.95))
                .zIndex(1)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // The Journal Queue
                        if !appState.forgeQueue.isEmpty {
                            VStack(spacing: 24) {
                                ForEach(appState.forgeQueue, id: \.self) { exercise in
                                    ExerciseLogCard(
                                        exerciseName: exercise,
                                        showSuccessFeedback: $showSuccessFeedback,
                                        onSwapRequested: {
                                            if let index = appState.forgeQueue.firstIndex(of: exercise) {
                                                swapExerciseIndex = index
                                                isShowingExercisePicker = true
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.top, 16)
                        }
                        
                        // Add Exercise Button
                        Button(action: {
                            swapExerciseIndex = nil
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
        .onReceive(liveTimer) { _ in
            if appState.isWorkoutActive, let start = appState.workoutStartTime {
                let interval = Date().timeIntervalSince(start)
                let hours = Int(interval) / 3600
                let minutes = Int(interval) / 60 % 60
                let seconds = Int(interval) % 60
                if hours > 0 {
                    currentDurationString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                } else {
                    currentDurationString = String(format: "%02d:%02d", minutes, seconds)
                }
            }
        }
        .sheet(isPresented: $isShowingExercisePicker) {
            ExercisePickerViewAdapter(isShowing: $isShowingExercisePicker, swapExerciseIndex: $swapExerciseIndex)
        }
        .sheet(isPresented: $appState.showWorkoutSummary) {
            WorkoutSummaryModal(
                durationString: currentDurationString,
                todayLog: getOrCreateTodayLog()
            )
            .environmentObject(appState)
        }
    }
}

// MARK: - Workout Summary Modal
struct WorkoutSummaryModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    var durationString: String
    var todayLog: DailyLog
    
    @State private var rpe: Double = 8.0
    @State private var cnsFatigue: Bool = false
    @Environment(\.modelContext) private var modelContext
    
    var totalSets: Int {
        todayLog.workouts.reduce(0) { $0 + $1.sets.count }
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Confetti / Icon
                ZStack {
                    Circle()
                        .fill(FriendlyTheme.apexGreen.opacity(0.2))
                        .frame(width: 120, height: 120)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
                
                VStack(spacing: 12) {
                    Text("WORKOUT COMPLETE")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2.0)
                    
                    Text("You pushed yourself to the limit.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                
                // Stats Grid
                HStack(spacing: 20) {
                    StatBox(title: "DURATION", value: durationString)
                    StatBox(title: "VOLUME", value: "\(Int(todayLog.totalVolume)) lbs")
                    StatBox(title: "SETS", value: "\(totalSets)")
                }
                .padding(.horizontal, 24)
                
                // Subjective Effort
                VStack(spacing: 20) {
                    HStack {
                        Text("RATE OF PERCEIVED EXERTION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        Text("\(Int(rpe))/10")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(rpe == 10 ? FriendlyTheme.limeSignal : .white)
                    }
                    Slider(value: $rpe, in: 1...10, step: 1)
                        .accentColor(rpe == 10 ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen)
                    
                    Toggle("CNS FATIGUE DETECTED", isOn: $cnsFatigue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(cnsFatigue ? .red : .white)
                        .tint(.red)
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    // Complete Workout Routine
                    todayLog.rpeScore = rpe
                    todayLog.cnsFatigueDetected = cnsFatigue
                    try? modelContext.save()
                    
                    appState.isWorkoutActive = false
                    appState.workoutStartTime = nil
                    appState.forgeQueue.removeAll()
                    dismiss()
                }) {
                    Text("DONE")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(FriendlyTheme.apexGreen)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct StatBox: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
                .tracking(1.0)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
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
                        
                        if set.isAbsoluteFailure == true {
                            Text("HD")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(FriendlyTheme.limeSignal)
                                .padding(4)
                                .background(FriendlyTheme.limeSignal.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        IntensityShareButton(workout: workout, set: set)
                        
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

// MARK: - Intensity Share Button
struct IntensityShareButton: View {
    let workout: WorkoutEntry
    let set: ExerciseSet
    
    var body: some View {
        if set.isAbsoluteFailure == true {
            let loadStr = "\(Int(set.weight))\(set.unit)"
            let brandStr = workout.equipmentBrand ?? "Standard"
            if let image = IntensityShareGenerator.generateImage(exerciseName: workout.exerciseName, load: loadStr, brand: brandStr) {
                ShareLink(item: image, preview: SharePreview(workout.exerciseName, image: image)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(FriendlyTheme.limeSignal)
                }
                .padding(.trailing, 8)
            }
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
    @Binding var swapExerciseIndex: Int?
    @EnvironmentObject var appState: AppState
    
    @State private var dummyExercise: String = ""
    @State private var dummyWeight: String = ""
    @State private var dummyReps: String = ""
    
    var body: some View {
        ExercisePickerView(
            selectedExercise: Binding(
                get: { dummyExercise },
                set: { newEx in
                    if !newEx.isEmpty {
                        if let index = swapExerciseIndex {
                            appState.forgeQueue[index] = newEx
                        } else if !appState.forgeQueue.contains(newEx) {
                            appState.forgeQueue.append(newEx)
                        }
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
