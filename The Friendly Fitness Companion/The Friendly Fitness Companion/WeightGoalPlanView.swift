import SwiftUI
import SwiftData
import Charts

// MARK: - Core Multi-Tab Container
struct WeightGoalPlanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var selectedTab = "Overview"
    let tabs = ["Overview", "Weight & Cals", "Macros", "Nutrients", "Exercise Plan"]
    
    // Global Plan State (Simplified for UI representation)
    @State private var action: String = "Maintain"
    @State private var targetWeight: Double = 180.0
    @State private var targetDays: Int = 30
    @State private var dailyCalories: Int = 2800
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Persistent Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("METABOLIC STRATEGY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Text("I plan to \(action) \(String(format: "%.0f", targetWeight)) lbs in \(targetDays) Days by eating \(dailyCalories) kcal.")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    
                    // Segmented Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(tabs, id: \.self) { tab in
                                Button(action: {
                                    withAnimation { selectedTab = tab }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(tab.uppercased())
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedTab == tab ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary)
                                        
                                        Rectangle()
                                            .fill(selectedTab == tab ? FriendlyTheme.apexGreen : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .background(FriendlyTheme.midnightMatte)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        OverviewTab()
                            .tag("Overview")
                        
                        WeightAndCaloriesTab(action: $action, targetWeight: $targetWeight, targetDays: $targetDays, dailyCalories: $dailyCalories)
                            .tag("Weight & Cals")
                        
                        MacrosTab()
                            .tag("Macros")
                        
                        NutrientsTab()
                            .tag("Nutrients")
                        
                        ExercisePlanTab()
                            .tag("Exercise Plan")
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .font(.system(size: 16, weight: .bold))
                }
                ToolbarItem(placement: .principal) {
                    Text("GOAL & PLAN")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 1. Overview Tab
struct OverviewTab: View {
    @EnvironmentObject var appState: AppState
    @State private var autopilotEnabled = true
    @State private var isPulsing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Autopilot Toggle
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ADVANCED AUTOPILOT")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(.white)
                            Text("Dynamically adjusts calories based on Forge intensity")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: $autopilotEnabled)
                            .tint(FriendlyTheme.apexGreen)
                            .overlay(
                                Circle()
                                    .stroke(FriendlyTheme.apexGreen, lineWidth: autopilotEnabled && isPulsing ? 4 : 0)
                                    .scaleEffect(autopilotEnabled && isPulsing ? 1.5 : 1)
                                    .opacity(autopilotEnabled && isPulsing ? 0 : 1)
                                    .animation(autopilotEnabled ? .easeOut(duration: 1.5).repeatForever(autoreverses: false) : .default, value: isPulsing)
                            )
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Weight Card
                OverviewCard(title: "WEIGHT PLAN", value: "Maintain at 180 lbs", icon: "scalemass.fill")
                
                // Calories Card
                OverviewCard(title: "CALORIC BUDGET", value: "2,800 kcal / day", icon: "flame.fill")
                
                // Average Macros Card
                OverviewCard(title: "MACROS (CARNIVORE)", value: "80% Fat / 20% Pro / 0% Carb", icon: "chart.pie.fill")
                
                // Exercise Plan Deep Link
                Button(action: {
                    appState.selectedTab = 10 // Navigate to Forge
                }) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EXERCISE PLAN")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(.white)
                            Text("View Routine in The Forge")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 20))
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(FriendlyTheme.apexGreen)
                .font(.system(size: 20))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
}

// MARK: - 2. Weight & Calories Tab
struct WeightAndCaloriesTab: View {
    @Binding var action: String
    @Binding var targetWeight: Double
    @Binding var targetDays: Int
    @Binding var dailyCalories: Int
    
    @State private var currentWeight: Double = 180.0
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    
    private var weeklyRate: String {
        let diff = targetWeight - currentWeight
        let weeks = max(Double(targetDays) / 7.0, 1.0)
        let rate = abs(diff / weeks)
        
        if diff > 0 {
            return String(format: "Gain %.1f lbs / week", rate)
        } else if diff < 0 {
            return String(format: "Lose %.1f lbs / week", rate)
        } else {
            return "Maintain Weight"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weight Planning Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("WEIGHT PLANNING")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Weight (lbs)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            TextField("180.0", value: $currentWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Target Weight (lbs)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            TextField("180.0", value: $targetWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Date")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        DatePicker("", selection: $targetDate, displayedComponents: .date)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .accentColor(FriendlyTheme.apexGreen)
                            .onChange(of: targetDate) { _ in
                                let diff = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 1
                                targetDays = max(diff, 1)
                                action = targetWeight > currentWeight ? "Gain" : (targetWeight < currentWeight ? "Lose" : "Maintain")
                            }
                    }
                    
                    HStack {
                        Text("Current Weekly Rate:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        Text(weeklyRate)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Calorie Budget Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("METABOLIC FUEL REQUIREMENT")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        TextField("2800", value: $dailyCalories, format: .number)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .frame(width: 150)
                        Text("kcal / day")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.bottom, 8)
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - 3. Macros Tab
struct MacrosTab: View {
    @State private var activePreset = "Strict Carnivore"
    @State private var setCustom = false
    
    @State private var fatPercent: Double = 80
    @State private var proteinPercent: Double = 20
    @State private var carbPercent: Double = 0
    
    let presets = [
        ("Strict Carnivore", 80.0, 20.0, 0.0),
        ("Standard Keto", 75.0, 20.0, 5.0),
        ("High-Protein Performance", 60.0, 40.0, 0.0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pie Chart Display
                VStack(spacing: 16) {
                    Chart {
                        SectorMark(angle: .value("Fat", fatPercent), innerRadius: .ratio(0.6), angularInset: 1.5)
                            .foregroundStyle(Color(red: 214/255, green: 160/255, blue: 84/255)) // Muted Gold
                        SectorMark(angle: .value("Protein", proteinPercent), innerRadius: .ratio(0.6), angularInset: 1.5)
                            .foregroundStyle(FriendlyTheme.apexGreen)
                        SectorMark(angle: .value("Carbs", carbPercent), innerRadius: .ratio(0.6), angularInset: 1.5)
                            .foregroundStyle(Color(red: 47/255, green: 79/255, blue: 79/255)) // Deep Slate
                    }
                    .frame(height: 200)
                    .padding()
                    
                    HStack(spacing: 24) {
                        MacroLegendItem(color: Color(red: 214/255, green: 160/255, blue: 84/255), label: "Fat", percent: fatPercent)
                        MacroLegendItem(color: FriendlyTheme.apexGreen, label: "Protein", percent: proteinPercent)
                        MacroLegendItem(color: Color(red: 47/255, green: 79/255, blue: 79/255), label: "Carbs", percent: carbPercent)
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Elite Presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("ELITE PRESETS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .padding(.horizontal, 24)
                    
                    ForEach(presets, id: \.0) { preset in
                        Button(action: {
                            if !setCustom {
                                withAnimation {
                                    activePreset = preset.0
                                    fatPercent = preset.1
                                    proteinPercent = preset.2
                                    carbPercent = preset.3
                                }
                            }
                        }) {
                            HStack {
                                Text(preset.0.uppercased())
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(activePreset == preset.0 && !setCustom ? .black : .white)
                                Spacer()
                                Text("\(Int(preset.1))F / \(Int(preset.2))P / \(Int(preset.3))C")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(activePreset == preset.0 && !setCustom ? .black : FriendlyTheme.textSecondary)
                            }
                            .padding(16)
                            .background(activePreset == preset.0 && !setCustom ? FriendlyTheme.apexGreen : Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .disabled(setCustom)
                    }
                }
                
                // Custom Macros Toggle
                VStack(spacing: 16) {
                    Toggle("SET CUSTOM MACROS", isOn: $setCustom)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                        .tint(FriendlyTheme.apexGreen)
                    
                    if setCustom {
                        VStack(spacing: 16) {
                            MacroSlider(label: "Fat", value: $fatPercent, color: Color(red: 214/255, green: 160/255, blue: 84/255))
                            MacroSlider(label: "Protein", value: $proteinPercent, color: FriendlyTheme.apexGreen)
                            MacroSlider(label: "Carbs", value: $carbPercent, color: Color(red: 47/255, green: 79/255, blue: 79/255))
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct MacroLegendItem: View {
    let color: Color
    let label: String
    let percent: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
            Text("\(Int(percent))%")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct MacroSlider: View {
    let label: String
    @Binding var value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            Slider(value: $value, in: 0...100)
                .accentColor(color)
        }
    }
}

// MARK: - 4. Nutrients Tab (Hunter-Gatherer Logic)
struct NutrientsTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("THE TRUTH SECTION")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                
                NutrientCard(
                    title: "Saturated Fat",
                    target: "High / Unrestricted",
                    targetColor: FriendlyTheme.apexGreen,
                    description: "Essential lipid fuel for hormonal optimization and cellular repair."
                )
                
                NutrientCard(
                    title: "Sodium",
                    target: "High (3,000mg - 6,000mg)",
                    targetColor: FriendlyTheme.apexGreen,
                    description: "Critical electrolyte for nerve function and muscle contraction during high-intensity Forge sessions."
                )
                
                NutrientCard(
                    title: "Dietary Fiber",
                    target: "Non-Essential",
                    targetColor: FriendlyTheme.textSecondary,
                    description: "Zero requirement for meat-based protocols; motility managed via fat-to-protein ratios."
                )
                
                NutrientCard(
                    title: "Net Carbs",
                    target: "< 20g",
                    targetColor: Color(red: 214/255, green: 160/255, blue: 84/255), // Muted Gold Warning
                    description: "Lock target at <20g for strict Carnivore/Keto baselines to ensure continuous ketone production."
                )
            }
            .padding(.bottom, 40)
        }
    }
}

struct NutrientCard: View {
    let title: String
    let target: String
    let targetColor: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(target)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(targetColor)
                    .multilineTextAlignment(.trailing)
            }
            
            Text(description)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
}

// MARK: - 5. Exercise Plan Tab
struct ExercisePlanTab: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @Query private var routines: [RoutineTemplate]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    private var currentProtocolName: String {
        routines.first?.name ?? "Heavy Duty HIT - 3 Day Split"
    }
    
    private var weeklyCommitment: String {
        let count = max(routines.first?.exercises.count ?? 3, 3)
        return "\(count) Days / Week"
    }
    
    private var volumeProjection: String {
        let recentLogs = dailyLogs.prefix(7).filter { $0.totalVolume > 0 }
        let avgVolume = recentLogs.isEmpty ? 15000 : recentLogs.reduce(0) { $0 + $1.totalVolume } / Double(recentLogs.count)
        let weeklyProjected = avgVolume * 3.0 // Assume 3 days a week
        return "\(Int(weeklyProjected / 1000))k lbs / week"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .padding(.top, 40)
                
                Text("THE FORGE PROTOCOL")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(.white)
                
                Text("Your exercise plan is strictly managed via High-Intensity Training principles within The Forge.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 16) {
                    ExercisePlanCard(title: "CURRENT PROTOCOL", value: currentProtocolName)
                    ExercisePlanCard(title: "WEEKLY COMMITMENT", value: weeklyCommitment)
                    ExercisePlanCard(title: "VOLUME PROJECTION", value: volumeProjection)
                }
                .padding(.top, 24)
                
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appState.selectedTab = 10
                    }
                }) {
                    Text("ENTER THE FORGE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FriendlyTheme.apexGreen)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

struct ExercisePlanCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(2.0)
                .foregroundColor(FriendlyTheme.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
}
