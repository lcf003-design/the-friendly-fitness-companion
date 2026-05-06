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
                    .padding(.bottom, 10)
                    
                    // Analytics: Tonnage Volume Chart
                    if dailyLogs.filter({ $0.totalVolume > 0 }).count > 0 {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("WORKOUT VOLUME TRENDS")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .tracking(2.0)
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
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
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
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                        .padding(.top, 40)
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
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(Int(recruitmentLevel * 100))%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
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
