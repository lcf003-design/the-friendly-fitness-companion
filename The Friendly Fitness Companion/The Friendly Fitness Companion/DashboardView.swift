import SwiftUI
import SwiftData
import Combine

// MARK: - Theme Definitions
struct FriendlyTheme {
    static let midnightMatte = Color(red: 10/255, green: 10/255, blue: 10/255)
    static let midnightMatteLight = Color(red: 26/255, green: 26/255, blue: 26/255)
    static let apexGreen = Color(red: 0, green: 1.0, blue: 0)
    static let limeSignal = Color(red: 191/255, green: 255/255, blue: 0)
    static let mutedAmber = Color(red: 214/255, green: 160/255, blue: 84/255)
    static let textSecondary = Color.gray
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    // Average Recruitment (Last 3 Workouts)
    private var averageRecruitment: Double {
        let lastThree = dailyLogs.filter { $0.maxMotorUnitRecruitment > 0 }.prefix(3)
        guard !lastThree.isEmpty else { return 0.0 }
        let sum = lastThree.reduce(0.0) { $0 + $1.maxMotorUnitRecruitment }
        return sum / Double(lastThree.count)
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.bottom.100percent")
                            .font(.system(size: 24))
                            .foregroundColor(FriendlyTheme.apexGreen)
                        
                        Spacer()
                        
                        Text("COMMAND CENTER")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "bell")
                            .font(.system(size: 24))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // The Forge: Henneman Meter
                    VStack(spacing: 12) {
                        HennemanMeterView(recruitmentLevel: averageRecruitment)
                        Text("LAST 3 WORKOUTS (AVG)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(1.5)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Henneman Meter Component
struct HennemanMeterView: View {
    var recruitmentLevel: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Track
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color(white: 0.15), style: StrokeStyle(lineWidth: 30, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(180))
                
                // Active Green Track
                Circle()
                    .trim(from: 0.5, to: 0.5 + (recruitmentLevel / 2))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [FriendlyTheme.limeSignal, FriendlyTheme.apexGreen]), center: .center, startAngle: .degrees(180), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(180))
                    .shadow(color: FriendlyTheme.apexGreen.opacity(0.5), radius: 15, x: 0, y: 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: recruitmentLevel)
                
                // Percentage Text
                VStack(spacing: -4) {
                    Text("\(Int(recruitmentLevel * 100))%")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .contentTransition(.numericText())
                        .shadow(color: FriendlyTheme.apexGreen.opacity(0.3), radius: 10)
                    
                    Text("MOTOR UNIT\nRECRUITMENT")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .tracking(1.5)
                }
                .offset(y: -30)
            }
            .frame(height: 140) // Clip the bottom half of the circle
        }
        .padding(.top, 20)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
