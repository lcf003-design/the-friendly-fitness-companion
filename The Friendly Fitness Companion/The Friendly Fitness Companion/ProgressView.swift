import SwiftUI
import SwiftData

struct ProgressViewTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .forward) private var dailyLogs: [DailyLog]
    
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
                }
                .padding(.bottom, 50)
            }
        }
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
