import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \RoutineTemplate.name) private var routines: [RoutineTemplate]
    @Query(sort: \CustomExercise.name) private var customExercises: [CustomExercise]
    
    @State private var showingCreateRoutine = false
    @State private var routineToEdit: RoutineTemplate?
    @State private var newRoutineName = ""
    @State private var newRoutineExercises: [String] = []
    
    // Available exercises to add to a routine
    let baseExercises = [
        "Incline Machine Press", "Pec Deck Fly", "Nautilus Pullover", "Lat Pulldown",
        "Machine Row", "Lateral Raise", "Shoulder Press", "Leg Press", "Hack Squat",
        "Leg Extension", "Lying Leg Curl", "Dips", "Bicep Curls", "Lat Rows"
    ]
    
    var allExercises: [String] {
        let customNames = customExercises.map { $0.name }
        return Array(Set(baseExercises + customNames)).sorted()
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 18))
                        
                        Text("ROUTINES")
                            .font(.system(size: 14, weight: .black))
                            .tracking(4.0)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            routineToEdit = nil
                            newRoutineName = ""
                            newRoutineExercises = []
                            showingCreateRoutine = true
                        }) {
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .tracking(2.0)
                            .padding(.top, 50)
                    } else {
                        ForEach(routines) { routine in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(routine.name.uppercased())
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(.white)
                                        .tracking(2.0)
                                    Spacer()
                                    
                                    Menu {
                                        Button(action: {
                                            routineToEdit = routine
                                            newRoutineName = routine.name
                                            newRoutineExercises = routine.exercises
                                            showingCreateRoutine = true
                                        }) {
                                            Label("Edit Routine", systemImage: "pencil")
                                        }
                                        
                                        Button(action: {
                                            let newRoutine = RoutineTemplate(name: "\(routine.name) (Copy)", exercises: routine.exercises)
                                            modelContext.insert(newRoutine)
                                            try? modelContext.save()
                                            HapticManager.shared.medium()
                                        }) {
                                            Label("Duplicate", systemImage: "doc.on.doc")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            modelContext.delete(routine)
                                            try? modelContext.save()
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                            .padding(8)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(routine.exercises, id: \.self) { exercise in
                                        HStack {
                                            Circle()
                                                .fill(FriendlyTheme.apexGreen)
                                                .frame(width: 6, height: 6)
                                            Text(exercise)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    HapticManager.shared.heavy()
                                    
                                    // Launch the routine
                                    appState.activeRoutine = routine
                                    appState.forgeQueue = routine.exercises
                                    appState.selectedTab = 2 // The Forge
                                }) {
                                    Text("LAUNCH ROUTINE")
                                        .font(.system(size: 12, weight: .black))
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
                            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
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
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                VStack(spacing: 20) {
                    Text(routineToEdit != nil ? "EDIT ROUTINE" : "BUILD ROUTINE")
                        .font(.system(size: 14, weight: .black))
                        .tracking(4.0)
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    TextField("Routine Name (e.g., Upper Body)", text: $newRoutineName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    
                    if !newRoutineExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SELECTED EXERCISES (DRAG TO REORDER)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .tracking(2.0)
                                .padding(.horizontal, 24)
                            
                            List {
                                ForEach(newRoutineExercises, id: \.self) { exercise in
                                    Text(exercise)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .listRowBackground(Color(white: 0.1))
                                }
                                .onMove { indices, newOffset in
                                    newRoutineExercises.move(fromOffsets: indices, toOffset: newOffset)
                                }
                                .onDelete { indices in
                                    newRoutineExercises.remove(atOffsets: indices)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .environment(\.editMode, .constant(.active))
                            .frame(height: min(CGFloat(newRoutineExercises.count * 50), 200))
                        }
                    }
                    
                    Text("ADD EXERCISES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .tracking(2.0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(allExercises, id: \.self) { exercise in
                                if !newRoutineExercises.contains(exercise) {
                                    ExerciseSelectionRow(exercise: exercise, selectedExercises: $newRoutineExercises)
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    
                    Button(action: {
                        if !newRoutineName.isEmpty && !newRoutineExercises.isEmpty {
                            if let routine = routineToEdit {
                                routine.name = newRoutineName
                                routine.exercises = newRoutineExercises
                            } else {
                                let newRoutine = RoutineTemplate(name: newRoutineName, exercises: newRoutineExercises)
                                modelContext.insert(newRoutine)
                            }
                            try? modelContext.save()
                            newRoutineName = ""
                            newRoutineExercises = []
                            showingCreateRoutine = false
                        }
                    }) {
                        Text(routineToEdit != nil ? "SAVE CHANGES" : "SAVE ROUTINE")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(2.0)
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
    
    var body: some View {
        Button(action: {
            selectedExercises.append(exercise)
            HapticManager.shared.light()
        }) {
            HStack {
                Text(exercise)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundColor(FriendlyTheme.apexGreen)
            }
            .padding()
            .background(AnyShapeStyle(.ultraThinMaterial))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .padding(.horizontal, 24)
    }
}
