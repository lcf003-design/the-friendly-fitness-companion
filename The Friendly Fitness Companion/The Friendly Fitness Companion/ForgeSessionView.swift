import SwiftUI
import SwiftData

struct ForgeSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    @State private var searchInput: String = ""
    @State private var isShowingSuggestions: Bool = false
    @State private var weight: Double = 135
    @State private var reps: Int = 10
    @State private var isAbsoluteFailure: Bool = false
    @State private var hasForcedReps: Bool = false
    @State private var hasNegatives: Bool = false
    @State private var hasRestPause: Bool = false
    
    @Query private var dailyLogs: [DailyLog]
    
    // Track the active workout entry to append sets
    @State private var activeWorkout: WorkoutEntry?
    
    private var currentExercise: String {
        searchInput.isEmpty ? "Select Exercise" : searchInput
    }
    
    var filteredExercises: [ExerciseDefinition] {
        if searchInput.isEmpty {
            return ExerciseLibrary.hitMovements
        } else {
            return ExerciseLibrary.hitMovements.filter { $0.name.localizedCaseInsensitiveContains(searchInput) }
        }
    }
    
    private var lastSessionStats: String? {
        let current = currentExercise
        if current == "Select Exercise" { return nil }
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Autocomplete Exercise Search
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("Search High-Intensity Movement...", text: $searchInput, onEditingChanged: { editing in
                                    withAnimation { isShowingSuggestions = editing }
                                })
                                .foregroundColor(.white)
                                .disableAutocorrection(true)
                                
                                if !searchInput.isEmpty {
                                    Button(action: { searchInput = ""; isShowingSuggestions = false }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            
                            if isShowingSuggestions && !filteredExercises.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(filteredExercises, id: \.name) { exercise in
                                        Button(action: {
                                            searchInput = exercise.name
                                            isShowingSuggestions = false
                                            HapticManager.shared.light()
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }) {
                                            HStack {
                                                Text(exercise.name)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                                            .padding()
                                            .background(.ultraThinMaterial)
                                        }
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        if let lastStats = lastSessionStats {
                            Text("Last Session: \(lastStats)")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.bottom, -16)
                        }
                            
                            // Clean White Input Form
                            VStack(spacing: 0) {
                                // Weight Row
                                HStack {
                                    Text("Weight")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button(action: { if weight >= 5 { weight -= 5 }; HapticManager.shared.light() }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                        Text("\(Int(weight))")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: 40, alignment: .center)
                                        Button(action: { weight += 5; HapticManager.shared.light() }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                                
                                // Reps Row
                                HStack {
                                    Text("Reps")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button(action: { if reps > 0 { reps -= 1 }; HapticManager.shared.light() }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                        Text("\(reps)")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: 40, alignment: .center)
                                        Button(action: { reps += 1; HapticManager.shared.light() }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                                
                                // Failure Row
                                Toggle(isOn: $isAbsoluteFailure) {
                                    Text("Pushed to Failure")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.white)
                                }
                                .tint(Color(red: 0.3, green: 0.8, blue: 0.4))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .onChange(of: isAbsoluteFailure) { _, val in
                                    if val { HapticManager.shared.heavy() }
                                }
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                                
                                Toggle(isOn: $hasForcedReps) {
                                    Text("Forced Reps")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.white)
                                }
                                .tint(Color(red: 0.3, green: 0.8, blue: 0.4))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                                
                                Toggle(isOn: $hasNegatives) {
                                    Text("Negatives")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.white)
                                }
                                .tint(Color(red: 0.3, green: 0.8, blue: 0.4))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                                
                                Toggle(isOn: $hasRestPause) {
                                    Text("Rest-Pause")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.white)
                                }
                                .tint(Color(red: 0.3, green: 0.8, blue: 0.4))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                            }
                            .background(.ultraThinMaterial)
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
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 1, height: 24)
                                            
                                            Text("\(Int(set.weight)) \(set.unit) x \(set.totalReps)")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            if set.isAbsoluteFailure == true {
                                                Text("🔥")
                                                    .font(.system(size: 16))
                                            }
                                            if set.forcedReps {
                                                Image(systemName: "bolt.fill")
                                                    .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.4))
                                            }
                                            if set.negatives {
                                                Image(systemName: "arrow.down.to.line.alt")
                                                    .foregroundColor(.red)
                                            }
                                            if set.hasRestPause == true {
                                                Image(systemName: "pause.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        
                                        if index < workout.sets.count - 1 {
                                            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                        }
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
                if let first = appState.forgeQueue.first {
                    searchInput = first
                }
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
    
    private func calculateRecruitment(weight: Double, reps: Int, isFailure: Bool, hasForcedReps: Bool, hasNegatives: Bool, hasRestPause: Bool) -> Double {
        var base = (weight / 300.0) * 0.4
        if isFailure {
            base += 0.4
        } else {
            base += Double(reps) * 0.02
        }
        if hasForcedReps { base += 0.1 }
        if hasNegatives { base += 0.1 }
        if hasRestPause { base += 0.15 }
        return min(max(base, 0.0), 1.0)
    }
    
    private func logSet() {
        if searchInput.isEmpty { return }
        
        let recruitment = calculateRecruitment(weight: weight, reps: reps, isFailure: isAbsoluteFailure, hasForcedReps: hasForcedReps, hasNegatives: hasNegatives, hasRestPause: hasRestPause)
        
        // Ensure we have an active workout for the current exercise
        if activeWorkout == nil || activeWorkout?.exerciseName != searchInput {
            startNewWorkoutEntry()
        }
        
        guard let workout = activeWorkout else { return }
        
        let newSet = ExerciseSet(
            weight: weight,
            unit: preferredUnit,
            baseReps: reps,
            rpe: isAbsoluteFailure ? 10.0 : 8.0,
            forcedReps: hasForcedReps,
            negatives: hasNegatives,
            hasRestPause: hasRestPause,
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
        
        // Reset state for next set (per Prompt 2)
        weight = 0
        reps = 0
        isAbsoluteFailure = false
        hasForcedReps = false
        hasNegatives = false
        hasRestPause = false
    }
    
    private func finishSession() {
        HapticManager.shared.medium()
        appState.showLiveForge = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.showWorkoutSummary = true
        }
    }
}
