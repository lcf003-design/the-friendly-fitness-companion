import SwiftUI

struct UnifiedFoodItem: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let sodium: Double
    var isVerified: Bool = false
    var servingSize: String? = "1 serving (100g)"
    var grade: String? = nil
    var imageUrl: String? = nil
}

struct FoodActionSheetView: View {
    let food: UnifiedFoodItem
    var onLog: ((Double) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity: String = "1"
    @State private var selectedUnit: String = "serving"
    @State private var showLabel = false
    @State private var showHistory = false
    @State private var showCompare = false
    
    let units = ["serving", "g", "oz", "piece"]
    
    var body: some View {
        ZStack {
            Color(red: 18/255, green: 18/255, blue: 18/255).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // 1. Image Header Section
                    ZStack(alignment: .bottom) {
                        // Background Image
                        if let urlString = food.imageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(height: 240)
                            .clipped()
                        } else {
                            // Fallback gradient/image
                            LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                                .frame(height: 240)
                        }
                        
                        // Dark gradient overlay for text readability
                        LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.9)]), startPoint: .center, endPoint: .bottom)
                            .frame(height: 240)
                        
                        // Top Navigation (Back & Star)
                        VStack {
                            HStack {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Button(action: {}) {
                                    Image(systemName: "star")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            Spacer()
                        }
                        .frame(height: 240)
                        
                        // Bottom Title & Grade
                        HStack(alignment: .bottom) {
                            Text(food.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            if let grade = food.grade, !grade.isEmpty {
                                Text(grade)
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(FriendlyTheme.apexGreen)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .frame(height: 240)
                    
                    // 2. Logging Controls Section
                    VStack(spacing: 24) {
                        
                        // Amount & Calories Row
                        HStack(alignment: .bottom) {
                            // Amount Input
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .bottom, spacing: 8) {
                                    TextField("1", text: $quantity)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 80)
                                        .overlay(Rectangle().frame(height: 1).foregroundColor(.gray), alignment: .bottom)
                                    
                                    Text(selectedUnit)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.bottom, 4)
                                }
                                Text("Weight: \(food.servingSize ?? "100g")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Calories Display
                            let qty = Double(quantity) ?? 1.0
                            let multiplier = selectedUnit == "serving" ? qty : (selectedUnit == "g" ? qty / 100.0 : qty) // Naive multiplier for UI
                            let displayCals = Int(food.calories * multiplier)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(displayCals)")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(FriendlyTheme.calmBlue)
                                Text("cals")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Unit Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(units, id: \.self) { unit in
                                Button(action: { selectedUnit = unit }) {
                                    Text(unit)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(selectedUnit == unit ? FriendlyTheme.calmBlue : FriendlyTheme.apexGreen)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 45/255, green: 45/255, blue: 45/255))
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Portion Guide Button
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "scalemass")
                                    Text("Portion Guide")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.3))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Save Row
                        HStack {
                            Text("Dinner")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(FriendlyTheme.calmBlue)
                            
                            Spacer()
                            
                            Button(action: {
                                let finalMultiplier = selectedUnit == "serving" ? (Double(quantity) ?? 1.0) : 1.0
                                onLog?(finalMultiplier)
                                dismiss()
                            }) {
                                Text("Save")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(FriendlyTheme.apexGreen)
                                    .cornerRadius(24)
                            }
                        }
                        
                    }
                    .padding(20)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // 3. Actions List
                    VStack(spacing: 0) {
                        DetailActionRow(icon: "clock.arrow.circlepath", title: "Add Auto Logging Schedule")
                        DetailActionRow(icon: "square.and.pencil", title: "Copy & Customize Food")
                        
                        Button(action: { showLabel = true }) {
                            DetailActionRow(icon: "doc.text", title: "Food Label")
                        }
                        
                        Button(action: { showCompare = true }) {
                            DetailActionRow(icon: "square.split.2x1", title: "Compare with Another Food")
                        }
                        
                        DetailActionRow(icon: "gearshape", title: "Settings")
                        DetailActionRow(icon: "questionmark.circle", title: "Help & Tips")
                        DetailActionRow(icon: "play.circle", title: "View How-to Videos")
                        
                        DetailActionRow(icon: "lightbulb", title: "Plan and track vitamins and minerals important to you, to make sure you are meeting your targets", isMultiline: true)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showLabel) {
            TechnicalFoodLabelView(food: food)
        }
        .sheet(isPresented: $showHistory) {
            FoodConsumptionHistoryView(food: food)
        }
        .sheet(isPresented: $showCompare) {
            FoodComparisonEngine(foodA: food)
        }
    }
}

struct DetailActionRow: View {
    let icon: String
    let title: String
    var isMultiline: Bool = false
    
    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(FriendlyTheme.apexGreen)
                .frame(width: 24)
                .padding(.top, isMultiline ? 4 : 0)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FriendlyTheme.apexGreen)
                .lineLimit(isMultiline ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
