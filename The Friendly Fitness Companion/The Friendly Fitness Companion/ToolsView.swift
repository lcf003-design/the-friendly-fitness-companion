import SwiftUI

struct ToolsView: View {
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    
    // Plate Calculator State
    @State private var targetBarbellWeight: String = "135"
    @State private var barWeight: Double = 45.0 // Standard Olympic Bar
    
    // Available plates (lbs)
    let availablePlates: [Double] = [45, 35, 25, 10, 5, 2.5]
    
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
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
                .onTapGesture { dismissKeyboard() }
            
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
                    
                    // Plate Math Calculator
                    VStack(alignment: .leading, spacing: 20) {
                        Text("PLATE MATH")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(2.0)
                        
                        HStack {
                            Text("TARGET (LBS)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            Spacer()
                            TextField("0", text: Binding(
                                get: { targetBarbellWeight },
                                set: { newValue in
                                    targetBarbellWeight = newValue
                                    triggerHaptic()
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        .padding(16)
                        .background(Color(white: 0.1))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        let platesNeeded = calculatePlates()
                        
                        if platesNeeded.isEmpty {
                            Text("Bar empty or invalid weight.")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.top, 10)
                        } else {
                            let actualWeight = (platesNeeded.reduce(0, +) * 2) + barWeight
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("LOAD PER SIDE:")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                    Spacer()
                                    Text("ACTUAL: \(actualWeight == floor(actualWeight) ? "\(Int(actualWeight))" : String(format: "%.1f", actualWeight)) LBS")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                
                                // Visual Barbell representation
                                HStack(spacing: 4) {
                                    // The Bar end
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 20, height: 10)
                                    
                                    // The Plates
                                    ForEach(Array(platesNeeded.enumerated()), id: \.offset) { index, plate in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(white: 0.2))
                                                .frame(width: plateWidth(for: plate), height: plateHeight(for: plate))
                                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1))
                                            
                                            Text(plate == floor(plate) ? "\(Int(plate))" : String(format: "%.1f", plate))
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .rotationEffect(.degrees(-90))
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                
                                // Text breakdown
                                HStack {
                                    ForEach(Array(Set(platesNeeded).sorted(by: >)), id: \.self) { uniquePlate in
                                        let count = platesNeeded.filter { $0 == uniquePlate }.count
                                        Text("\(count)x \(uniquePlate == floor(uniquePlate) ? "\(Int(uniquePlate))" : String(format: "%.1f", uniquePlate))")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(FriendlyTheme.apexGreen.opacity(0.2))
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.horizontal, 20)
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { dismissKeyboard() }
                .padding(.bottom, 100)
            }
        }
    }
    
    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Plate Logic
    private func calculatePlates() -> [Double] {
        guard let target = Double(targetBarbellWeight), target > barWeight else { return [] }
        
        var weightToFillPerSide = (target - barWeight) / 2.0
        var plates: [Double] = []
        
        for plate in availablePlates {
            // Epsilon added to prevent floating point inaccuracy
            while weightToFillPerSide >= (plate - 0.001) {
                plates.append(plate)
                weightToFillPerSide -= plate
            }
        }
        
        return plates
    }
    
    private func plateHeight(for weight: Double) -> CGFloat {
        switch weight {
        case 45: return 80
        case 35: return 70
        case 25: return 60
        case 10: return 45
        case 5: return 35
        case 2.5: return 30
        default: return 50
        }
    }
    
    private func plateWidth(for weight: Double) -> CGFloat {
        switch weight {
        case 45: return 24
        case 35: return 20
        case 25: return 18
        case 10: return 14
        case 5: return 10
        case 2.5: return 8
        default: return 15
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
