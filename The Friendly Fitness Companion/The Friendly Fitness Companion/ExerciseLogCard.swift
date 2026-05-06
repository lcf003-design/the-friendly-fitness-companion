import SwiftUI
import SwiftData
import Combine

struct ExerciseLogCard: View {
    let exerciseName: String
    @Binding var showSuccessFeedback: Bool
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @StateObject private var vm = ExerciseLogViewModel()
    
    // Timer publisher handled locally for UI updates
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
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
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .rigid)
                    impact.impactOccurred()
                    appState.forgeQueue.removeAll(where: { $0 == exerciseName })
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Premium Ghost Set Display (Industry Standard for Progressive Overload)
            if let prevWeight = vm.previousSetWeight, let prevReps = vm.previousSetReps, let prevUnit = vm.previousSetUnit {
                HStack(spacing: 0) {
                    // Standard Autofill Button
                    Button(action: {
                        vm.weight = prevWeight
                        vm.baseReps = prevReps
                        vm.unit = prevUnit
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(FriendlyTheme.textSecondary)
                            Text("LAST:")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            Text("\(prevWeight) \(prevUnit) × \(prevReps)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Progressive Overload Auto-Suggest (The "BEAT IT" Button)
                    Button(action: {
                        if let sugg = vm.suggestedWeight {
                            vm.weight = String(sugg == floor(sugg) ? "\(Int(sugg))" : "\(sugg)")
                        }
                        vm.baseReps = prevReps
                        vm.unit = prevUnit
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }) {
                        HStack(spacing: 4) {
                            Text("BEAT IT")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            if vm.isNewEstimated1RM {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                            }
                        }
                        .foregroundColor(FriendlyTheme.mutedAmber)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .background(Color.white.opacity(0.05))
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
                        withAnimation { vm.isWarmup = true }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Text("WARMUP")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(vm.isWarmup ? FriendlyTheme.mutedAmber : Color.clear)
                            .foregroundColor(vm.isWarmup ? .black : FriendlyTheme.textSecondary)
                    }
                    
                    Button(action: {
                        withAnimation { vm.isWarmup = false }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Text("WORKING")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(!vm.isWarmup ? FriendlyTheme.apexGreen : Color.clear)
                            .foregroundColor(!vm.isWarmup ? .black : FriendlyTheme.textSecondary)
                    }
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Core Inputs (Weight & Reps) - COMPACT
            HStack(spacing: 16) {
                // Weight Column
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("WEIGHT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        Button(action: {
                            vm.unit = (vm.unit == "lbs") ? "kg" : "lbs"
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Text(vm.unit.uppercased())
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FriendlyTheme.apexGreen.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    TextField("0", text: $vm.weight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
                
                Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                
                // Reps Column
                VStack(alignment: .leading, spacing: 4) {
                    Text("REPS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                    
                    TextField("0", text: $vm.baseReps)
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider().background(Color.white.opacity(0.1))
            
            if !vm.isWarmup {
                Divider().background(Color.white.opacity(0.1))
                
                // Proximity to Failure (RPE)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("RPE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        Text("\(Int(vm.rpe)) / 10")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(FriendlyTheme.limeSignal)
                    }
                    Slider(value: $vm.rpe, in: 1...10, step: 1)
                        .accentColor(FriendlyTheme.limeSignal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Advanced Modifiers (Forced & Negatives)
                VStack(alignment: .leading, spacing: 12) {
                    Text("BEYOND FAILURE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                    
                    HStack(spacing: 12) {
                        StepperRow(title: "FORCED", value: $vm.forcedRepsCount, color: FriendlyTheme.mutedAmber)
                        StepperRow(title: "NEGATIVES", value: $vm.negativesCount, color: .red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Rest-Pause Engine
                VStack(spacing: 12) {
                    if !vm.completedRestPauseReps.isEmpty {
                        HStack {
                            Text("REST-PAUSE LOG")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            Spacer()
                            let log = vm.completedRestPauseReps.map { "\($0)" }.joined(separator: " + ")
                            Text("+ \(log) reps")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(FriendlyTheme.mutedAmber)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: vm.toggleRestPause) {
                            HStack {
                                Image(systemName: "timer")
                                Text(vm.isTimerRunning ? "REST: \(vm.restPauseTimer)s" : "REST-PAUSE")
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(vm.isTimerRunning ? FriendlyTheme.mutedAmber : Color.white.opacity(0.05))
                            .foregroundColor(vm.isTimerRunning ? FriendlyTheme.midnightMatte : .white)
                            .cornerRadius(8)
                        }
                        
                        if !vm.isTimerRunning && !vm.completedRestPauseReps.isEmpty {
                            TextField("Reps", text: $vm.currentRestPauseExtraReps)
                                .keyboardType(.numberPad)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 50)
                                .padding(.vertical, 12)
                                .background(Color(white: 0.15))
                                .cornerRadius(8)
                            
                            Button(action: vm.logRestPauseRep) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 40)
                                    .padding(.vertical, 12)
                                    .background(FriendlyTheme.mutedAmber)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Log Set Button
            Button(action: saveSet) {
                HStack {
                    if vm.submissionState == .loading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text(vm.isWarmup ? "LOG WARMUP" : "LOG WORKING SET")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.0)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(vm.isWarmup ? FriendlyTheme.mutedAmber : FriendlyTheme.apexGreen)
                .foregroundColor(.black)
            }
        }
        .background(Color(white: 0.08)) // Darker, cleaner card background
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 16)
        .onReceive(timer) { _ in
            guard vm.isTimerRunning, let endTime = vm.timerEndTime else { return }
            let remaining = endTime.timeIntervalSinceNow
            
            if remaining <= 0 {
                vm.restPauseTimer = 0
                vm.isTimerRunning = false
                vm.timerEndTime = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                if vm.completedRestPauseReps.isEmpty {
                    vm.completedRestPauseReps.append(0)
                    vm.completedRestPauseReps.removeAll()
                }
            } else {
                vm.restPauseTimer = Int(ceil(remaining))
            }
        }
        .onAppear {
            vm.loadPreviousPerformance(exerciseName: exerciseName, dailyLogs: dailyLogs)
        }
        .alert(isPresented: $vm.showValidationError) {
            Alert(title: Text("Invalid Input"), message: Text(vm.validationErrorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveSet() {
        vm.submissionState = .loading
        
        // Validation
        guard let wAmount = Double(vm.weight), let bReps = Int(vm.baseReps) else {
            vm.validationErrorMessage = "Please enter valid numeric values for Weight and Reps."
            vm.showValidationError = true
            vm.submissionState = .error
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        guard wAmount > 0, wAmount < 2000 else {
            vm.validationErrorMessage = "Weight must be between 1 and 2000."
            vm.showValidationError = true
            vm.submissionState = .error
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        guard bReps > 0, bReps < 500 else {
            vm.validationErrorMessage = "Reps must be between 1 and 500."
            vm.showValidationError = true
            vm.submissionState = .error
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
            unit: vm.unit,
            baseReps: bReps,
            restPauseReps: vm.completedRestPauseReps.filter { $0 > 0 },
            rpe: vm.isWarmup ? 0.0 : vm.rpe,
            forcedRepsCount: vm.isWarmup ? 0 : vm.forcedRepsCount,
            negativesCount: vm.isWarmup ? 0 : vm.negativesCount,
            isWarmup: vm.isWarmup,
            recruitment: vm.recruitmentPercentage
        )
        
        newSet.workoutEntry = workoutEntry
        workoutEntry.sets.append(newSet)
        modelContext.insert(newSet)
        
        let setVolume = Double(newSet.totalReps) * wAmount
        todayLog.totalVolume += setVolume
        if vm.recruitmentPercentage > todayLog.maxMotorUnitRecruitment {
            todayLog.maxMotorUnitRecruitment = vm.recruitmentPercentage
        }
        
        do {
            try modelContext.save()
            vm.submissionState = .success
            triggerSuccessFeedback(wasWorkingSet: !vm.isWarmup)
        } catch {
            vm.validationErrorMessage = "Failed to save to database: \(error.localizedDescription)"
            vm.showValidationError = true
            vm.submissionState = .error
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    private func triggerSuccessFeedback(wasWorkingSet: Bool) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { showSuccessFeedback = true }
        
        vm.resetAfterSuccess()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { showSuccessFeedback = false }
            if wasWorkingSet {
                withAnimation {
                    appState.forgeQueue.removeAll(where: { $0 == exerciseName })
                }
            }
        }
    }
}
