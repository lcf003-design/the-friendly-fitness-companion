import SwiftUI
import SwiftData
import Combine
import Charts

// MARK: - Theme Definitions
struct FriendlyTheme {
    static let midnightMatte = Color(red: 18/255, green: 18/255, blue: 18/255) // Softer background
    static let midnightMatteLight = Color(red: 28/255, green: 28/255, blue: 28/255) // Card background
    static let apexGreen = Color(red: 0, green: 200/255, blue: 83/255) // More organic green
    static let limeSignal = Color(red: 100/255, green: 221/255, blue: 23/255) // Friendly accent
    static let mutedAmber = Color(red: 214/255, green: 160/255, blue: 84/255)
    static let textSecondary = Color.gray
    static let calmBlue = Color(red: 33/255, green: 150/255, blue: 243/255) // For calorie budget / friendly accents
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query private var dailyLogs: [DailyLog]
    @Query private var metabolicGoals: [MetabolicGoal]
    
    @State private var showFoodLogger = false
    @State private var showMyHealth = false
    @Query private var healthRecords: [HealthRecord]
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    init() {
        var descriptor = FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 30
        _dailyLogs = Query(descriptor)
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Modern Organic Header
                    HStack {
                        Button(action: {
                            withAnimation {
                                appState.isDrawerOpen = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        
                        Spacer()
                        
                        Text("Dashboard")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("Go Premium")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(FriendlyTheme.mutedAmber)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    // Date Navigator
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(FriendlyTheme.apexGreen)
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(FriendlyTheme.apexGreen)
                            Text("Today")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    .padding(.horizontal, 24)
                    
                    // Metabolic Hub Widget
                    MetabolicHubWidget(dailyLogs: dailyLogs, metabolicGoals: metabolicGoals, showFoodLogger: $showFoodLogger)
                        .padding(.horizontal, 20)
                    
                    // Modular List Cards
                    VStack(spacing: 12) {
                        ModularRowCard(
                            icon: "scalemass.fill",
                            iconColor: FriendlyTheme.calmBlue,
                            title: "Weigh In",
                            subtitle: "Last weigh-in: \(lastWeighInDate())",
                            value: "\(currentWeight()) \(preferredUnit)"
                        )
                        
                        ModularRowCard(
                            icon: "target",
                            iconColor: FriendlyTheme.calmBlue,
                            title: "My Weight Goal & Plan",
                            subtitle: weightGoalSubtitle(),
                            value: ""
                        )
                        
                        ModularRowCard(
                            icon: "calendar.badge.clock",
                            iconColor: FriendlyTheme.mutedAmber,
                            title: "Day Events",
                            subtitle: "",
                            value: "•••"
                        )
                        
                        // Health Section
                        VStack(spacing: 0) {
                            ModularRowCard(
                                icon: "heart.fill",
                                iconColor: .red,
                                title: "My Health",
                                subtitle: "",
                                value: "•••",
                                isTop: true,
                                isBottom: false
                            )
                            
                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                            
                            ModularRowCard(
                                icon: "testtube.2",
                                iconColor: FriendlyTheme.calmBlue,
                                title: "Blood Ketones",
                                subtitle: "No data yet",
                                value: "🔒",
                                isTop: false,
                                isBottom: false
                            )
                            
                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                            
                            ModularRowCard(
                                icon: "lungs.fill",
                                iconColor: FriendlyTheme.calmBlue,
                                title: "Breath Ketones",
                                subtitle: "No data yet",
                                value: "🔒",
                                isTop: false,
                                isBottom: true
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 100)
            }
        }
    }
    
    // Helper Methods
    private func lastWeighInDate() -> String {
        guard let latestLog = dailyLogs.first(where: { !$0.bodyMeasurements.isEmpty }),
              let _ = latestLog.bodyMeasurements.last else { return "No data" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: latestLog.date)
    }
    
    private func currentWeight() -> String {
        guard let latestLog = dailyLogs.first(where: { !$0.bodyMeasurements.isEmpty }),
              let measurement = latestLog.bodyMeasurements.last else { return "--" }
        return String(format: "%.1f", measurement.bodyWeight ?? 0.0)
    }
    
    private func weightGoalSubtitle() -> String {
        guard let goal = metabolicGoals.first else { return "Set your goal" }
        let diff = abs(goal.targetWeight - (Double(currentWeight()) ?? 0))
        let diffStr = String(format: "%.1f", diff)
        if goal.targetWeight > (Double(currentWeight()) ?? 0) {
            return "Gain \(diffStr) \(preferredUnit) to reach target"
        } else {
            return "Lose \(diffStr) \(preferredUnit) to reach target"
        }
    }
}

// MARK: - Metabolic Hub Widget
struct MetabolicHubWidget: View {
    var dailyLogs: [DailyLog]
    var metabolicGoals: [MetabolicGoal]
    @Binding var showFoodLogger: Bool
    
    var body: some View {
        VStack {
            // Main Content Area
            HStack(spacing: 0) {
                // Left Column (Exercise/Water)
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Exercise")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Text("0")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.calmBlue)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Water")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        HStack(spacing: 2) {
                            Text("0")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.calmBlue)
                            Image(systemName: "drop")
                                .font(.system(size: 14))
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                    }
                }
                .frame(width: 80)
                
                Spacer()
                
                // Central Ring
                VStack {
                    Text("Calorie Budget")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .padding(.bottom, 2)
                    
                    Text("\(metabolicGoals.first?.dailyCalorieTarget ?? 2000)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.calmBlue)
                        .padding(.bottom, 8)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 16)
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .trim(from: 0.0, to: 0.75) // Mock progress
                            .stroke(FriendlyTheme.calmBlue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text("\(metabolicGoals.first?.dailyCalorieTarget ?? 2000)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("left")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Right Column (Meals)
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Breakfast")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Text("0")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.calmBlue)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Lunch")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Text("0")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.calmBlue)
                    }
                }
                .frame(width: 80)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            
            // Footer Area
            HStack {
                Spacer()
                Button(action: { showFoodLogger = true }) {
                    Text("View All Meals")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                }
                Spacer()
            }
            .padding(.vertical, 20)
        }
        .background(FriendlyTheme.midnightMatteLight)
        .cornerRadius(24)
    }
}

// MARK: - Modular Row Card
struct ModularRowCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let value: String
    
    var isTop: Bool = true
    var isBottom: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Background
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Value
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(value == "🔒" ? FriendlyTheme.mutedAmber : FriendlyTheme.calmBlue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(FriendlyTheme.midnightMatteLight)
        // Adjust corner radii for grouped lists
        .clipShape(
            .rect(
                topLeadingRadius: isTop ? 20 : 0,
                bottomLeadingRadius: isBottom ? 20 : 0,
                bottomTrailingRadius: isBottom ? 20 : 0,
                topTrailingRadius: isTop ? 20 : 0
            )
        )
    }
}

#Preview {
    DashboardView()
}

// MARK: - Legacy Components
struct HennemanMeterView: View {
    var recruitmentLevel: Double
    var isFailure: Bool = false
    @State private var pulseState: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isFailure ? "MAX RECRUITMENT" : "MOTOR UNIT RECRUITMENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.textSecondary)
                    .tracking(2.0)
                
                Spacer()
                
                Text("\(Int(recruitmentLevel * 100))%")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.15))
                        .frame(height: 8)
                    
                    // Active track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [FriendlyTheme.limeSignal, isFailure ? .white : FriendlyTheme.apexGreen]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geometry.size.width * CGFloat(recruitmentLevel), height: 8)
                        .shadow(color: isFailure ? FriendlyTheme.limeSignal : FriendlyTheme.apexGreen.opacity(0.5), radius: isFailure ? (pulseState ? 12 : 4) : 4, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: recruitmentLevel)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseState = true
            }
        }
    }
}
