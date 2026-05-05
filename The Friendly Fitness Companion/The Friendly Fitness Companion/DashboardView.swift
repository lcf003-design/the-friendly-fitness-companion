import SwiftUI
import SwiftData

// MARK: - Theme Definitions (Moved here or to a shared file, assuming shared if already present)
// If FriendlyTheme is redefined, we keep it, otherwise it's global.
// I will keep it here to ensure it compiles if it's the only place it exists.
struct FriendlyTheme {
    static let midnightMatte = Color(red: 10/255, green: 10/255, blue: 10/255)
    static let midnightMatteLight = Color(red: 26/255, green: 26/255, blue: 26/255)
    static let apexGreen = Color(red: 0, green: 1.0, blue: 0)
    static let limeSignal = Color(red: 191/255, green: 255/255, blue: 0)
    static let mutedAmber = Color(red: 214/255, green: 160/255, blue: 84/255)
    static let textSecondary = Color.gray
}

// MARK: - Main Dashboard View
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Fetch logs, ordered by date descending (newest first)
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    // Derived Data for Today
    private var todayLog: DailyLog? {
        let calendar = Calendar.current
        return dailyLogs.first(where: { calendar.isDateInToday($0.date) })
    }
    
    private var motorUnitRecruitment: Double {
        todayLog?.maxMotorUnitRecruitment ?? 0.0
    }
    
    var body: some View {
        ZStack {
            // Background
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Spacer()
                        
                        Text("THE FRIENDLY COMPANION")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .tracking(1.2)
                        
                        Spacer()
                        
                        Image(systemName: "bell")
                            .font(.system(size: 24))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // The Forge: Henneman Meter
                    HennemanMeterView(recruitmentLevel: motorUnitRecruitment)
                    
                    // Optional Recovery/HealthKit Data
                    RecoveryBalanceView()
                }
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
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
                    .stroke(FriendlyTheme.midnightMatteLight, style: StrokeStyle(lineWidth: 30, lineCap: .round))
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
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .contentTransition(.numericText())
                    
                    Text("MOTOR UNIT\nRECRUITMENT")
                        .font(.system(size: 12, weight: .semibold))
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



// MARK: - Recovery Balance Placeholder
struct RecoveryBalanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OPTIMAL RECOVERY BALANCE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .tracking(0.5)
            Text("INTAKE: 1540 CAL")
                .font(.system(size: 14))
                .foregroundColor(FriendlyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
        .padding(.horizontal, 20)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
