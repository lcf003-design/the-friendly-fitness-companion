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
                        
                        Text("The Collective")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Global Tonnage
                    VStack(spacing: 8) {
                        Text("Global Tonnage Today")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
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
                        Text("Prestige Leaderboard")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
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
        ModularRowCard(
            icon: rank == 1 ? "medal.fill" : "person.fill",
            iconColor: rank <= 3 ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary,
            title: "#\(rank) \(idString)",
            subtitle: isHeavyDuty ? "HD Certified" : "",
            value: "\(Int(volume).formatted()) \(preferredUnit)",
            isTop: rank == 1,
            isBottom: rank == 5
        )
        .padding(.horizontal, 24)
    }
}
