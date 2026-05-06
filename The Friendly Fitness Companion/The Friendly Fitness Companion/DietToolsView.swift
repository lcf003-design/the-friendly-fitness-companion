import SwiftUI

struct DietToolsView: View {
    @Binding var showDietGoal: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            WeeklyAdherenceView()
                .padding(.top, 10)
            
            // Top Card - My Diet
            Button(action: { showDietGoal = true }) {
                HStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(FriendlyTheme.apexGreen)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MY DIET")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(.white)
                        Text("Manage your metabolic strategy")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    Spacer()
                    
                    Text("SELECT")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(FriendlyTheme.apexGreen)
                        .foregroundColor(.black)
                        .cornerRadius(6)
                }
                .padding(20)
                .background(Color.white.opacity(0.02))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .padding(.horizontal, 24)
            
            // The Hunter-Gatherer Feature Banner
            NavigationLink(destination: FastingHubView()) { // or Fasting Education Flow
                ZStack {
                    // Darkened image mock
                    Color.black.opacity(0.4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THE HUNTER-GATHERER")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(.white)
                        Text("Protocol intelligence & specific nutrient density.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Text("LEARN MORE >")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .padding(.top, 8)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
                .background(Color.black) // placeholder for image
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)
            }
            
            // Primary Tool Stack
            VStack(spacing: 0) {
                ToolStackRow(icon: "bag.fill", title: "Premium Recipes & Meals")
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 56)
                ToolStackRow(icon: "menucard.fill", title: "Premium Menus")
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 56)
                ToolStackRow(icon: "doc.text.fill", title: "Meal Planner")
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 56)
                NavigationLink(destination: RestaurantScanView()) {
                    ToolStackRow(icon: "camera.viewfinder", title: "Restaurant Menu AI Scan")
                }
            }
            .background(Color.white.opacity(0.02))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 24)
            
            // Intermittent Fasting Card
            NavigationLink(destination: FastingHubView()) {
                HStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("INTERMITTENT FASTING")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                .padding(20)
                .background(Color.white.opacity(0.02))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)
            }
            
            // Header for Analysis & Insights
            HStack {
                Text("ANALYSIS & INSIGHTS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            // Diet Trends Card
            NavigationLink(destination: DocumentVaultView()) {
                HStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 24))
                        .foregroundColor(FriendlyTheme.apexGreen)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Diet Trends")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Your weight-loss journey explained with insights from your diary.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                .padding(20)
                .background(Color.white.opacity(0.02))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)
            }
        }
    }
}

struct ToolStackRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(FriendlyTheme.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(FriendlyTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
