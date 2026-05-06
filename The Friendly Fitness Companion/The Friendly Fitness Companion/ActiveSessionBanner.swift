import SwiftUI
import Combine

struct ActiveSessionBanner: View {
    @EnvironmentObject var appState: AppState
    @State private var currentDurationString: String = "00:00"
    @State private var isPulsing = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(FriendlyTheme.apexGreen)
                    .frame(width: 8, height: 8)
                    .opacity(isPulsing ? 1.0 : 0.3)
                
                Text("ACTIVE SESSION\(appState.activeRoutine != nil ? ": \(appState.activeRoutine!.name.uppercased())" : "")")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(FriendlyTheme.apexGreen)
                
                Spacer()
                
                Text(currentDurationString)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .background(FriendlyTheme.midnightMatte.opacity(0.8))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 24)
            .padding(.top, 50)
            .onTapGesture {
                withAnimation {
                    appState.showLiveForge = true
                }
            }
            Spacer()
        }
        .zIndex(100)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .onReceive(timer) { _ in
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
    }
}
