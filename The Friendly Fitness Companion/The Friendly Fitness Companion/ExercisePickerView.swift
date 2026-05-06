import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all daily logs to search for past performance
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    // Fetch custom exercises
    @Query(sort: \CustomExercise.name) private var customExercises: [CustomExercise]
    
    @Binding var selectedExercise: String
    @Binding var suggestedWeight: String
    @Binding var suggestedReps: String
    
    @State private var searchText: String = ""
    
    // Pre-populated High Intensity Training movements
    let hitExercises = [
        "Leg Press",
        "Hack Squat",
        "Leg Extension",
        "Lying Leg Curl",
        "Machine Chest Press",
        "Incline Machine Press",
        "Pec Deck Fly",
        "Nautilus Pullover",
        "Lat Pulldown",
        "Machine Row",
        "Lateral Raise",
        "Shoulder Press"
    ]
    
    var allExercises: [String] {
        let customNames = customExercises.map { $0.name }
        return Array(Set(hitExercises + customNames)).sorted()
    }
    
    var filteredExercises: [String] {
        if searchText.isEmpty {
            return allExercises
        } else {
            return allExercises.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("SELECT MOVEMENT")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.5)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Search
                TextField("Search movements...", text: $searchText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                
                // List
                ScrollView {
                    VStack(spacing: 12) {
                        // "Add New" Button
                        if !searchText.isEmpty && !allExercises.contains(where: { $0.caseInsensitiveCompare(searchText) == .orderedSame }) {
                            Button(action: {
                                addCustomExercise()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                    Text("Add \"\(searchText)\"")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                    Spacer()
                                }
                                .padding(20)
                                .background(FriendlyTheme.apexGreen.opacity(0.15))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(FriendlyTheme.apexGreen, lineWidth: 1))
                            }
                        }
                        
                        ForEach(filteredExercises, id: \.self) { exercise in
                            Button(action: {
                                selectExercise(exercise)
                            }) {
                                HStack {
                                    Text(exercise)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if let lastPerformance = findLastPerformance(for: exercise) {
                                        Text("Last: \(Int(lastPerformance.weight))lbs × \(lastPerformance.totalReps)")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                    } else {
                                        Text("NEW")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(FriendlyTheme.mutedAmber)
                                    }
                                }
                                .padding(20)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func addCustomExercise() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newCustom = CustomExercise(name: trimmed)
        modelContext.insert(newCustom)
        
        // Directly select it and close
        selectExercise(trimmed)
    }
    
    private func selectExercise(_ exercise: String) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        selectedExercise = exercise
        
        if let last = findLastPerformance(for: exercise) {
            suggestedWeight = String(Int(last.weight))
            suggestedReps = String(last.totalReps)
        } else {
            suggestedWeight = ""
            suggestedReps = ""
        }
        
        dismiss()
    }
    
    private func findLastPerformance(for exercise: String) -> ExerciseSet? {
        for log in dailyLogs {
            if let workout = log.workouts.first(where: { $0.exerciseName == exercise }),
               let lastSet = workout.sets.last {
                return lastSet
            }
        }
        return nil
    }
}
