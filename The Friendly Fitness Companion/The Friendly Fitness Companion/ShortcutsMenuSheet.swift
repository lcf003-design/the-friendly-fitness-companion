import SwiftUI

struct ShortcutsMenuSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var showSnapLog = false
    @State private var snapLogType: SnapLogType = .water
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
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
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                appState.selectedTab = 10 // Navigate to Forge
                                appState.showLiveForge = true
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
        .sheet(isPresented: $showSnapLog) {
            SnapLogView(type: snapLogType)
                .presentationDetents([.fraction(0.7)])
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
