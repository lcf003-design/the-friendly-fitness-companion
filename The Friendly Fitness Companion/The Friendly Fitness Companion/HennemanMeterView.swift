import SwiftUI

// MARK: - Legacy Components
struct HennemanMeterView: View {
    var recruitmentLevel: Double
    var isFailure: Bool = false
    @State private var pulseState: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isFailure ? "MAX RECRUITMENT" : "MOTOR UNIT RECRUITMENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.textSecondary)
                    .tracking(2.0)
                
                Spacer()
                
                Text("\(Int(recruitmentLevel * 100))%")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.15))
                        .frame(height: 8)
                    
                    // Active track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [FriendlyTheme.limeSignal, isFailure ? .white : FriendlyTheme.apexGreen]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geometry.size.width * CGFloat(recruitmentLevel), height: 8)
                        .shadow(color: isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen.opacity(0.5), radius: isFailure ? (pulseState ? 12 : 4) : 4, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: recruitmentLevel)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseState = true
            }
        }
    }
}
