import SwiftUI
import SwiftData

struct KitchenSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var searchText: String = ""
    @State private var showSuccessFeedback: Bool = false
    
    // Mock Data for display (Pending API Hookup)
    let mockResultName = "Chicken Fajitas (Bowl)"
    let mockResultWeight = "190g"
    let mockTier = "Modern"
    let hasSeedOils = true
    let hasRefinedSugars = false
    
    let fatGrams = 14.0
    let fatPercent = 0.31
    let proteinGrams = 28.0
    let proteinPercent = 0.48
    let carbsGrams = 11.0
    let carbsPercent = 0.21
    
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
                    Text("THE FRIENDLY COMPANION")
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
                    Image(systemName: "barcode.viewfinder")
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
                .padding()
                .background(FriendlyTheme.midnightMatteLight)
                .cornerRadius(30)
                .padding(.horizontal)
                
                // Result Card
                ScrollView {
                    VStack(spacing: 20) {
                        FoodResultCard(
                            name: mockResultName,
                            weight: mockResultWeight,
                            tier: mockTier,
                            fatGrams: fatGrams,
                            fatPercent: fatPercent,
                            proteinGrams: proteinGrams,
                            proteinPercent: proteinPercent,
                            carbsGrams: carbsGrams,
                            carbsPercent: carbsPercent,
                            hasSeedOils: hasSeedOils,
                            hasRefinedSugars: hasRefinedSugars
                        )
                        
                        // Log Meal Button
                        Button(action: saveMeal) {
                            HStack {
                                Text(showSuccessFeedback ? "LOGGED TO DAILY LOG" : "LOG MEAL")
                                    .font(.system(size: 16, weight: .bold))
                                    .tracking(1.5)
                                if showSuccessFeedback {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showSuccessFeedback ? FriendlyTheme.midnightMatteLight : FriendlyTheme.apexGreen)
                            .foregroundColor(showSuccessFeedback ? FriendlyTheme.apexGreen : .black)
                            .cornerRadius(30)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - SwiftData Persistence
    private func saveMeal() {
        let todayLog = getOrCreateTodayLog()
        
        let newMeal = MealEntry(
            name: mockResultName,
            tier: mockTier,
            fat: fatGrams,
            protein: proteinGrams,
            carbs: carbsGrams,
            hasSeedOils: hasSeedOils,
            hasSugars: hasRefinedSugars
        )
        
        newMeal.dailyLog = todayLog
        todayLog.meals.append(newMeal)
        modelContext.insert(newMeal)
        
        // Update Daily Summary
        todayLog.totalFatGrams += fatGrams
        todayLog.totalProteinGrams += proteinGrams
        todayLog.totalCarbsGrams += carbsGrams
        
        do {
            try modelContext.save()
            triggerSuccessFeedback()
        } catch {
            print("Failed to save meal: \(error.localizedDescription)")
        }
    }
    
    private func triggerSuccessFeedback() {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        withAnimation { showSuccessFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccessFeedback = false }
        }
    }
}

struct FoodResultCard: View {
    var name: String
    var weight: String
    var tier: String
    var fatGrams: Double
    var fatPercent: Double
    var proteinGrams: Double
    var proteinPercent: Double
    var carbsGrams: Double
    var carbsPercent: Double
    var hasSeedOils: Bool
    var hasRefinedSugars: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Info & Badge
            HStack(alignment: .top) {
                // Mock Image Placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(FriendlyTheme.textSecondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(weight)
                        .font(.system(size: 14))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Tier Badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text(tier)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(tier == "Apex" ? FriendlyTheme.limeSignal : (tier == "Ancestral" ? .white : FriendlyTheme.apexGreen))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(FriendlyTheme.midnightMatte)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(tier == "Apex" ? FriendlyTheme.limeSignal : (tier == "Ancestral" ? .white : FriendlyTheme.apexGreen), lineWidth: 1)
                )
            }
            
            // Macros
            HStack(spacing: 20) {
                MacroStatView(label: "FAT", value: "\(Int(fatGrams))g", color: FriendlyTheme.mutedAmber, percent: fatPercent)
                MacroStatView(label: "PROTEIN", value: "\(Int(proteinGrams))g", color: FriendlyTheme.apexGreen, percent: proteinPercent)
                MacroStatView(label: "CARBS", value: "\(Int(carbsGrams))g", color: .blue, percent: carbsPercent)
            }
            
            // Alerts
            if hasSeedOils {
                FriendlyAlertView(message: "Not the friendliest choice for your gut! Try tallow or butter instead?")
            }
            if hasRefinedSugars {
                FriendlyAlertView(message: "Contains refined sugars (like Dextrose/Maltodextrin). An Ancestral sweetener like raw honey might be better!")
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
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(FriendlyTheme.midnightMatte)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percent), height: 4)
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
        .cornerRadius(16)
    }
}

#Preview {
    KitchenSearchView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
