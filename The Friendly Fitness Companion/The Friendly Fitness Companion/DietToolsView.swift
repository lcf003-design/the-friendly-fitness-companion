import SwiftUI

struct DietToolsView: View {
    @Binding var showDietGoal: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            WeeklyAdherenceView()
                .padding(.top, 10)
            
            // Top Card - My Diet
            Button(action: { showDietGoal = true }) {
                ModularRowCard(
                    icon: "flame.fill",
                    iconColor: FriendlyTheme.apexGreen,
                    title: "My Diet",
                    subtitle: "Manage your metabolic strategy",
                    value: "SELECT"
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            
            // The Hunter-Gatherer Feature Banner
            NavigationLink(destination: FastingHubView()) { // or Fasting Education Flow
                ZStack {
                    // Darkened image mock
                    Color.black.opacity(0.4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The Hunter-Gatherer")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Protocol intelligence & specific nutrient density.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
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
                .cornerRadius(20)
                .padding(.horizontal, 24)
            }
            
            // Primary Tool Stack
            VStack(spacing: 0) {
                ModularRowCard(
                    icon: "bag.fill",
                    iconColor: FriendlyTheme.textSecondary,
                    title: "Premium Recipes & Meals",
                    subtitle: "",
                    value: "",
                    isTop: true,
                    isBottom: false
                )
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                
                ModularRowCard(
                    icon: "menucard.fill",
                    iconColor: FriendlyTheme.textSecondary,
                    title: "Premium Menus",
                    subtitle: "",
                    value: "",
                    isTop: false,
                    isBottom: false
                )
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                
                ModularRowCard(
                    icon: "doc.text.fill",
                    iconColor: FriendlyTheme.textSecondary,
                    title: "Meal Planner",
                    subtitle: "",
                    value: "",
                    isTop: false,
                    isBottom: false
                )
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                
                NavigationLink(destination: RestaurantScanView()) {
                    ModularRowCard(
                        icon: "camera.viewfinder",
                        iconColor: FriendlyTheme.textSecondary,
                        title: "Restaurant Menu AI Scan",
                        subtitle: "",
                        value: "",
                        isTop: false,
                        isBottom: true
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            
            // Intermittent Fasting Card
            NavigationLink(destination: FastingHubView()) {
                ModularRowCard(
                    icon: "clock.fill",
                    iconColor: .white,
                    title: "Intermittent Fasting",
                    subtitle: "",
                    value: ""
                )
            }
            .buttonStyle(.plain)
            
            // Header for Analysis & Insights
            HStack {
                Text("Analysis & Insights")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            // Diet Trends Card
            NavigationLink(destination: DocumentVaultView()) {
                ModularRowCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: FriendlyTheme.apexGreen,
                    title: "My Diet Trends",
                    subtitle: "Your weight-loss journey explained with insights from your diary.",
                    value: ""
                )
            }
            .buttonStyle(.plain)
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
