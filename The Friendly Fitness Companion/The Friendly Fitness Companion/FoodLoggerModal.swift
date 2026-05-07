import SwiftUI
import SwiftData

struct FoodLoggerModal: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @StateObject private var apiManager = NutritionAPIManager.shared
    @State private var searchText = ""
    @State private var selectedFood: UnifiedFoodItem?
    
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
                        
                        // Global Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(FriendlyTheme.textSecondary)
                            TextField("Search global food database...", text: $searchText)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: searchText) { _, newValue in
                                    if !newValue.isEmpty && newValue.count > 2 {
                                        apiManager.searchFoods(query: newValue)
                                    }
                                }
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    apiManager.searchResults.removeAll()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        if !searchText.isEmpty {
                            // Search Results List
                            if apiManager.isSearching {
                                HStack {
                                    Spacer()
                                    ProgressView().tint(FriendlyTheme.apexGreen)
                                    Spacer()
                                }
                                .padding(.top, 32)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(apiManager.searchResults, id: \.self) { result in
                                        FoodSearchResultRow(item: result) {
                                            selectedFood = UnifiedFoodItem(
                                                name: result.name,
                                                brand: result.brand,
                                                calories: result.calories,
                                                protein: result.protein,
                                                fat: result.fat,
                                                carbs: result.carbs,
                                                sodium: result.sodium,
                                                isVerified: true,
                                                servingSize: result.servingSize,
                                                grade: result.grade,
                                                imageUrl: result.imageUrl
                                            )
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        } else {
                            // QUICK-ADD STAPLES
                            Text("QUICK-ADD STAPLES")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            
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
                                        .background(FriendlyTheme.midnightMatteLight)
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
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
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
                                .background(FriendlyTheme.midnightMatteLight)
                                .cornerRadius(20)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                        
                        Spacer(minLength: 40)
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
            .sheet(item: $selectedFood) { food in
                FoodActionSheetView(food: food) { multiplier in
                    logFood(
                        name: food.name,
                        cal: Int(food.calories * multiplier),
                        pro: Int(food.protein * multiplier),
                        fat: Int(food.fat * multiplier),
                        carb: Int(food.carbs * multiplier),
                        sod: Int(food.sodium * multiplier),
                        pot: 0,
                        mag: 0
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func logFood(name: String, cal: Int, pro: Int, fat: Int, carb: Int, sod: Int, pot: Int, mag: Int) {
        HapticManager.shared.medium()
        
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

struct FoodSearchResultRow: View {
    let item: APIFoodItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(item.brand) • \(item.servingSize ?? "1 serving")")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(item.calories))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("cal")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 70)
            }
        }
    }
}
