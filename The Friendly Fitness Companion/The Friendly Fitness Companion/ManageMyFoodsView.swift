import SwiftUI
import SwiftData

struct ManageMyFoodsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var customFoods: [CustomFood]
    @Query private var dailyLogs: [DailyLog]
    
    @StateObject private var apiManager = NutritionAPIManager.shared
    @State private var searchText = ""
    @State private var selectedCategory = "RECENT"
    
    let categories = ["FAVS", "RECENT", "FREQUENT", "CUSTOM", "MEALS", "RECIPES", "PHOTOFOODS"]
    
    // MARK: - Intelligence Engines (Prompt 91)
    
    var recentFoods: [FoodEntry] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date.distantPast
        var uniqueFoods: [String: FoodEntry] = [:]
        
        for log in dailyLogs where log.date >= sevenDaysAgo {
            for food in log.foodEntries {
                if uniqueFoods[food.name] == nil || uniqueFoods[food.name]!.timestamp < food.timestamp {
                    uniqueFoods[food.name] = food
                }
            }
        }
        return Array(uniqueFoods.values).sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    var frequentFoods: [(FoodEntry, Int)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        var counts: [String: Int] = [:]
        var latestEntry: [String: FoodEntry] = [:]
        
        for log in dailyLogs where log.date >= thirtyDaysAgo {
            for food in log.foodEntries {
                counts[food.name, default: 0] += 1
                if latestEntry[food.name] == nil || latestEntry[food.name]!.timestamp < food.timestamp {
                    latestEntry[food.name] = food
                }
            }
        }
        
        let sorted = counts.sorted { $0.value > $1.value }.prefix(20)
        return sorted.compactMap { dict in
            if let entry = latestEntry[dict.key] {
                return (entry, dict.value)
            }
            return nil
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Search Bar
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(FriendlyTheme.textSecondary)
                        TextField("Search local foods or global database...", text: $searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { newValue in
                                if !newValue.isEmpty && newValue.count > 2 {
                                    apiManager.searchFoods(query: newValue)
                                }
                            }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Horizontal Category Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    withAnimation {
                                        selectedCategory = category
                                        searchText = "" // Reset search when switching tabs
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Text(category)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .tracking(1.5)
                                            .foregroundColor(selectedCategory == category ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary)
                                        
                                        Rectangle()
                                            .fill(selectedCategory == category ? FriendlyTheme.apexGreen : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 8)
                .background(FriendlyTheme.midnightMatte.opacity(0.95))
                .zIndex(1)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Content Area
                ScrollView {
                    VStack(spacing: 12) {
                        if !searchText.isEmpty {
                            // API Search Results Layout
                            if apiManager.isSearching {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: FriendlyTheme.apexGreen))
                                    .padding(.top, 40)
                            } else {
                                HStack {
                                    Text("GLOBAL API RESULTS")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .tracking(1.5)
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                
                                ForEach(apiManager.searchResults, id: \.self) { result in
                                    APIFoodResultCard(item: result, modelContext: modelContext)
                                }
                            }
                        } else {
                            // Category Specific Layout
                            switch selectedCategory {
                            case "RECENT":
                                if recentFoods.isEmpty {
                                    EmptyStateView(title: "NO RECENT FOODS", subtitle: "Log a meal to see it here.")
                                } else {
                                    ForEach(recentFoods) { food in
                                        FoodRowView(name: food.name, desc: "\(food.calories) kcal • \(food.protein)g P", icon: "clock.fill")
                                    }
                                }
                            case "FREQUENT":
                                if frequentFoods.isEmpty {
                                    EmptyStateView(title: "NOT ENOUGH DATA", subtitle: "Keep logging to build your frequent intelligence.")
                                } else {
                                    ForEach(frequentFoods, id: \.0.id) { pair in
                                        FoodRowView(name: pair.0.name, desc: "Logged \(pair.1) times recently", icon: "flame.fill")
                                    }
                                }
                            case "CUSTOM":
                                if customFoods.isEmpty {
                                    EmptyStateView(title: "NO CUSTOM FOODS", subtitle: "Create custom entries to use them anytime.")
                                } else {
                                    ForEach(customFoods) { custom in
                                        FoodRowView(name: custom.name, desc: "\(Int(custom.caloriesPer100g)) kcal / 100g", icon: "cube.box.fill")
                                    }
                                }
                            default:
                                EmptyStateView(title: "\(selectedCategory) UNDER CONSTRUCTION", subtitle: "This module will be available in future phases.")
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Food Warehouse")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "circle.hexagongrid")
                .font(.system(size: 40))
                .foregroundColor(FriendlyTheme.textSecondary.opacity(0.3))
                .padding(.bottom, 8)
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(2.0)
                .foregroundColor(FriendlyTheme.textSecondary)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary.opacity(0.7))
        }
        .padding(.top, 60)
    }
}

struct FoodRowView: View {
    let name: String
    let desc: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                Image(systemName: icon)
                    .foregroundColor(FriendlyTheme.apexGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .foregroundColor(FriendlyTheme.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }
}

struct APIFoodResultCard: View {
    let item: APIFoodItem
    let modelContext: ModelContext
    @State private var showSaveOptions = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                
                // Could implement AsyncImage here for item.imageUrl if provided
                Image(systemName: "globe")
                    .foregroundColor(FriendlyTheme.apexGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(item.brand) • \(Int(item.calories)) kcal")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                showSaveOptions = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(FriendlyTheme.apexGreen)
            }
            .confirmationDialog("Add to Vault", isPresented: $showSaveOptions, titleVisibility: .visible) {
                Button("Save as Custom Food") {
                    saveAsCustom()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }
    
    private func saveAsCustom() {
        let newCustom = CustomFood(
            name: item.name,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat
        )
        modelContext.insert(newCustom)
        HapticManager.shared.success()
    }
}
