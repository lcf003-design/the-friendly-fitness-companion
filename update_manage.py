import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/ManageMyFoodsView.swift"
with open(path, "r") as f:
    content = f.read()

# Replace APIFoodResultCard
old_api_card = """struct APIFoodResultCard: View {
    let item: APIFoodItem
    let modelContext: ModelContext
    @State private var showSaveOptions = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                    .cornerRadius(16)
                
                // Could implement AsyncImage here for item.imageUrl if provided
                Image(systemName: "globe")
                    .foregroundColor(FriendlyTheme.apexGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\\(item.brand) • \\(Int(item.calories)) kcal")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                
                DensityMeterView(peRatio: item.protein / max(item.fat + item.carbs, 1.0))
                    .padding(.top, 2)
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
                    let custom = CustomFood(name: item.name, brand: item.brand, caloriesPer100g: item.calories, proteinPer100g: item.protein, fatPer100g: item.fat, carbsPer100g: item.carbs)
                    modelContext.insert(custom)
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(FriendlyTheme.midnightMatteLight)
    }
}"""

new_api_card = """struct APIFoodResultCard: View {
    let item: APIFoodItem
    let modelContext: ModelContext
    
    var body: some View {
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
                    
                    Text("\\(item.brand) • \\(item.servingSize ?? "1 serving")")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\\(Int(item.calories))")
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
}"""

content = content.replace(old_api_card, new_api_card)

# Replace FoodRowView
old_row = """struct FoodRowView: View {
    let name: String
    let desc: String
    let icon: String
    var peRatio: Double? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)
                        .cornerRadius(16)
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
                    if let peRatio = peRatio {
                        DensityMeterView(peRatio: peRatio)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(FriendlyTheme.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(FriendlyTheme.midnightMatteLight)
        }
        .buttonStyle(PlainButtonStyle())
    }
}"""

new_row = """struct FoodRowView: View {
    let name: String
    let desc: String
    let icon: String
    var peRatio: Double? = nil
    let action: () -> Void
    
    // Extract calories from desc naive approach
    var displayCals: String {
        if let calString = desc.components(separatedBy: " kcal").first, let _ = Int(calString) {
            return calString
        }
        return "-"
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(displayCals)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        if displayCals != "-" {
                            Text("cal")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 70)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}"""

content = content.replace(old_row, new_row)

# Update Search bar appearance
old_search = """                        TextField("Search local foods or global database...", text: $searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { _, newValue in
                                if !newValue.isEmpty && newValue.count > 2 {
                                    apiManager.searchFoods(query: newValue)
                                }
                            }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)"""

new_search = """                        TextField("Search local foods or global database...", text: $searchText)
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
                    .padding(.top, 16)"""

content = content.replace(old_search, new_search)

# Remove the thick dark background behind the tabs
content = content.replace(".background(FriendlyTheme.midnightMatte.opacity(0.95))\n                .zIndex(1)", "")

with open(path, "w") as f:
    f.write(content)
