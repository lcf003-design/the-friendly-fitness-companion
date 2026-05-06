import SwiftUI
import SwiftData
import Charts

struct ProgressViewTab: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \DailyLog.date, order: .forward) private var dailyLogs: [DailyLog]
    @Query(sort: \FastingSession.startTime, order: .reverse) private var fastingSessions: [FastingSession]
    
    @State private var pdfURL: URL?
    
    // Generate dates for the current month
    private var currentMonthDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else { return [] }
        
        var days: [Date] = []
        var currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return days
    }
    
    private func logForDate(_ date: Date) -> DailyLog? {
        let calendar = Calendar.current
        return dailyLogs.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 18))
                        
                        Text("PROGRESS")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if let url = TechnicalReportGenerator.generatePDF(dailyLogs: dailyLogs) {
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Heatmap Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("INTENSITY GRID")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(2.0)
                        
                        // Calendar Grid Layout
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(currentMonthDays, id: \.self) { date in
                                let log = logForDate(date)
                                let recruitment = log?.maxMotorUnitRecruitment ?? 0.0
                                
                                HeatmapDayCell(date: date, recruitment: recruitment)
                            }
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.horizontal, 20)
                    
                    // Advanced Audit Panel
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ADVANCED AUDIT")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Toggle("Only Heavy Duty Certified Sets", isOn: $filterOnlyFailureSets)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .tint(FriendlyTheme.limeSignal)
                        
                        HStack {
                            Menu {
                                ForEach(["All", "Standard", "Nautilus", "Hammer Strength", "MedX", "Cybex"], id: \.self) { brand in
                                    Button(brand) { filterEquipmentBrand = brand }
                                }
                            } label: {
                                HStack {
                                    Text("BRAND: \(filterEquipmentBrand)")
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            }
                            
                            Menu {
                                ForEach(["All", "Free Weight", "Selectorized", "Plate-Loaded", "Cable"], id: \.self) { type in
                                    Button(type) { filterResistanceType = type }
                                }
                            } label: {
                                HStack {
                                    Text("TYPE: \(filterResistanceType)")
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.horizontal, 20)
                    
                    // Deep Analytics: 1RM Progression Chart
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("1RM PROGRESSION")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .tracking(2.0)
                            Spacer()
                            // Just showing an indicator that this is 90-day data
                            Text("ALL TIME")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(FriendlyTheme.apexGreen.opacity(0.2))
                                .cornerRadius(6)
                        }
                        
                        Toggle("Use Intensity-Adjusted 1RM", isOn: $appState.useIntensityAdjusted1RM)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tint(FriendlyTheme.apexGreen)
                            .padding(.bottom, 8)
                        
                        let chartData = generateChartData()
                        
                        if chartData.isEmpty {
                            Text("Log more sets in the Forge to generate analytics.")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.top, 10)
                        } else {
                            // Picker to filter by exercise
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(Set(chartData.map { $0.exercise })).sorted(), id: \.self) { exercise in
                                        Button(action: {
                                            selectedChartExercise = exercise
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                        }) {
                                            Text(exercise)
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedChartExercise == exercise ? FriendlyTheme.apexGreen : Color(white: 0.15))
                                                .foregroundColor(selectedChartExercise == exercise ? .black : .white)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                            
                            // The actual Chart
                            Chart {
                                ForEach(chartData.filter { selectedChartExercise == nil || $0.exercise == selectedChartExercise }) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("1RM (Lbs)", point.calculated1RM)
                                    )
                                    .interpolationMethod(.catmullRom) // Smooth curves
                                    .foregroundStyle(FriendlyTheme.apexGreen)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    
                                    AreaMark(
                                        x: .value("Date", point.date),
                                        y: .value("1RM (Lbs)", point.calculated1RM)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [FriendlyTheme.apexGreen.opacity(0.3), Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    
                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("1RM (Lbs)", point.calculated1RM)
                                    )
                                    .foregroundStyle(point.hitAbsoluteFailure ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen)
                                    .symbolSize(50)
                                }
                            }
                            .frame(height: 250)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 7)) {
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.1))
                                    AxisValueLabel(format: .dateTime.month().day(), anchor: .top)
                                        .foregroundStyle(FriendlyTheme.textSecondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) {
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.1))
                                    AxisValueLabel()
                                        .foregroundStyle(FriendlyTheme.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.horizontal, 20)
                    
                    // Prime Performance Insight
                    if let insight = generatePrimeInsight() {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(FriendlyTheme.limeSignal)
                                Text("PRIME PERFORMANCE")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .tracking(2.0)
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                Spacer()
                            }
                            
                            Text(insight)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        .padding(24)
                        .background(FriendlyTheme.limeSignal.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 30).stroke(FriendlyTheme.limeSignal.opacity(0.3), lineWidth: 1))
                        .cornerRadius(30)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Auto-select the first exercise if available
            let data = generateChartData()
            if selectedChartExercise == nil, let first = data.first {
                selectedChartExercise = first.exercise
            }
        }
    }
    
    // MARK: - Analytics Data Engine
    @State private var selectedChartExercise: String? = nil
    
    // Advanced Audit Filters
    @State private var filterEquipmentBrand: String = "All"
    @State private var filterResistanceType: String = "All"
    @State private var filterOnlyFailureSets: Bool = false
    
    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let exercise: String
        let calculated1RM: Double
        let hitAbsoluteFailure: Bool
    }
    
    private func generateChartData() -> [ChartDataPoint] {
        var dataPoints: [ChartDataPoint] = []
        
        for log in dailyLogs {
            for workout in log.workouts {
                // Find the best set for this workout to represent the 1RM
                var best1RM: Double = 0
                var hitAbsoluteFailure: Bool = false
                for set in workout.sets {
                    if set.isAbsoluteFailure == true { hitAbsoluteFailure = true }
                    
                    // Brzycki: Weight / (1.0278 - (0.0278 * Reps))
                    // Using totalReps to account for Rest-Pause
                    let baseReps = Double(set.totalReps)
                    let effectiveReps = appState.useIntensityAdjusted1RM ? (baseReps + (Double(set.forcedRepsCount) * 1.5) + (Double(set.negativesCount) * 2.0)) : baseReps
                    
                    let w = set.weight
                    guard effectiveReps > 0 else { continue }
                    
                    let current1RM = w / (1.0278 - (0.0278 * effectiveReps))
                    if current1RM > best1RM {
                        best1RM = current1RM
                    }
                }
                
                // Advanced Audit Filters
                if filterEquipmentBrand != "All" && (workout.equipmentBrand ?? "Standard") != filterEquipmentBrand { continue }
                if filterResistanceType != "All" && (workout.resistanceType ?? "Free Weight") != filterResistanceType { continue }
                if filterOnlyFailureSets && !hitAbsoluteFailure { continue }
                
                if best1RM > 0 {
                    dataPoints.append(ChartDataPoint(
                        date: log.date,
                        exercise: workout.exerciseName,
                        calculated1RM: best1RM,
                        hitAbsoluteFailure: hitAbsoluteFailure
                    ))
                }
            }
        }
        
        return dataPoints.sorted(by: { $0.date < $1.date })
    }
    
    private func generatePrimeInsight() -> String? {
        let chartData = generateChartData()
        guard !chartData.isEmpty, !fastingSessions.isEmpty else { return nil }
        
        let allSessions = fastingSessions.filter { $0.endTime != nil }
        guard !allSessions.isEmpty else { return nil }
        
        // Find the absolute highest 1RM
        if let max1RM = chartData.max(by: { $0.calculated1RM < $1.calculated1RM }) {
            // Find fasting sessions within 24h before this workout
            let calendar = Calendar.current
            for session in allSessions {
                if let end = session.endTime, end <= max1RM.date, calendar.dateComponents([.hour], from: end, to: max1RM.date).hour ?? 24 < 24 {
                    let hours = Int(session.duration / 3600)
                    if hours >= 12 {
                        // Estimate spike
                        let avg1RM = chartData.map { $0.calculated1RM }.reduce(0, +) / Double(chartData.count)
                        let spikePercent = Int(((max1RM.calculated1RM - avg1RM) / avg1RM) * 100)
                        let percentStr = spikePercent > 0 ? "\(spikePercent)%" : "Peak"
                        return "PRIME WINDOW DETECTED: \(hours)h Fast = \(percentStr) Intensity Spike for \(max1RM.exercise)."
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Heatmap Cell
struct HeatmapDayCell: View {
    var date: Date
    var recruitment: Double
    
    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        let dayString = Calendar.current.component(.day, from: date)
        
        ZStack {
            // Background Logic
            RoundedRectangle(cornerRadius: 8)
                .fill(fillColor)
                .aspectRatio(1.0, contentMode: .fit)
                // Neon Logic: 100% gets massive bloom
                .shadow(color: shadowColor, radius: recruitment >= 1.0 ? 10 : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.white : Color.clear, lineWidth: 1.5)
                )
            
            Text("\(dayString)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(recruitment > 0 ? .black : FriendlyTheme.textSecondary.opacity(0.5))
        }
    }
    
    private var fillColor: Color {
        if recruitment >= 1.0 {
            return FriendlyTheme.limeSignal // 100%
        } else if recruitment >= 0.8 {
            return FriendlyTheme.apexGreen.opacity(0.6) // 80%+ Muted Green
        } else if recruitment > 0.0 {
            return FriendlyTheme.apexGreen.opacity(0.3) // Light day
        } else {
            return Color(white: 0.1) // Rest day (Dark Matte)
        }
    }
    
    private var shadowColor: Color {
        if recruitment >= 1.0 {
            return FriendlyTheme.limeSignal.opacity(0.8)
        } else if recruitment >= 0.8 {
            return FriendlyTheme.apexGreen.opacity(0.4)
        }
        return .clear
    }
}

#Preview {
    ProgressViewTab()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
