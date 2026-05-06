import SwiftUI
import SwiftData

struct FoodComparisonEngine: View {
    let foodA: UnifiedFoodItem
    @State private var foodB: UnifiedFoodItem? = nil
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var customFoods: [CustomFood]
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("COMPARE ENGINE")
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
                
                if let foodB = foodB {
                    // Comparison View
                    ScrollView {
                        VStack(spacing: 30) {
                            HStack {
                                VStack {
                                    Text(foodA.name)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Text("VS")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                
                                VStack {
                                    Text(foodB.name)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                            
                            ComparisonBarChart(title: "Protein (g)", valA: foodA.protein, valB: foodB.protein, higherIsBetter: true, isFloat: false)
                            ComparisonBarChart(title: "Total Fat (g)", valA: foodA.fat, valB: foodB.fat, higherIsBetter: true, isFloat: false)
                            ComparisonBarChart(title: "Sodium (mg)", valA: foodA.sodium, valB: foodB.sodium, higherIsBetter: false, isFloat: false)
                            
                            let peA = foodA.protein / max(foodA.fat + foodA.carbs, 1.0)
                            let peB = foodB.protein / max(foodB.fat + foodB.carbs, 1.0)
                            ComparisonBarChart(title: "P:E Ratio", valA: peA, valB: peB, higherIsBetter: true, isFloat: true)
                            
                            Button(action: {
                                self.foodB = nil
                            }) {
                                Text("COMPARE DIFFERENT FOOD")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                            .padding(24)
                        }
                    }
                } else {
                    // Selection View for Food B
                    VStack {
                        TextField("Search local foods to compare...", text: $searchText)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .padding(24)
                        
                        List {
                            ForEach(customFoods.filter { searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased()) }) { custom in
                                Button(action: {
                                    self.foodB = UnifiedFoodItem(
                                        name: custom.name,
                                        brand: "Custom",
                                        calories: custom.caloriesPer100g,
                                        protein: custom.proteinPer100g,
                                        fat: custom.fatPer100g,
                                        carbs: custom.carbsPer100g,
                                        sodium: 0 // Defaulting missing data
                                    )
                                }) {
                                    HStack {
                                        Text(custom.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
        }
    }
}

struct ComparisonBarChart: View {
    let title: String
    let valA: Double
    let valB: Double
    var higherIsBetter: Bool = true
    var isFloat: Bool = false
    
    var maxVal: Double {
        max(valA, valB, 1.0)
    }
    
    var isWinnerA: Bool {
        higherIsBetter ? valA >= valB && valA > 0 : valA <= valB
    }
    
    var isWinnerB: Bool {
        higherIsBetter ? valB >= valA && valB > 0 : valB <= valA
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundColor(FriendlyTheme.textSecondary)
            
            HStack(alignment: .bottom, spacing: 40) {
                // Bar A
                VStack {
                    Text(isFloat ? String(format: "%.1f", valA) : "\(Int(valA))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isWinnerA ? FriendlyTheme.apexGreen : .white)
                    Rectangle()
                        .fill(isWinnerA ? FriendlyTheme.apexGreen : Color.white.opacity(0.3))
                        .frame(width: 40, height: max(10, CGFloat((valA / maxVal) * 100)))
                        .cornerRadius(4)
                        .shadow(color: isWinnerA ? FriendlyTheme.apexGreen.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
                }
                
                // Bar B
                VStack {
                    Text(isFloat ? String(format: "%.1f", valB) : "\(Int(valB))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isWinnerB ? FriendlyTheme.apexGreen : .white)
                    Rectangle()
                        .fill(isWinnerB ? FriendlyTheme.apexGreen : Color.white.opacity(0.3))
                        .frame(width: 40, height: max(10, CGFloat((valB / maxVal) * 100)))
                        .cornerRadius(4)
                        .shadow(color: isWinnerB ? FriendlyTheme.apexGreen.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
                }
            }
        }
    }
}
