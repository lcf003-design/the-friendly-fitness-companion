import SwiftUI
import SwiftData

struct FoodConsumptionHistoryView: View {
    let food: UnifiedFoodItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    var historyLogs: [(date: Date, entry: FoodEntry)] {
        var results: [(Date, FoodEntry)] = []
        for log in dailyLogs {
            for entry in log.foodEntries {
                if entry.name.lowercased() == food.name.lowercased() {
                    results.append((log.date, entry))
                }
            }
        }
        return results
    }
    
    var totalTimesConsumed: Int {
        historyLogs.count
    }
    
    var averageCalories: Int {
        guard !historyLogs.isEmpty else { return 0 }
        let total = historyLogs.reduce(0) { $0 + $1.entry.calories }
        return total / historyLogs.count
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("CONSUMPTION HISTORY")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                }
                .padding(24)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Insights
                HStack(spacing: 16) {
                    InsightBox(title: "TOTAL LOGS", value: "\(totalTimesConsumed)")
                    InsightBox(title: "AVG CALORIES", value: "\(averageCalories)")
                }
                .padding(24)
                
                if historyLogs.isEmpty {
                    Spacer()
                    Text("NO HISTORY FOUND")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(historyLogs, id: \.entry.id) { log in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("\(log.entry.calories) kcal • \(log.entry.protein)g P • \(log.entry.fat)g F")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct InsightBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.5)
                .foregroundColor(FriendlyTheme.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(FriendlyTheme.apexGreen)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.02))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
