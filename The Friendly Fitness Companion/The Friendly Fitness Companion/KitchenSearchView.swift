import SwiftUI
import SwiftData

// Enum for standard units
enum ServingUnit: String, CaseIterable {
    case grams = "g"
    case ounces = "oz"
    case pounds = "lb"
    
    // Multiplier to convert to grams
    var multiplierToGrams: Double {
        switch self {
        case .grams: return 1.0
        case .ounces: return 28.3495
        case .pounds: return 453.592
        }
    }
}

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
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        Text("THE KITCHEN")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "bell")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // Search Bar (Isolated for performance)
                    IsolatedSearchBar(searchText: $searchText, isLoading: isLoading, onSearch: performSearch)
                    
                    // Result List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if searchResults.isEmpty && !isLoading && !searchText.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass.circle")
                                        .font(.system(size: 40, weight: .ultraLight))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                    Text("Hit 'Return' to search the database.")
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.top, 60)
                            }
                            
                            ForEach(searchResults) { result in
                                NavigationLink(destination: FoodDetailView(result: result)) {
                                    FoodListRow(result: result)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        searchResults = []
        
        Task {
            do {
                let results = try await NutritionAPIService.shared.searchFood(query: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                }
            } catch {
                print("Search failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Premium List Row
struct FoodListRow: View {
    var result: FoodSearchResult
    
    var body: some View {
        HStack(spacing: 16) {
            // Elegant Icon
            ZStack {
                Circle()
                    .fill(Color(white: 0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 18))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(result.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Generic")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            Spacer()
            
            let estimatedCals = (result.fatGrams * 9) + (result.proteinGrams * 4) + (result.carbsGrams * 4)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(estimatedCals)) cals")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.blue) 
                
                Text("100g")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(FriendlyTheme.textSecondary.opacity(0.5))
                .padding(.leading, 4)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(white: 0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Isolated Search Bar Component
// This prevents the massive KitchenSearchView (and its @Query) from re-rendering on every keystroke.
struct IsolatedSearchBar: View {
    @Binding var searchText: String
    var isLoading: Bool
    var onSearch: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(FriendlyTheme.textSecondary)
            
            TextField("Search foods...", text: $searchText)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
                .submitLabel(.search)
                .onSubmit {
                    onSearch()
                }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: FriendlyTheme.apexGreen))
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(white: 0.15).opacity(0.8))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Premium Detail Screen
struct FoodDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    var result: FoodSearchResult
    
    @State private var servingSizeValue: String = "100"
    @State private var selectedUnit: ServingUnit = .grams
    
    private var scaleFactor: Double {
        let inputtedAmount = Double(servingSizeValue) ?? 100.0
        let totalGrams = inputtedAmount * selectedUnit.multiplierToGrams
        return totalGrams / 100.0
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
                    // 1. Premium Hero Header
                    ZStack(alignment: .bottomLeading) {
                        ZStack {
                            Color(white: 0.05)
                            Circle()
                                .fill(FriendlyTheme.apexGreen.opacity(0.15))
                                .frame(width: 250, height: 250)
                                .blur(radius: 50)
                                .offset(x: 100, y: -50)
                            
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 200, height: 200)
                                .blur(radius: 60)
                                .offset(x: -80, y: 50)
                        }
                        .frame(height: 250)
                        .clipped()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Spacer()
                            Text(result.name)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5)
                        }
                        .padding(24)
                    }
                    
                    VStack(spacing: 30) {
                        // 2. Unit Selection Grid (MyNetDiary Style)
                        HStack(spacing: 12) {
                            ForEach(ServingUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    withAnimation {
                                        selectedUnit = unit
                                    }
                                }) {
                                    Text(unit.rawValue)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(selectedUnit == unit ? .black : FriendlyTheme.apexGreen)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedUnit == unit ? FriendlyTheme.apexGreen : Color(white: 0.15))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 3. Quantity & Calories
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amount")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                
                                HStack {
                                    TextField("100", text: $servingSizeValue)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(selectedUnit.rawValue)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("\(Int(estimatedCals))")
                                        .font(.system(size: 46, weight: .light, design: .rounded))
                                        .foregroundColor(.blue)
                                    Text("cals")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(white: 0.12))
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // 4. Macros
                        HStack(spacing: 20) {
                            MacroStatView(label: "FAT", value: "\(Int(scaledFat))g", color: FriendlyTheme.mutedAmber, percent: scaledFat / totalMacros)
                            MacroStatView(label: "PROTEIN", value: "\(Int(scaledProtein))g", color: FriendlyTheme.apexGreen, percent: scaledProtein / totalMacros)
                            MacroStatView(label: "CARBS", value: "\(Int(scaledCarbs))g", color: .blue, percent: scaledCarbs / totalMacros)
                        }
                        .padding(24)
                        .background(Color(white: 0.12))
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // 5. Alerts
                        VStack(spacing: 12) {
                            if result.containsSeedOils {
                                FriendlyAlertView(message: "Contains Seed Oils. Not the friendliest choice for your gut! Try tallow or butter instead?")
                            }
                            if result.containsRefinedSugars {
                                FriendlyAlertView(message: "Contains refined sugars. An Ancestral sweetener like raw honey might be better!")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                        
                        // 6. Action Buttons
                        Button(action: saveMeal) {
                            HStack {
                                Text("Log to Daily Tracker")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(24)
                            .shadow(color: FriendlyTheme.apexGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 20)
                    }
                    .offset(y: -20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    private func saveMeal() {
        let todayLog = getOrCreateTodayLog()
        
        let newMeal = MealEntry(
            name: result.name,
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
            dismiss()
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(0, geometry.size.width * CGFloat(percent)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct FriendlyAlertView: View {
    var message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(FriendlyTheme.mutedAmber)
                .font(.system(size: 20))
                .padding(.top, 2)
                .shadow(color: FriendlyTheme.mutedAmber.opacity(0.5), radius: 5)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FriendlyTheme.mutedAmber)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 40/255, green: 30/255, blue: 15/255))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(FriendlyTheme.mutedAmber.opacity(0.3), lineWidth: 1))
    }
}

#Preview {
    KitchenSearchView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
