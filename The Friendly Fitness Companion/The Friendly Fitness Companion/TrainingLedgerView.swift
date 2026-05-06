import SwiftUI
import SwiftData

struct TrainingLedgerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    // Flatten workouts for the ledger view
    var allWorkouts: [(date: Date, workout: WorkoutEntry)] {
        var results: [(Date, WorkoutEntry)] = []
        for log in dailyLogs {
            for workout in log.workouts {
                results.append((log.date, workout))
            }
        }
        return results.sorted(by: { $0.0 > $1.0 })
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("TRAINING LEDGER")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .tracking(3.0)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Divider().background(Color.white.opacity(0.1))
                
                if allWorkouts.isEmpty {
                    Spacer()
                    Text("NO AUDIT LOGS FOUND")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) { // Extremely dense
                            ForEach(allWorkouts, id: \.workout.id) { item in
                                LedgerRowView(date: item.date, workout: item.workout)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 120) // padding for tab bar
                    }
                }
            }
        }
    }
}

struct LedgerRowView: View {
    let date: Date
    let workout: WorkoutEntry
    
    @State private var showSummary = false
    
    var isHeavyDuty: Bool {
        workout.sets.contains { $0.isAbsoluteFailure ?? false }
    }
    
    var totalTonnage: Double {
        workout.sets.reduce(Double(0)) { $0 + ($1.weight * Double($1.totalReps)) }
    }
    
    var body: some View {
        Button(action: { showSummary = true }) {
            HStack(spacing: 12) {
                Text(date.formatted(date: .numeric, time: .omitted))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .frame(width: 80, alignment: .leading)
                
                Text(workout.exerciseName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(totalTonnage)) \(preferredUnit)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(FriendlyTheme.apexGreen)
                
                if isHeavyDuty {
                    Text("HD")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(FriendlyTheme.apexGreen.opacity(0.2))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(FriendlyTheme.apexGreen, lineWidth: 1))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.02))
        }
        .sheet(isPresented: $showSummary) {
            // Reusing existing workout summary card or building a dense summary
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                VStack {
                    Text("LEDGER AUDIT: \(workout.exerciseName.uppercased())")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .padding(.top, 30)
                        .padding(.bottom, 20)
                    
                    ScrollView {
                        ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, set in
                            HStack {
                                Text("SET \(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                Text("\(Int(set.weight)) \(preferredUnit) × \(set.totalReps)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if set.isAbsoluteFailure == true {
                                    Text("FAIL")
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
