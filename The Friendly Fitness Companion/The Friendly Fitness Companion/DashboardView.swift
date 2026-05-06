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
    @EnvironmentObject var appState: AppState
    @Query private var dailyLogs: [DailyLog]
    @Query private var metabolicGoals: [MetabolicGoal]
    
    @State private var showFoodLogger = false
    
    init() {
        var descriptor = FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 30 // Prevent querying hundreds of logs unnecessarily
        _dailyLogs = Query(descriptor)
    }
    
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
                        Button(action: {
                            withAnimation {
                                appState.isDrawerOpen = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 24))
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        
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
                    
                    // Dynamic Budgeting
                    MetabolicBudgetView(dailyLogs: dailyLogs, metabolicGoals: metabolicGoals, showFoodLogger: $showFoodLogger)
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
                    
                    // Fasting Protocol Access
                    VStack(alignment: .leading, spacing: 20) {
                        Text("FASTING PROTOCOL")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(3.0)
                            .padding(.horizontal, 24)
                        
                        Button(action: {
                            appState.selectedTab = 13
                        }) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("FASTING HUB")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .tracking(2.0)
                                        .foregroundColor(.white)
                                    Text("Track metabolic stages & longevity")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showFoodLogger) {
            FoodLoggerModal()
        }
    }
}

// MARK: - Henneman Meter Component (Linear Bar)
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

// MARK: - Dynamic Budgeting Component
struct MetabolicBudgetView: View {
    var dailyLogs: [DailyLog]
    var metabolicGoals: [MetabolicGoal]
    @Binding var showFoodLogger: Bool
    
    private var goal: MetabolicGoal {
        metabolicGoals.first ?? MetabolicGoal()
    }
    
    private var todayLog: DailyLog? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dailyLogs.first(where: { calendar.startOfDay(for: $0.date) == today })
    }
    
    private var consumedCalories: Int {
        todayLog?.foodEntries.reduce(0) { $0 + $1.calories } ?? 0
    }
    
    private var consumedProtein: Int {
        todayLog?.foodEntries.reduce(0) { $0 + $1.protein } ?? 0
    }
    
    private var consumedFat: Int {
        todayLog?.foodEntries.reduce(0) { $0 + $1.fat } ?? 0
    }
    
    private var consumedCarbs: Int {
        todayLog?.foodEntries.reduce(0) { $0 + $1.carbs } ?? 0
    }
    
    private var consumedSodium: Int {
        todayLog?.foodEntries.reduce(0) { $0 + $1.sodium } ?? 0
    }
    
    private var consumedPotassium: Int {
        todayLog?.foodEntries.reduce(0) { $0 + $1.potassium } ?? 0
    }
    
    private var consumedMagnesium: Int {
        todayLog?.foodEntries.reduce(0) { $0 + $1.magnesium } ?? 0
    }
    
    private var hasRecentAbsoluteFailure: Bool {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        return dailyLogs.contains { log in
            log.date >= yesterday && log.workouts.contains { workout in
                workout.sets.contains { set in
                    set.isAbsoluteFailure == true
                }
            }
        }
    }
    
    private var effectiveCalorieTarget: Int {
        if goal.isAutopilotEnabled && hasRecentAbsoluteFailure {
            return Int(Double(goal.dailyCalorieTarget) * 1.10)
        }
        return goal.dailyCalorieTarget
    }
    
    private var effectiveProteinTarget: Int {
        let baseTarget = Int((Double(effectiveCalorieTarget) * (goal.proteinPercent / 100)) / 4.0)
        if goal.isAutopilotEnabled && hasRecentAbsoluteFailure {
            return baseTarget + 15
        }
        return baseTarget
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("METABOLIC FUEL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .tracking(3.0)
                
                if goal.isAutopilotEnabled && hasRecentAbsoluteFailure {
                    Text("AUTOPILOT ACTIVE")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FriendlyTheme.apexGreen.opacity(0.2))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: { showFoodLogger = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("LOG FOOD")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(FriendlyTheme.apexGreen)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                // Calorie Card
                let remaining = effectiveCalorieTarget - consumedCalories
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(remaining)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(remaining < 0 ? Color(red: 214/255, green: 160/255, blue: 84/255) : .white) // Turn Gold if over
                        Text(remaining < 0 ? "KCAL OVER" : "KCAL LEFT")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(consumedCalories) / \(effectiveCalorieTarget)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("CONSUMED")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Macro Strips
                VStack(spacing: 12) {
                    // Calculate targets based on calorie split
                    let fTarget = Int((Double(effectiveCalorieTarget) * (goal.fatPercent / 100)) / 9.0)
                    let cTarget = Int((Double(effectiveCalorieTarget) * (goal.carbPercent / 100)) / 4.0)
                    
                    MacroStrip(label: "PROTEIN", current: consumedProtein, target: effectiveProteinTarget, color: FriendlyTheme.apexGreen)
                    MacroStrip(label: "FAT", current: consumedFat, target: fTarget, color: Color(red: 214/255, green: 160/255, blue: 84/255))
                    MacroStrip(label: "NET CARBS", current: consumedCarbs, target: cTarget, color: Color(red: 47/255, green: 79/255, blue: 79/255))
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Electrolyte Command
                VStack(spacing: 8) {
                    HStack {
                        Text("ELECTROLYTE COMMAND")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                    }
                    
                    ElectrolyteStrip(label: "SODIUM", current: consumedSodium, target: 5000)
                    ElectrolyteStrip(label: "POTASSIUM", current: consumedPotassium, target: 3500)
                    ElectrolyteStrip(label: "MAGNESIUM", current: consumedMagnesium, target: 400)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
}

struct MacroStrip: View {
    let label: String
    let current: Int
    let target: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                Spacer()
                Text("\(current) / \(target)g")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    let progress = target > 0 ? min(Double(current) / Double(target), 1.0) : (current > 0 ? 1.0 : 0.0)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
    }
}

struct ElectrolyteStrip: View {
    let label: String
    let current: Int
    let target: Int
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                Spacer()
                Text("\(current)/\(target)mg")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundColor(FriendlyTheme.limeSignal)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 2)
                        .cornerRadius(1)
                    
                    let progress = target > 0 ? min(Double(current) / Double(target), 1.0) : (current > 0 ? 1.0 : 0.0)
                    
                    Rectangle()
                        .fill(FriendlyTheme.limeSignal)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 2)
                        .shadow(color: FriendlyTheme.limeSignal.opacity(0.6), radius: 2, x: 0, y: 0)
                        .cornerRadius(1)
                }
            }
            .frame(height: 2)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
