import SwiftUI
import SwiftData

struct FoodLoggerModal: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    // Quick Add Staples (Name, Cal, Pro, Fat, Carb, Sodium, Potassium, Magnesium)
    let presets = [
        ("Ribeye (1 lb)", 1050, 80, 85, 0, 250, 1400, 90),
        ("Ground Beef 80/20 (1 lb)", 1150, 75, 90, 0, 300, 1200, 80),
        ("Large Egg (1)", 78, 6, 5, 0, 70, 70, 5),
        ("Butter (1 tbsp)", 100, 0, 11, 0, 90, 3, 0),
        ("Bacon (3 slices)", 130, 9, 10, 0, 400, 150, 10),
        ("Electrolyte Mix", 0, 0, 0, 0, 1000, 200, 60)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("QUICK-ADD STAPLES")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(presets, id: \.0) { preset in
                                Button(action: { logFood(name: preset.0, cal: preset.1, pro: preset.2, fat: preset.3, carb: preset.4, sod: preset.5, pot: preset.6, mag: preset.7) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(preset.0.uppercased())
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("\(preset.1) kcal • \(preset.2)g P • \(preset.3)g F • \(preset.4)g C")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(FriendlyTheme.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                            .font(.system(size: 24))
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.05))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Link to Grocery Check
                        NavigationLink(destination: GroceryCheckView()) {
                            HStack {
                                Image(systemName: "scale.3d")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("LABEL AUDIT")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .tracking(1.0)
                                        .foregroundColor(.white)
                                    Text("Verify protein yield via Grocery Check")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("LOG FOOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func logFood(name: String, cal: Int, pro: Int, fat: Int, carb: Int, sod: Int, pot: Int, mag: Int) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let todayLog = getTodayLog()
        let newEntry = FoodEntry(name: name, calories: cal, protein: pro, fat: fat, carbs: carb, sodium: sod, potassium: pot, magnesium: mag)
        todayLog.foodEntries.append(newEntry)
        
        try? modelContext.save()
        dismiss()
    }
    
    private func getTodayLog() -> DailyLog {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existing = dailyLogs.first(where: { calendar.startOfDay(for: $0.date) == today }) {
            return existing
        } else {
            let newLog = DailyLog(date: today)
            modelContext.insert(newLog)
            return newLog
        }
    }
}
