import SwiftUI

struct TechnicalFoodLabelView: View {
    let food: UnifiedFoodItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("NUTRITION FACTS")
                        .font(.system(size: 24, weight: .black, design: .rounded))
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
                
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(food.name)
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text(food.brand)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            Spacer()
                            if food.isVerified {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("VERIFIED")
                                }
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(FriendlyTheme.apexGreen.opacity(0.2))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        Divider().background(Color.white).padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            NutrientRow(title: "Calories", value: "\(Int(food.calories))", isHighlight: false, isIndented: false)
                            Divider().background(Color.white.opacity(0.3))
                            
                            NutrientRow(title: "Total Fat", value: "\(Int(food.fat))g", isHighlight: true, isIndented: false)
                            Divider().background(Color.white.opacity(0.3))
                            
                            NutrientRow(title: "Sodium", value: "\(Int(food.sodium))mg", isHighlight: false, isIndented: false)
                            Divider().background(Color.white.opacity(0.3))
                            
                            NutrientRow(title: "Total Carbohydrate", value: "\(Int(food.carbs))g", isHighlight: false, isIndented: false)
                            Divider().background(Color.white.opacity(0.3))
                            
                            NutrientRow(title: "Protein", value: "\(Int(food.protein))g", isHighlight: true, isIndented: false)
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.02))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

struct NutrientRow: View {
    let title: String
    let value: String
    let isHighlight: Bool
    let isIndented: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: isHighlight ? .black : .bold, design: .rounded))
                .foregroundColor(isHighlight ? FriendlyTheme.apexGreen : .white)
                .padding(.leading, isIndented ? 16 : 0)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(isHighlight ? FriendlyTheme.apexGreen : .white)
        }
        .padding(.vertical, 12)
    }
}
