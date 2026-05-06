import SwiftUI
import SwiftData

struct CommunityView: View {
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    @Query private var allWorkouts: [WorkoutEntry]
    
    // Fake "GLOBAL TONNAGE" based on local + huge number
    private var globalTonnage: Double {
        let localVolume = dailyLogs.reduce(0) { $0 + $1.totalVolume }
        let baseTonnage = 12_450_800.0 // 12.4 million lbs
        return baseTonnage + localVolume
    }
    
    // Mock Leaderboard Data
    private var topPerformers: [(String, Double, Bool)] {
        // Find local user max volume
        let localMax = allWorkouts.reduce(0) { $0 + $1.sets.reduce(0, { $0 + ($1.weight * Double($1.totalReps)) }) }
        
        let localHeavyDuty = allWorkouts.contains(where: { $0.sets.contains(where: { $0.isAbsoluteFailure == true }) })
        
        let performers = [
            ("USR-7A8B", 84500.0, true),
            ("USR-1X9Q", 78200.0, true),
            ("USR-LOCAL", localMax > 0 ? localMax : 32000.0, localHeavyDuty),
            ("USR-4M2L", 65400.0, false),
            ("USR-9C5V", 52100.0, false)
        ]
        
        return performers.sorted(by: { $0.1 > $1.1 })
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 18))
                        
                        Text("THE COLLECTIVE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Global Tonnage
                    VStack(spacing: 8) {
                        Text("GLOBAL TONNAGE TODAY")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Text("\(Int(globalTonnage).formatted())")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: FriendlyTheme.apexGreen.opacity(0.3), radius: 10, x: 0, y: 0)
                        
                        Text("\(preferredUnit.uppercased()) MOVED BY THE FORGE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    .padding(.vertical, 30)
                    
                    // Leaderboard
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PRESTIGE LEADERBOARD")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.horizontal, 24)
                        
                        ForEach(Array(topPerformers.enumerated()), id: \.offset) { index, performer in
                            LeaderboardRow(
                                rank: index + 1,
                                idString: performer.0,
                                volume: performer.1,
                                isHeavyDuty: performer.2
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let idString: String
    let volume: Double
    let isHeavyDuty: Bool
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    var body: some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(rank <= 3 ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(idString)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if isHeavyDuty {
                    Text("HD CERTIFIED")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FriendlyTheme.limeSignal.opacity(0.2))
                        .foregroundColor(FriendlyTheme.limeSignal)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Text("\(Int(volume).formatted()) \(preferredUnit)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHeavyDuty ? FriendlyTheme.apexGreen.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isHeavyDuty ? 1.5 : 1)
                .shadow(color: isHeavyDuty ? FriendlyTheme.apexGreen.opacity(0.2) : .clear, radius: 5)
        )
        .padding(.horizontal, 24)
    }
}
