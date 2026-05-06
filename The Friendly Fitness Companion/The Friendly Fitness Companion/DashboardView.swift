import SwiftUI
import SwiftData
import Combine
import Charts

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
    
    // Recovery Logic
    private var recoveryStatus: (title: String, color: Color, message: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let recentLogs = dailyLogs.filter { $0.totalVolume > 0 && calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.date), to: today).day ?? 0 <= 5 }
        
        if recentLogs.count >= 3 {
            return ("OVERTRAINING RISK", .red, "You've trained \(recentLogs.count) times in the last 5 days. Heavy Duty requires absolute recovery. Take a break.")
        } else if let lastWorkout = dailyLogs.first(where: { $0.totalVolume > 0 }) {
            let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastWorkout.date), to: today).day ?? 0
            if daysSince == 0 {
                return ("RECOVERING", FriendlyTheme.mutedAmber, "You trained today. CNS recovery is actively occurring. Do not train again.")
            } else if daysSince == 1 {
                return ("RECOVERING", FriendlyTheme.mutedAmber, "It has only been 1 day since your last session. Growth happens during rest.")
            } else {
                return ("READY TO FORGE", FriendlyTheme.apexGreen, "System fully recovered. Proceed with maximum intensity.")
            }
        }
        return ("READY TO FORGE", FriendlyTheme.apexGreen, "No recent sessions. Time to begin.")
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.bottom.100percent")
                            .font(.system(size: 24))
                            .foregroundColor(FriendlyTheme.apexGreen)
                        
                        Spacer()
                        
                        Text("COMMAND CENTER")
                            .font(.system(size: 14, weight: .black))
                            .tracking(4.0)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.system(size: 14))
                            Text("SYNCED")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                        }
                        .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.leading, 12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // The Forge: Henneman Meter
                    VStack(spacing: 12) {
                        HennemanMeterView(recruitmentLevel: averageRecruitment)
                        Text("LAST 3 WORKOUTS (AVG)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(3.0)
                    }
                    .padding(.bottom, 10)
                    
                    // Analytics: Tonnage Volume Chart
                    if dailyLogs.filter({ $0.totalVolume > 0 }).count > 0 {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("WORKOUT VOLUME TRENDS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .tracking(3.0)
                                .padding(.horizontal, 24)
                            
                            Chart {
                                let validLogs = dailyLogs.filter { $0.totalVolume > 0 }.prefix(7).reversed()
                                ForEach(Array(validLogs), id: \.id) { log in
                                    BarMark(
                                        x: .value("Date", log.date, unit: .day),
                                        y: .value("Volume", log.totalVolume)
                                    )
                                    .foregroundStyle(FriendlyTheme.apexGreen.gradient)
                                    .cornerRadius(6)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                                        .foregroundStyle(FriendlyTheme.textSecondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                        .foregroundStyle(Color.white.opacity(0.1))
                                    if let volume = value.as(Double.self) {
                                        AxisValueLabel {
                                            Text("\(Int(volume / 1000))k")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .padding(20)
                            .background(.ultraThinMaterial)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            .padding(.horizontal, 20)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 40))
                                .foregroundColor(FriendlyTheme.textSecondary.opacity(0.5))
                            Text("NO DATA YET")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                        .padding(.top, 40)
                    }
                    
                    // Heavy Duty Intensity & Recovery Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("HEAVY DUTY INTENSITY")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(3.0)
                            .padding(.horizontal, 24)
                        
                        // Motor Unit Recruitment Trend Chart
                        if dailyLogs.filter({ $0.maxMotorUnitRecruitment > 0 }).count > 0 {
                            Chart {
                                let validLogs = dailyLogs.filter { $0.maxMotorUnitRecruitment > 0 }.prefix(7).reversed()
                                ForEach(Array(validLogs), id: \.id) { log in
                                    LineMark(
                                        x: .value("Date", log.date, unit: .day),
                                        y: .value("Recruitment", log.maxMotorUnitRecruitment * 100)
                                    )
                                    .foregroundStyle(FriendlyTheme.limeSignal)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                    .interpolationMethod(.monotone)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                                        .foregroundStyle(FriendlyTheme.textSecondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .stride(by: 25)) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                        .foregroundStyle(Color.white.opacity(0.1))
                                    if let pct = value.as(Double.self) {
                                        AxisValueLabel {
                                            Text("\(Int(pct))%")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                        }
                                    }
                                }
                            }
                            .chartYScale(domain: 0...100)
                            .frame(height: 150)
                            .padding(20)
                            .background(FriendlyTheme.midnightMatteLight)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        
                        // Recovery Recommendation Card
                        VStack(alignment: .leading, spacing: 12) {
                            let status = recoveryStatus
                            HStack {
                                Image(systemName: status.color == FriendlyTheme.apexGreen ? "checkmark.circle.fill" : (status.color == .red ? "exclamationmark.triangle.fill" : "moon.zzz.fill"))
                                    .foregroundColor(status.color)
                                Text("RECOVERY STATUS")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .tracking(3.0)
                            }
                            
                            Text(status.title)
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(status.color)
                            
                            Text(status.message)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Henneman Meter Component (Linear Bar)
struct HennemanMeterView: View {
    var recruitmentLevel: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MOTOR UNIT RECRUITMENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .tracking(2.0)
                
                Spacer()
                
                Text("\(Int(recruitmentLevel * 100))%")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(FriendlyTheme.apexGreen)
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
                            LinearGradient(gradient: Gradient(colors: [FriendlyTheme.limeSignal, FriendlyTheme.apexGreen]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geometry.size.width * CGFloat(recruitmentLevel), height: 8)
                        .shadow(color: FriendlyTheme.apexGreen.opacity(0.5), radius: 4, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: recruitmentLevel)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
