import SwiftUI
import SwiftData

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
    
    // Timer state for the Recovery Clock to constantly update
    @State private var now = Date()
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    // Average Recruitment (Last 3 Workouts)
    private var averageRecruitment: Double {
        let lastThree = dailyLogs.filter { $0.maxMotorUnitRecruitment > 0 }.prefix(3)
        guard !lastThree.isEmpty else { return 0.0 }
        let sum = lastThree.reduce(0.0) { $0 + $1.maxMotorUnitRecruitment }
        return sum / Double(lastThree.count)
    }
    
    // Find the timestamp of the absolutely most recent workout set
    private var lastWorkoutTimestamp: Date? {
        for log in dailyLogs {
            for workout in log.workouts {
                if let lastSet = workout.sets.last {
                    return lastSet.workoutEntry?.timestamp ?? workout.timestamp
                }
            }
        }
        return nil
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
                    
                    // Recovery Clock (Secondary Gauge)
                    RecoveryClockView(lastWorkout: lastWorkoutTimestamp, now: now)
                }
                .padding(.bottom, 100)
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
}

// MARK: - Recovery Clock Component
struct RecoveryClockView: View {
    var lastWorkout: Date?
    var now: Date
    
    var body: some View {
        VStack(spacing: 16) {
            Text("RECOVERY CLOCK")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
                .tracking(2.0)
            
            HStack(spacing: 20) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(isRecovered ? FriendlyTheme.apexGreen : FriendlyTheme.mutedAmber)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeSinceString)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text(isRecovered ? "READY FOR WAR" : "RECOVERING")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(isRecovered ? FriendlyTheme.apexGreen : FriendlyTheme.mutedAmber)
                        .tracking(1.5)
                }
                Spacer()
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
        .padding(.horizontal, 20)
    }
    
    private var isRecovered: Bool {
        guard let last = lastWorkout else { return true }
        let hoursSince = now.timeIntervalSince(last) / 3600
        return hoursSince >= 48.0
    }
    
    private var timeSinceString: String {
        guard let last = lastWorkout else { return "00:00:00" }
        let diff = Int(now.timeIntervalSince(last))
        guard diff > 0 else { return "00:00:00" }
        
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = (diff % 3600) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
