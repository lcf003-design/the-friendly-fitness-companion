import SwiftUI
import SwiftData

struct ShortcutsMenuSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var showSnapLog = false
    @State private var snapLogType: SnapLogType = .water
    @State private var isSelectingRoutine = false
    @State private var showSettings = false
    
    @Query private var routines: [RoutineTemplate]
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            if isSelectingRoutine {
                routineSelectionView
            } else {
                mainMenuView
            }
        }
        .sheet(isPresented: $showSnapLog) {
            SnapLogView(type: snapLogType)
                .presentationDetents([.fraction(0.7)])
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                AppSettingsView()
            }
        }
    }
    
    var routineSelectionView: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    withAnimation { isSelectingRoutine = false }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                Spacer()
                Text("SELECT ROUTINE")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Quick Start
                    Button(action: {
                        startForgeSession(routine: nil)
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(FriendlyTheme.limeSignal)
                            Text("QUICK START")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FriendlyTheme.limeSignal, lineWidth: 1))
                    }
                    
                    if routines.isEmpty {
                        Text("No saved routines found.")
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.top, 20)
                    } else {
                        let nextRoutine = RoutineRotationManager.nextRoutineToHit(routines: routines)
                        ForEach(routines) { routine in
                            let isNext = (routine.id == nextRoutine?.id)
                            let daysSince = RoutineRotationManager.daysSinceLastHit(for: routine)
                            
                            Button(action: {
                                startForgeSession(routine: routine)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(routine.name.uppercased())
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(isNext ? FriendlyTheme.apexGreen : .white)
                                            
                                            if isNext {
                                                Text("NEXT")
                                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(FriendlyTheme.apexGreen.opacity(0.2))
                                                    .foregroundColor(FriendlyTheme.apexGreen)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        HStack {
                                            Text("\(routine.exercises.count) exercises")
                                                .font(.system(size: 12))
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                            
                                            Text("•")
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                            
                                            if let days = daysSince {
                                                Text("\(days)d since hit")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(days > 4 ? .orange : FriendlyTheme.textSecondary)
                                            } else {
                                                Text("Never hit")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(FriendlyTheme.textSecondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isNext ? FriendlyTheme.apexGreen.opacity(0.5) : Color.clear, lineWidth: 1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func startForgeSession(routine: RoutineTemplate?) {
        HapticManager.shared.light()
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let r = routine {
                appState.forgeQueue = r.exercises
            } else {
                appState.forgeQueue = []
            }
            appState.selectedTab = 10
            appState.showLiveForge = true
        }
    }
    
    var mainMenuView: some View {
        VStack(spacing: 30) {
                // Header
                HStack {
                    Spacer()
                    Text("SHORTCUTS")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                    Spacer()
                }
                .overlay(
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.shared.light()
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .font(.system(size: 18))
                        }
                    }
                )
                .padding(.horizontal, 24)
                .padding(.top, 30)
                
                // Primary Actions
                HStack(spacing: 16) {
                    PrimaryActionCircle(icon: "magnifyingglass", title: "Search") {
                        HapticManager.shared.light()
                        dismiss()
                        appState.isDrawerOpen = true
                    }
                    PrimaryActionCircle(icon: "barcode.viewfinder", title: "Barcode") {
                        HapticManager.shared.light()
                    }
                    PrimaryActionCircle(icon: "camera.macro", title: "Meal Scan") {
                        HapticManager.shared.light()
                    }
                    PrimaryActionCircle(icon: "mic.fill", title: "Voice") {
                        HapticManager.shared.light()
                    }
                }
                .padding(.horizontal, 20)
                
                // Secondary Actions (2x2 Grid)
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        SecondaryActionButton(icon: "drop.fill", title: "Water", color: .blue) {
                            HapticManager.shared.light()
                            snapLogType = .water
                            showSnapLog = true
                        }
                        SecondaryActionButton(icon: "dumbbell.fill", title: "Exercise", color: FriendlyTheme.limeSignal) {
                            HapticManager.shared.light()
                            withAnimation {
                                isSelectingRoutine = true
                            }
                        }
                    }
                    HStack(spacing: 16) {
                        SecondaryActionButton(icon: "scalemass.fill", title: "Weight", color: .purple) {
                            HapticManager.shared.light()
                            snapLogType = .weight
                            showSnapLog = true
                        }
                        SecondaryActionButton(icon: "flame.fill", title: "Calories", color: .orange) {
                            HapticManager.shared.light()
                            snapLogType = .calories
                            showSnapLog = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
enum SnapLogType {
    case water, weight, calories
}

struct PrimaryActionCircle: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SecondaryActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}
