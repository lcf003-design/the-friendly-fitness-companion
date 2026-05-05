import SwiftUI

// MARK: - Theme Definitions
struct FriendlyTheme {
    static let midnightMatte = Color(red: 10/255, green: 10/255, blue: 10/255)
    static let midnightMatteLight = Color(red: 26/255, green: 26/255, blue: 26/255)
    static let apexGreen = Color(red: 0, green: 1.0, blue: 0)
    static let limeSignal = Color(red: 191/255, green: 255/255, blue: 0)
    static let mutedAmber = Color(red: 214/255, green: 160/255, blue: 84/255)
    static let textSecondary = Color.gray
}

// MARK: - Main Dashboard View
struct DashboardView: View {
    @State private var motorUnitRecruitment: Double = 0.88
    @State private var fatGrams: Double = 120
    @State private var proteinGrams: Double = 120
    
    var body: some View {
        ZStack {
            // Background
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Spacer()
                        
                        Text("THE FRIENDLY COMPANION")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .tracking(1.2)
                        
                        Spacer()
                        
                        Image(systemName: "bell")
                            .font(.system(size: 24))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // The Forge: Henneman Meter
                    HennemanMeterView(recruitmentLevel: motorUnitRecruitment)
                    
                    // The Kitchen: Fat to Protein Ratio
                    FatProteinDialView(fat: fatGrams, protein: proteinGrams)
                    
                    // Optional Recovery/HealthKit Data
                    RecoveryBalanceView()
                }
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Henneman Meter Component
struct HennemanMeterView: View {
    var recruitmentLevel: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Track
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(FriendlyTheme.midnightMatteLight, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(180))
                
                // Active Green Track
                Circle()
                    .trim(from: 0.5, to: 0.5 + (recruitmentLevel / 2))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [FriendlyTheme.limeSignal, FriendlyTheme.apexGreen]), center: .center, startAngle: .degrees(180), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(180))
                    .shadow(color: FriendlyTheme.apexGreen.opacity(0.6), radius: 20, x: 0, y: 0)
                
                // Percentage Text
                VStack(spacing: -4) {
                    Text("\(Int(recruitmentLevel * 100))%")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                    
                    Text("MOTOR UNIT\nRECRUITMENT")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .tracking(1.5)
                }
                .offset(y: -30)
            }
            .frame(height: 140) // Clip the bottom half of the circle
        }
        .padding(.top, 20)
    }
}

// MARK: - Fat to Protein Dial Component
struct FatProteinDialView: View {
    var fat: Double
    var protein: Double
    
    var body: some View {
        VStack {
            Text("FAT:PROTEIN RATIO")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.0)
                .padding(.bottom, 16)
            
            HStack(spacing: 30) {
                // Fat Stat
                VStack(alignment: .trailing) {
                    Text("FAT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FriendlyTheme.limeSignal)
                    Text("\(Int(fat))g")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Center Dial (1:1 Indicator)
                ZStack {
                    Circle()
                        .fill(FriendlyTheme.midnightMatte)
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Simple representation of the dial
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .stroke(FriendlyTheme.limeSignal, lineWidth: 15)
                        .rotationEffect(.degrees(90))
                    
                    Circle()
                        .trim(from: 0.5, to: 1.0)
                        .stroke(FriendlyTheme.apexGreen, lineWidth: 15)
                        .rotationEffect(.degrees(90))
                    
                    VStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        Text("1:1")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("RATIO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                }
                
                // Protein Stat
                VStack(alignment: .leading) {
                    Text("PROTEIN")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FriendlyTheme.apexGreen)
                    Text("\(Int(protein))g")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(24)
        .background(FriendlyTheme.midnightMatteLight)
        .cornerRadius(30)
        .padding(.horizontal, 20)
    }
}

// MARK: - Recovery Balance Placeholder
struct RecoveryBalanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OPTIMAL RECOVERY BALANCE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .tracking(0.5)
            Text("INTAKE: 1540 CAL")
                .font(.system(size: 14))
                .foregroundColor(FriendlyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(FriendlyTheme.midnightMatteLight)
        .cornerRadius(30)
        .padding(.horizontal, 20)
    }
}

// MARK: - Previews
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
