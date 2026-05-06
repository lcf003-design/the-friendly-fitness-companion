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
}

struct FoodActionSheetView: View {
    let food: UnifiedFoodItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var showLabel = false
    @State private var showHistory = false
    @State private var showCompare = false
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(food.brand) • \(Int(food.calories)) kcal")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                }
                .padding(24)
                
                Divider().background(Color.white.opacity(0.1))
                
                ScrollView {
                    VStack(spacing: 0) {
                        ActionRow(icon: "text.justify.left", title: "Food Label") {
                            showLabel = true
                        }
                        ActionRow(icon: "square.split.2x1", title: "Compare with Another Food") {
                            showCompare = true
                        }
                        ActionRow(icon: "square.and.pencil", title: "Update Food") {
                            // Placeholder
                        }
                        ActionRow(icon: "doc.on.doc", title: "Copy & Update Nutrients") {
                            // Placeholder
                        }
                        ActionRow(icon: "doc.badge.plus", title: "Copy & Remove or Add Ingredients") {
                            // Placeholder
                        }
                        ActionRow(icon: "star.slash", title: "Remove from Favorites") {
                            // Placeholder
                        }
                        ActionRow(icon: "clock.arrow.circlepath", title: "Consumption History") {
                            showHistory = true
                        }
                        ActionRow(icon: "arrow.triangle.2.circlepath", title: "Replace Logged Food") {
                            // Placeholder
                        }
                        ActionRow(icon: "magnifyingglass.badge.minus", title: "Remove from Search History") {
                            // Placeholder
                        }
                    }
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

struct ActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
        }
        Divider().background(Color.white.opacity(0.1)).padding(.leading, 64)
    }
}
