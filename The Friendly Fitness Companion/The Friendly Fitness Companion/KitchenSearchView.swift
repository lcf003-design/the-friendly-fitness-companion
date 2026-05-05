import SwiftUI
import SwiftData

struct KitchenSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var searchText: String = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        Text("THE KITCHEN")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "bell")
                            .font(.title2)
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(FriendlyTheme.textSecondary)
                        TextField("Search foods...", text: $searchText)
                            .foregroundColor(.white)
                            .submitLabel(.search)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: FriendlyTheme.apexGreen))
                        } else {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                    }
                    .padding()
                    .background(FriendlyTheme.midnightMatteLight)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Compact Result List
                    ScrollView {
                        VStack(spacing: 0) {
                            if searchResults.isEmpty && !isLoading && !searchText.isEmpty {
                                Text("Hit 'Return' to search the global database.")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .font(.system(size: 14))
                                    .padding(.top, 40)
                            }
                            
                            ForEach(searchResults) { result in
                                NavigationLink(destination: FoodDetailView(result: result)) {
                                    FoodListRow(result: result)
                                }
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - API Logic
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        searchResults = []
        
        Task {
            do {
                let results = try await NutritionAPIService.shared.searchFood(query: searchText)
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.isLoading = false
                }
            } catch {
                print("Search failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Compact List Row
struct FoodListRow: View {
    var result: FoodSearchResult
    
    var body: some View {
        HStack(spacing: 16) {
            // Generic Icon based on Tier
            Circle()
                .fill(FriendlyTheme.midnightMatteLight)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: result.tier == "Apex" ? "flame.fill" : (result.tier == "Modern" ? "exclamationmark.triangle.fill" : "leaf.fill"))
                        .foregroundColor(result.tier == "Apex" ? FriendlyTheme.limeSignal : (result.tier == "Modern" ? FriendlyTheme.mutedAmber : FriendlyTheme.apexGreen))
                        .font(.system(size: 14))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(result.tier)
                    .font(.system(size: 12))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            Spacer()
            
            // Basic Cals/Macros preview (Estimating cals from macros for display)
            let estimatedCals = (result.fatGrams * 9) + (result.proteinGrams * 4) + (result.carbsGrams * 4)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(estimatedCals)) cals")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FriendlyTheme.apexGreen)
                Text("per 100g")
                    .font(.system(size: 12))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            // Empty Circle like MyNetDiary
            Circle()
                .stroke(FriendlyTheme.textSecondary.opacity(0.5), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .padding(.leading, 8)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle()) // Makes the whole row tappable
    }
}

// MARK: - Dedicated Detail Screen
struct FoodDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    var result: FoodSearchResult
    @State private var servingSizeGrams: String = "100"
    
    // Scaled Macros based on input serving size
    private var scaleFactor: Double {
        let grams = Double(servingSizeGrams) ?? 100.0
        return grams / 100.0
    }
    
    private var scaledFat: Double { result.fatGrams * scaleFactor }
    private var scaledProtein: Double { result.proteinGrams * scaleFactor }
    private var scaledCarbs: Double { result.carbsGrams * scaleFactor }
    private var totalMacros: Double {
        let total = scaledFat + scaledProtein + scaledCarbs
        return total > 0 ? total : 1.0
    }
    
    private var estimatedCals: Double {
        return (scaledFat * 9) + (scaledProtein * 4) + (scaledCarbs * 4)
    }
    
    private func getOrCreateTodayLog() -> DailyLog {
        let calendar = Calendar.current
        if let todayLog = dailyLogs.first(where: { calendar.isDateInToday($0.date) }) {
            return todayLog
        } else {
            let newLog = DailyLog()
            modelContext.insert(newLog)
            return newLog
        }
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 1. Hero Header
                    ZStack(alignment: .bottomLeading) {
                        // Placeholder Image (Gradient for premium feel)
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 20/255, green: 20/255, blue: 25/255), FriendlyTheme.midnightMatte]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 250)
                        
                        // Icon Overlay in center
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.1))
                            .position(x: UIScreen.main.bounds.width/2, y: 125)
                        
                        HStack(alignment: .bottom) {
                            Text(result.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .shadow(radius: 5)
                            
                            Spacer()
                            
                            // Tier Badge
                            Text(result.tier)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(result.tier == "Apex" ? .black : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(result.tier == "Apex" ? FriendlyTheme.limeSignal : (result.tier == "Ancestral" ? Color.blue : FriendlyTheme.mutedAmber))
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                    
                    VStack(spacing: 24) {
                        // 2. Quantity & Calories
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Weight (g)")
                                    .font(.system(size: 12))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("100", text: $servingSizeGrams)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                                Divider().background(Color.white.opacity(0.2))
                            }
                            .frame(width: 100)
                            
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(estimatedCals))")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundColor(.blue) // MyNetDiary style blue cals
                                Text("cals")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // 3. Macros
                        HStack(spacing: 20) {
                            MacroStatView(label: "FAT", value: "\(Int(scaledFat))g", color: FriendlyTheme.mutedAmber, percent: scaledFat / totalMacros)
                            MacroStatView(label: "PROTEIN", value: "\(Int(scaledProtein))g", color: FriendlyTheme.apexGreen, percent: scaledProtein / totalMacros)
                            MacroStatView(label: "CARBS", value: "\(Int(scaledCarbs))g", color: .blue, percent: scaledCarbs / totalMacros)
                        }
                        
                        // 4. Alerts
                        if result.containsSeedOils {
                            FriendlyAlertView(message: "Contains Seed Oils. Not the friendliest choice for your gut! Try tallow or butter instead?")
                        }
                        if result.containsRefinedSugars {
                            FriendlyAlertView(message: "Contains refined sugars. An Ancestral sweetener like raw honey might be better!")
                        }
                        
                        Spacer(minLength: 40)
                        
                        // 5. Action Buttons
                        HStack {
                            Text("The Kitchen")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(FriendlyTheme.apexGreen)
                            
                            Spacer()
                            
                            Button(action: saveMeal) {
                                Text("Log")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 12)
                                    .background(FriendlyTheme.apexGreen)
                                    .foregroundColor(.black)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Custom Back button appearance implicitly handled by iOS
    }
    
    // MARK: - Persistence
    private func saveMeal() {
        let todayLog = getOrCreateTodayLog()
        
        let newMeal = MealEntry(
            name: result.name,
            tier: result.tier,
            fat: scaledFat,
            protein: scaledProtein,
            carbs: scaledCarbs,
            hasSeedOils: result.containsSeedOils,
            hasSugars: result.containsRefinedSugars
        )
        
        newMeal.dailyLog = todayLog
        todayLog.meals.append(newMeal)
        modelContext.insert(newMeal)
        
        todayLog.totalFatGrams += scaledFat
        todayLog.totalProteinGrams += scaledProtein
        todayLog.totalCarbsGrams += scaledCarbs
        
        do {
            try modelContext.save()
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            dismiss() // Pop back to search view
        } catch {
            print("Failed to save meal: \(error.localizedDescription)")
        }
    }
}

// MARK: - Shared UI Components
struct MacroStatView: View {
    var label: String
    var value: String
    var color: Color
    var percent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(FriendlyTheme.midnightMatteLight)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: max(0, geometry.size.width * CGFloat(percent)), height: 4)
                }
            }
            .frame(height: 4)
            
            Text("\(Int(percent * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct FriendlyAlertView: View {
    var message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(FriendlyTheme.mutedAmber)
                .font(.system(size: 16))
                .padding(.top, 2)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(FriendlyTheme.mutedAmber)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 51/255, green: 37/255, blue: 19/255))
        .cornerRadius(12)
    }
}

#Preview {
    KitchenSearchView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
