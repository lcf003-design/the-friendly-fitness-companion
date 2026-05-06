import SwiftUI

struct TechnicalFoodLabelView: View {
    let food: UnifiedFoodItem
    var onLog: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background similar to the screenshot
            Color(red: 22/255, green: 22/255, blue: 22/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    Spacer()
                    Text("Food Label")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(red: 30/255, green: 30/255, blue: 30/255))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Title Area
                        HStack(alignment: .top) {
                            if food.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .padding(.top, 4)
                            } else {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .padding(.top, 4)
                            }
                            
                            Text(food.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(3)
                            
                            Spacer()
                            
                            if let grade = food.grade, !grade.isEmpty {
                                VStack {
                                    Text("Grade")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text(grade)
                                        .font(.system(size: 22, weight: .black, design: .rounded))
                                        .foregroundColor(grade == "A" || grade == "B" ? FriendlyTheme.apexGreen : (grade == "C" ? .yellow : .red))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Serving Size
                        HStack {
                            Text("Serving size")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text(food.servingSize ?? "1 serving")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        
                        Divider().background(Color.white.opacity(0.2)).padding(.horizontal, 20)
                        
                        // Calories
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount per serving")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Calories")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(food.calories))")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        
                        Divider().background(Color.white.opacity(0.3)).padding(.horizontal, 20).frame(height: 2)
                        
                        // Nutrients Toggle
                        HStack {
                            Spacer()
                            Text("Show % Food Label Daily Value*")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FriendlyTheme.apexGreen)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        
                        // Macros
                        VStack(spacing: 0) {
                            FoodLabelNutrientRow(title: "Total Fat", amount: food.fat, isBold: true, dv: 65)
                            FoodLabelNutrientRow(title: "Total Carbs", amount: food.carbs, isBold: true, dv: 300)
                            FoodLabelNutrientRow(title: "Protein", amount: food.protein, isBold: true, dv: 50)
                            FoodLabelNutrientRow(title: "Sodium", amount: food.sodium, unit: "mg", isBold: true, dv: 2400)
                        }
                        
                        // Footnote
                        VStack(alignment: .leading, spacing: 4) {
                            Text("* Percent Daily Values are based on a 2,000 calorie diet.")
                                .foregroundColor(.gray)
                            Text("Explain Percentages.")
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        .font(.system(size: 12))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Extra Actions
                        VStack(spacing: 0) {
                            FoodLabelActionRow(icon: "barcode.viewfinder", title: "Barcode", detail: "Scanned", iconColor: FriendlyTheme.calmBlue)
                            FoodLabelActionRow(icon: "clock.arrow.circlepath", title: "Consumption History", isGreen: true)
                            FoodLabelActionRow(icon: "questionmark.circle", title: "Help & Tips", isGreen: true)
                        }
                        .padding(.vertical, 8)
                        
                                                
                        if let onLog = onLog {
                            Button(action: {
                                onLog()
                                dismiss()
                            }) {
                                Text("LOG FOOD")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(FriendlyTheme.apexGreen)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
}

struct FoodLabelNutrientRow: View {
    let title: String
    let amount: Double
    var unit: String = "g"
    let isBold: Bool
    var isIndented: Bool = false
    let dv: Double // Daily Value for 100%
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: isBold ? .bold : .regular))
                    .foregroundColor(.white)
                Text("\(String(format: "%.1f", amount))\(unit)")
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.8))
                
                Spacer()
                
                if dv > 0 {
                    let percent = Int((amount / dv) * 100)
                    Text("\(percent)%")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.leading, isIndented ? 16 : 0)
            
            Divider().background(Color.white.opacity(0.1))
        }
    }
}

struct FoodLabelActionRow: View {
    let icon: String
    let title: String
    var detail: String? = nil
    var isGreen: Bool = false
    var iconColor: Color? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor ?? (isGreen ? FriendlyTheme.apexGreen : .gray))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isGreen ? FriendlyTheme.apexGreen : .gray)
            
            Spacer()
            
            if let detail = detail {
                Text(detail)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
