import SwiftUI
import SwiftData

struct TrainingLedgerView: View {
    @Environment(\.dismiss) var dismiss
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
                // Modern Organic Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    
                    Spacer()
                    
                    Text("Training Ledger")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.clear) // Balance
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Divider().background(Color.white.opacity(0.1))
                
                if allWorkouts.isEmpty {
                    Spacer()
                    Text("No past events")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(allWorkouts, id: \.workout.id) { item in
                                LedgerRowView(date: item.date, workout: item.workout)
                            }
                        }
                        .padding(.horizontal, 20)
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
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    @State private var showSummary = false
    
    var isHeavyDuty: Bool {
        workout.sets.contains { $0.isAbsoluteFailure ?? false }
    }
    
    var totalTonnage: Double {
        workout.sets.reduce(Double(0)) { $0 + ($1.weight * Double($1.totalReps)) }
    }
    
    var body: some View {
        Button(action: { showSummary = true }) {
            HStack(spacing: 16) {
                // Icon Background
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(FriendlyTheme.mutedAmber)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.exerciseName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(totalTonnage)) \(preferredUnit)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(FriendlyTheme.calmBlue)
                    
                    if isHeavyDuty {
                        Text("High Intensity")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(FriendlyTheme.midnightMatteLight)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSummary) {
            // Reusing existing workout summary card or building a dense summary
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                VStack {
                    HStack {
                        Spacer()
                        Text("Workout Summary")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    Text(workout.exerciseName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, set in
                                HStack {
                                    Text("Set \(index + 1)")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text("\(Int(set.weight)) \(preferredUnit) × \(set.totalReps)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if set.isAbsoluteFailure == true {
                                        Text("Failure")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(FriendlyTheme.midnightMatteLight)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
