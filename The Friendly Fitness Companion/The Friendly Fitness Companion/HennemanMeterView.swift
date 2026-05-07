import SwiftUI

// MARK: - Legacy Components
struct HennemanMeterView: View {
    var recruitmentLevel: Double
    var isFailure: Bool = false
    @State private var pulseState: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                // Background semi-transparent filled circle
                Circle()
                    .fill(.ultraThinMaterial)
                
                Circle()
                    .fill(FriendlyTheme.apexGreen.opacity(0.2))
                
                // Muted track
                Circle()
                    .stroke(FriendlyTheme.apexGreen.opacity(0.15), lineWidth: 14)
                    .padding(16)
                
                // Active needle/progress indicator
                Circle()
                    .trim(from: 0, to: CGFloat(recruitmentLevel))
                    .stroke(
                        isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(16)
                    .shadow(color: isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen.opacity(0.5), radius: isFailure ? (pulseState ? 12 : 4) : 4, x: 0, y: 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: recruitmentLevel)
                
                VStack(spacing: 4) {
                    Text("\(Int(recruitmentLevel * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(isFailure ? FriendlyTheme.limeSignal : .white)
                    
                    Text(isFailure ? "MAX FAILURE" : "RECRUITMENT")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.textSecondary)
                        .tracking(1.0)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseState = true
            }
        }
    }
}
