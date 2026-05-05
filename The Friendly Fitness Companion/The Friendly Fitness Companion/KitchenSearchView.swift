import SwiftUI
import SwiftData

struct KitchenSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var searchText: String = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isLoading: Bool = false
    
    // Track which item triggered the success flash
    @State private var loggedItemId: UUID? = nil
    
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
                    TextField("Search for Food...", text: $searchText)
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
                .cornerRadius(30)
                .padding(.horizontal)
                
                // Result List
                ScrollView {
                    VStack(spacing: 20) {
                        if searchResults.isEmpty && !isLoading && !searchText.isEmpty {
                            Text("Hit 'Return' to search the global database.")
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .font(.system(size: 14))
                                .padding(.top, 40)
                        }
                        
                        ForEach(searchResults) { result in
                            VStack(spacing: 20) {
                                FoodResultCard(result: result)
                                
                                // Log Meal Button
                                Button(action: {
                                    saveMeal(result: result)
                                }) {
                                    HStack {
                                        Text(loggedItemId == result.id ? "LOGGED TO DAILY LOG" : "LOG MEAL")
                                            .font(.system(size: 16, weight: .bold))
                                            .tracking(1.5)
                                        if loggedItemId == result.id {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(loggedItemId == result.id ? FriendlyTheme.midnightMatteLight : FriendlyTheme.apexGreen)
                                    .foregroundColor(loggedItemId == result.id ? FriendlyTheme.apexGreen : .black)
                                    .cornerRadius(30)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
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
    
    // MARK: - SwiftData Persistence
    private func saveMeal(result: FoodSearchResult) {
        let todayLog = getOrCreateTodayLog()
        
        let newMeal = MealEntry(
            name: result.name,
            tier: result.tier,
            fat: result.fatGrams,
            protein: result.proteinGrams,
            carbs: result.carbsGrams,
            hasSeedOils: result.containsSeedOils,
            hasSugars: result.containsRefinedSugars
        )
        
        newMeal.dailyLog = todayLog
        todayLog.meals.append(newMeal)
        modelContext.insert(newMeal)
        
        // Update Daily Summary
        todayLog.totalFatGrams += result.fatGrams
        todayLog.totalProteinGrams += result.proteinGrams
        todayLog.totalCarbsGrams += result.carbsGrams
        
        do {
            try modelContext.save()
            triggerSuccessFeedback(for: result.id)
        } catch {
            print("Failed to save meal: \(error.localizedDescription)")
        }
    }
    
    private func triggerSuccessFeedback(for id: UUID) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        withAnimation { loggedItemId = id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { loggedItemId = nil }
        }
    }
}

struct FoodResultCard: View {
    var result: FoodSearchResult
    
    // Helper to calculate percentages for the progress bars
    private var totalMacros: Double {
        let total = result.fatGrams + result.proteinGrams + result.carbsGrams
        return total > 0 ? total : 1.0 // prevent division by zero
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Info & Badge
            HStack(alignment: .top) {
                // Image Placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(FriendlyTheme.textSecondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text("Per 100g")
                        .font(.system(size: 14))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Tier Badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text(result.tier)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(result.tier == "Apex" ? FriendlyTheme.limeSignal : (result.tier == "Ancestral" ? .white : FriendlyTheme.apexGreen))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(FriendlyTheme.midnightMatte)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(result.tier == "Apex" ? FriendlyTheme.limeSignal : (result.tier == "Ancestral" ? .white : FriendlyTheme.apexGreen), lineWidth: 1)
                )
            }
            
            // Macros
            HStack(spacing: 20) {
                MacroStatView(label: "FAT", value: "\(Int(result.fatGrams))g", color: FriendlyTheme.mutedAmber, percent: result.fatGrams / totalMacros)
                MacroStatView(label: "PROTEIN", value: "\(Int(result.proteinGrams))g", color: FriendlyTheme.apexGreen, percent: result.proteinGrams / totalMacros)
                MacroStatView(label: "CARBS", value: "\(Int(result.carbsGrams))g", color: .blue, percent: result.carbsGrams / totalMacros)
            }
            
            // Alerts
            if result.containsSeedOils {
                FriendlyAlertView(message: "Not the friendliest choice for your gut! Try tallow or butter instead?")
            }
            if result.containsRefinedSugars {
                FriendlyAlertView(message: "Contains refined sugars. An Ancestral sweetener like raw honey might be better!")
            }
        }
        .padding(20)
        .background(FriendlyTheme.midnightMatteLight)
        .cornerRadius(24)
        .shadow(color: FriendlyTheme.apexGreen.opacity(0.05), radius: 20, x: 0, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(FriendlyTheme.apexGreen.opacity(0.1), lineWidth: 1)
        )
    }
}
