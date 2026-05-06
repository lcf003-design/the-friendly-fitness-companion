import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \RoutineTemplate.name) private var routines: [RoutineTemplate]
    
    @State private var showingCreateRoutine = false
    @State private var newRoutineName = ""
    @State private var newRoutineExercises: [String] = []
    
    // Available exercises to add to a routine
    let exerciseDatabase = [
        "Incline Machine Press", "Pec Deck Fly", "Nautilus Pullover", "Lat Pulldown",
        "Machine Row", "Lateral Raise", "Shoulder Press", "Leg Press", "Hack Squat",
        "Leg Extension", "Lying Leg Curl", "Dips", "Bicep Curls", "Lat Rows"
    ]
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 18))
                        
                        Text("ROUTINES")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { showingCreateRoutine = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Saved Routines List
                    if routines.isEmpty {
                        Text("NO ROUTINES SAVED.\nTAP + TO BUILD ONE.")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .tracking(2.0)
                            .padding(.top, 50)
                    } else {
                        ForEach(routines) { routine in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(routine.name.uppercased())
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .tracking(1.5)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(routine.exercises, id: \.self) { exercise in
                                        HStack {
                                            Circle()
                                                .fill(FriendlyTheme.apexGreen)
                                                .frame(width: 6, height: 6)
                                            Text(exercise)
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                    
                                    // Launch the routine
                                    appState.activeRoutine = routine
                                    appState.forgeQueue = routine.exercises
                                    appState.selectedTab = 2 // The Forge
                                }) {
                                    Text("LAUNCH ROUTINE")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .tracking(1.5)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(FriendlyTheme.apexGreen.opacity(0.15))
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FriendlyTheme.apexGreen, lineWidth: 1))
                                }
                                .padding(.top, 8)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(30)
                            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showingCreateRoutine) {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("BUILD ROUTINE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.5)
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    TextField("Routine Name (e.g., Upper Body)", text: $newRoutineName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    
                    Text("SELECT EXERCISES")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .tracking(1.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(exerciseDatabase, id: \.self) { exercise in
                                ExerciseSelectionRow(exercise: exercise, selectedExercises: $newRoutineExercises)
                            }
                        }
                    }
                    
                    Button(action: {
                        if !newRoutineName.isEmpty && !newRoutineExercises.isEmpty {
                            let newRoutine = RoutineTemplate(name: newRoutineName, exercises: newRoutineExercises)
                            modelContext.insert(newRoutine)
                            newRoutineName = ""
                            newRoutineExercises = []
                            showingCreateRoutine = false
                        }
                    }) {
                        Text("SAVE ROUTINE")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(30)
                    }
                    .padding(24)
                    .disabled(newRoutineName.isEmpty || newRoutineExercises.isEmpty)
                    .opacity((newRoutineName.isEmpty || newRoutineExercises.isEmpty) ? 0.5 : 1.0)
                }
            }
        }
    }
}

#Preview {
    RoutinesView()
        .modelContainer(for: RoutineTemplate.self, inMemory: true)
}

struct ExerciseSelectionRow: View {
    let exercise: String
    @Binding var selectedExercises: [String]
    
    var isSelected: Bool {
        selectedExercises.contains(exercise)
    }
    
    var body: some View {
        Button(action: {
            if let index = selectedExercises.firstIndex(of: exercise) {
                selectedExercises.remove(at: index)
            } else {
                selectedExercises.append(exercise)
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            HStack {
                Text(exercise)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .black : .white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(isSelected ? AnyShapeStyle(FriendlyTheme.apexGreen) : AnyShapeStyle(.ultraThinMaterial))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
        }
        .padding(.horizontal, 24)
    }
}
