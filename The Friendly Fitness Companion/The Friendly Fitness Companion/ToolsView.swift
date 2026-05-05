import SwiftUI

struct ToolsView: View {
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    
    // Calculate 1RM using Brzycki Formula
    private var oneRepMax: Double {
        guard let w = Double(weightInput), let r = Double(repsInput), r > 0 else {
            return 0.0
        }
        // Brzycki: Weight / (1.0278 - (0.0278 * Reps))
        let max = w / (1.0278 - (0.0278 * r))
        
        // Trigger haptic if valid calculation (could be optimized, but using SwiftUI state)
        return max
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 18))
                        
                        Text("TOOLS")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // 1RM Calculator Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("1RM CALCULATOR")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(2.0)
                        
                        // Inputs
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("WEIGHT (LBS)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                
                                TextField("0", text: Binding(
                                    get: { weightInput },
                                    set: { newValue in
                                        weightInput = newValue
                                        triggerHaptic()
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("REPS")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                
                                TextField("0", text: Binding(
                                    get: { repsInput },
                                    set: { newValue in
                                        repsInput = newValue
                                        triggerHaptic()
                                    }
                                ))
                                .keyboardType(.numberPad)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }
                        
                        // Neon Bloom Result Card
                        VStack {
                            Text("ESTIMATED 1RM")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                                .tracking(1.5)
                            
                            Text(oneRepMax > 0 ? "\(Int(oneRepMax)) LBS" : "--")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(.black)
                                .contentTransition(.numericText())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(FriendlyTheme.apexGreen)
                        .cornerRadius(20)
                        .shadow(color: FriendlyTheme.apexGreen.opacity(0.6), radius: 20, x: 0, y: 0)
                        .padding(.vertical, 10)
                        
                        // Strength Table
                        if oneRepMax > 0 {
                            VStack(spacing: 12) {
                                StrengthRow(percentage: 85, weight: oneRepMax * 0.85)
                                Divider().background(Color.white.opacity(0.1))
                                StrengthRow(percentage: 80, weight: oneRepMax * 0.80)
                                Divider().background(Color.white.opacity(0.1))
                                StrengthRow(percentage: 75, weight: oneRepMax * 0.75)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100)
            }
        }
    }
    
    private func triggerHaptic() {
        if !weightInput.isEmpty && !repsInput.isEmpty {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}

// MARK: - Strength Table Row
struct StrengthRow: View {
    var percentage: Int
    var weight: Double
    
    var body: some View {
        HStack {
            Text("\(percentage)%")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(FriendlyTheme.limeSignal)
            
            Spacer()
            
            Text("\(Int(weight)) lbs")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ToolsView()
}
