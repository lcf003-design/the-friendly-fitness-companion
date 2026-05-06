import SwiftUI
import SwiftData

// MARK: - Custom Foods View
struct CustomFoodsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var foods: [CustomFood]
    
    @State private var showAddFood = false
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            if foods.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(FriendlyTheme.textSecondary.opacity(0.3))
                    Text("NO CUSTOM FOODS")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                }
            } else {
                List {
                    ForEach(foods) { food in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("\(Int(food.caloriesPer100g)) kcal | P: \(Int(food.proteinPer100g))g | C: \(Int(food.carbsPer100g))g | F: \(Int(food.fatPer100g))g (per 100g)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .onDelete(perform: deleteFood)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("MY FOODS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddFood = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddCustomFoodView()
        }
    }
    
    private func deleteFood(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(foods[index])
        }
        try? modelContext.save()
    }
}

struct AddCustomFoodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                Form {
                    Section(header: Text("MACROS PER 100g").foregroundColor(FriendlyTheme.textSecondary)) {
                        TextField("Food Name", text: $name)
                            .foregroundColor(.white)
                        TextField("Calories (kcal)", text: $calories).keyboardType(.decimalPad).foregroundColor(.white)
                        TextField("Protein (g)", text: $protein).keyboardType(.decimalPad).foregroundColor(.white)
                        TextField("Carbs (g)", text: $carbs).keyboardType(.decimalPad).foregroundColor(.white)
                        TextField("Fat (g)", text: $fat).keyboardType(.decimalPad).foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(FriendlyTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newFood = CustomFood(
                            name: name,
                            calories: Double(calories) ?? 0,
                            protein: Double(protein) ?? 0,
                            carbs: Double(carbs) ?? 0,
                            fat: Double(fat) ?? 0
                        )
                        modelContext.insert(newFood)
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Recipes View
struct CustomRecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [CustomRecipe]
    
    @State private var showAddRecipe = false
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            if recipes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 60))
                        .foregroundColor(FriendlyTheme.textSecondary.opacity(0.3))
                    Text("RECIPE VAULT EMPTY")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                }
            } else {
                List {
                    ForEach(recipes) { recipe in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.name.uppercased())
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if !recipe.ingredients.isEmpty {
                                Text("Ingredients: \(recipe.ingredients.joined(separator: ", "))")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            
                            Text(recipe.instructions)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(3)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .onDelete(perform: deleteRecipe)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("RECIPE VAULT")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddRecipe = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
            }
        }
        .sheet(isPresented: $showAddRecipe) {
            AddCustomRecipeView()
        }
    }
    
    private func deleteRecipe(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recipes[index])
        }
        try? modelContext.save()
    }
}

struct AddCustomRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var instructions = ""
    @State private var ingredientInput = ""
    @State private var ingredients: [String] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                Form {
                    Section(header: Text("RECIPE DETAILS").foregroundColor(FriendlyTheme.textSecondary)) {
                        TextField("Protocol Name (e.g. Pre-Forge Fueling)", text: $name)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $instructions)
                            .frame(height: 100)
                            .foregroundColor(.white)
                            .overlay(
                                VStack {
                                    HStack {
                                        if instructions.isEmpty {
                                            Text("Instructions...")
                                                .foregroundColor(Color.white.opacity(0.3))
                                                .padding(.top, 8)
                                                .padding(.leading, 5)
                                        }
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            )
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    Section(header: Text("INGREDIENTS").foregroundColor(FriendlyTheme.textSecondary)) {
                        HStack {
                            TextField("Add ingredient", text: $ingredientInput)
                                .foregroundColor(.white)
                            Button(action: {
                                let trimmed = ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    ingredients.append(trimmed)
                                    ingredientInput = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                            }
                        }
                        
                        ForEach(ingredients, id: \.self) { item in
                            Text(item).foregroundColor(.white)
                        }
                        .onDelete { indexSet in
                            ingredients.remove(atOffsets: indexSet)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(FriendlyTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newRecipe = CustomRecipe(name: name, instructions: instructions, ingredients: ingredients)
                        modelContext.insert(newRecipe)
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Grocery Check View
struct GroceryCheckView: View {
    @State private var item1Name = "Label A"
    @State private var item1Protein = ""
    @State private var item1Serving = "100"
    
    @State private var item2Name = "Label B"
    @State private var item2Protein = ""
    @State private var item2Serving = "100"
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("MACRO COMPARISON")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    HStack(spacing: 16) {
                        // Column 1
                        VStack(spacing: 16) {
                            TextField("Name", text: $item1Name)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Serving (g)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("100", text: $item1Serving)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                
                                Text("Protein (g)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("e.g. 20", text: $item1Protein)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            
                            let ratio1 = calculateRatio(protein: item1Protein, serving: item1Serving)
                            Text(ratio1 > 0 ? String(format: "%.1f%% Protein", ratio1 * 100) : "--")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .padding(.top, 8)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        // Column 2
                        VStack(spacing: 16) {
                            TextField("Name", text: $item2Name)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Serving (g)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("100", text: $item2Serving)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                
                                Text("Protein (g)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("e.g. 20", text: $item2Protein)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            
                            let ratio2 = calculateRatio(protein: item2Protein, serving: item2Serving)
                            Text(ratio2 > 0 ? String(format: "%.1f%% Protein", ratio2 * 100) : "--")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .padding(.top, 8)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("GROCERY CHECK")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func calculateRatio(protein: String, serving: String) -> Double {
        guard let p = Double(protein), let s = Double(serving), s > 0 else { return 0 }
        return p / s
    }
}

// MARK: - Body Measurements View
struct BodyMeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.timestamp, order: .reverse) private var measurements: [BodyMeasurement]
    
    @State private var showAddMeasurement = false
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            if measurements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 60))
                        .foregroundColor(FriendlyTheme.textSecondary.opacity(0.3))
                    Text("NO MEASUREMENTS LOGGED")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                }
            } else {
                List {
                    ForEach(measurements) { measurement in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(formatDate(measurement.timestamp))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.apexGreen)
                            
                            HStack {
                                if let neck = measurement.neckInches { Text("Neck: \(String(format: "%.1f", neck))\"") }
                                if let chest = measurement.chestInches { Text("Chest: \(String(format: "%.1f", chest))\"") }
                            }
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            
                            HStack {
                                if let waist = measurement.waistInches { Text("Waist: \(String(format: "%.1f", waist))\"") }
                                if let thighs = measurement.thighsInches { Text("Thighs: \(String(format: "%.1f", thighs))\"") }
                            }
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .onDelete(perform: deleteMeasurement)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("BODY STATS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddMeasurement = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
            }
        }
        .sheet(isPresented: $showAddMeasurement) {
            AddMeasurementView()
        }
    }
    
    private func deleteMeasurement(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(measurements[index])
        }
        try? modelContext.save()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AddMeasurementView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var neck = ""
    @State private var chest = ""
    @State private var waist = ""
    @State private var thighs = ""
    
    @Query private var dailyLogs: [DailyLog]
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                Form {
                    Section(header: Text("MEASUREMENTS (INCHES)").foregroundColor(FriendlyTheme.textSecondary)) {
                        TextField("Neck", text: $neck).keyboardType(.decimalPad).foregroundColor(.white)
                        TextField("Chest", text: $chest).keyboardType(.decimalPad).foregroundColor(.white)
                        TextField("Waist", text: $waist).keyboardType(.decimalPad).foregroundColor(.white)
                        TextField("Thighs", text: $thighs).keyboardType(.decimalPad).foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(FriendlyTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newMeasurement = BodyMeasurement(
                            neckInches: Double(neck),
                            waistInches: Double(waist),
                            chestInches: Double(chest),
                            thighsInches: Double(thighs)
                        )
                        
                        // Link to today's DailyLog
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let todayId = formatter.string(from: Date())
                        
                        let log = dailyLogs.first(where: { $0.id == todayId }) ?? {
                            let newLog = DailyLog(date: Date())
                            modelContext.insert(newLog)
                            return newLog
                        }()
                        
                        newMeasurement.dailyLog = log
                        modelContext.insert(newMeasurement)
                        
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
