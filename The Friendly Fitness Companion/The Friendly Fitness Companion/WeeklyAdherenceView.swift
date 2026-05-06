import SwiftUI
import SwiftData

struct WeeklyAdherenceView: View {
    @Query private var dailyLogs: [DailyLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Adherence")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    AdherenceSquare(dayOffset: 6 - dayOffset, dailyLogs: dailyLogs)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(FriendlyTheme.midnightMatteLight)
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

struct AdherenceSquare: View {
    let dayOffset: Int
    let dailyLogs: [DailyLog]
    
    var statusColor: Color {
        let targetDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: targetDate)
        
        guard let log = dailyLogs.first(where: { $0.id == dateString }) else {
            return Color.white.opacity(0.1) // Muted Gray/Empty
        }
        
        let targetProtein: Double = 180.0
        let targetCalories: Double = 2500.0
        
        let totalProtein = log.foodEntries.reduce(0) { $0 + $1.protein }
        let totalCalories = log.foodEntries.reduce(0) { $0 + $1.calories }
        
        let proteinHit = Double(totalProtein) >= targetProtein
        let calDiff = abs(Double(totalCalories) - Double(targetCalories)) / Double(targetCalories)
        let calorieHit = calDiff <= 0.05
        
        if proteinHit && calorieHit {
            return FriendlyTheme.apexGreen
        } else if proteinHit {
            return .white
        } else {
            return Color.white.opacity(0.2) // Muted Gray (missed)
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(statusColor)
            .frame(height: 32)
            .cornerRadius(8)
    }
}
