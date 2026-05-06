import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
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
                        .padding(.bottom, 10)
                        
                        // Menu Cards
                        NavigationLink(destination: OneRepMaxView()) {
                            ToolMenuCard(
                                title: "1RM CALCULATOR",
                                subtitle: "Estimate your one-rep max and view your localized strength curve based on the Epley formula.",
                                systemImage: "chart.line.uptrend.xyaxis"
                            )
                        }
                        
                        NavigationLink(destination: PlateMathView()) {
                            ToolMenuCard(
                                title: "PLATE MATH",
                                subtitle: "Quickly calculate exactly which plates to load onto the barbell for a target weight.",
                                systemImage: "circle.circle.fill"
                            )
                        }
                        
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Tool Menu Card UI
struct ToolMenuCard: View {
    var title: String
    var subtitle: String
    var systemImage: String
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(FriendlyTheme.apexGreen.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(FriendlyTheme.apexGreen)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(FriendlyTheme.textSecondary)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

// MARK: - 1RM Calculator Subview
struct OneRepMaxView: View {
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    
    let strengthTableData: [(percentage: Int, reps: Int)] = [
        (100, 1), (95, 2), (90, 4), (85, 6), (80, 8),
        (75, 10), (70, 12), (65, 16), (60, 20), (55, 24), (50, 30)
    ]
    
    private var oneRepMax: Double {
        guard let w = Double(weightInput), let r = Double(repsInput), r > 0 else {
            return 0.0
        }
        if r == 1 { return w }
        return w * (1.0 + (r / 30.0))
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Inputs
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WEIGHT (LBS)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            
                            TextField("0", text: $weightInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
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
                            
                            TextField("0", text: $repsInput)
                                .keyboardType(.numberPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Result Card
                    VStack {
                        Text("ESTIMATED 1RM")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.6))
                            .tracking(1.5)
                        
                        Text(oneRepMax > 0 ? "\(String(format: "%.1f", oneRepMax)) LBS" : "--")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(FriendlyTheme.apexGreen)
                    .cornerRadius(24)
                    .shadow(color: FriendlyTheme.apexGreen.opacity(0.6), radius: 20, x: 0, y: 0)
                    
                    // Strength Table
                    if oneRepMax > 0 {
                        VStack(spacing: 12) {
                            HStack {
                                Text("PERCENT")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .frame(width: 60, alignment: .leading)
                                Spacer()
                                Text("WEIGHT")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .frame(width: 80, alignment: .center)
                                Spacer()
                                Text("REPS")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 4)
                            
                            ForEach(strengthTableData, id: \.percentage) { item in
                                StrengthRow(percentage: item.percentage, weight: oneRepMax * (Double(item.percentage) / 100.0), reps: item.reps)
                                if item.percentage != 50 {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("1RM Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Plate Math Subview
struct PlateMathView: View {
    @State private var targetBarbellWeight: String = "135"
    @State private var barWeight: Double = 45.0
    let availablePlates: [Double] = [45, 35, 25, 10, 5, 2.5]
    
    private func calculatePlates() -> [Double] {
        guard let target = Double(targetBarbellWeight), target > barWeight else { return [] }
        var weightToFillPerSide = (target - barWeight) / 2.0
        var plates: [Double] = []
        for plate in availablePlates {
            while weightToFillPerSide >= (plate - 0.001) {
                plates.append(plate)
                weightToFillPerSide -= plate
            }
        }
        return plates
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("TARGET (LBS)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        Spacer()
                        TextField("0", text: $targetBarbellWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    .padding(20)
                    .background(Color(white: 0.1))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .padding(.top, 20)
                    
                    let platesNeeded = calculatePlates()
                    
                    if platesNeeded.isEmpty {
                        Text("Bar empty or invalid weight.")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    } else {
                        let actualWeight = (platesNeeded.reduce(0, +) * 2) + barWeight
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("LOAD PER SIDE:")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                Spacer()
                                Text("ACTUAL: \(actualWeight == floor(actualWeight) ? "\(Int(actualWeight))" : String(format: "%.1f", actualWeight)) LBS")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            
                            // Visual Barbell
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 20, height: 10)
                                
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
                            .padding(.vertical, 16)
                            
                            // Text breakdown
                            HStack {
                                ForEach(Array(Set(platesNeeded).sorted(by: >)), id: \.self) { uniquePlate in
                                    let count = platesNeeded.filter { $0 == uniquePlate }.count
                                    Text("\(count)x \(uniquePlate == floor(uniquePlate) ? "\(Int(uniquePlate))" : String(format: "%.1f", uniquePlate))")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(FriendlyTheme.apexGreen.opacity(0.2))
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Plate Math")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func plateHeight(for plate: Double) -> CGFloat {
        if plate >= 45 { return 100 }
        if plate >= 35 { return 80 }
        if plate >= 25 { return 65 }
        if plate >= 10 { return 50 }
        return 40
    }
    
    private func plateWidth(for plate: Double) -> CGFloat {
        if plate >= 45 { return 24 }
        if plate >= 35 { return 20 }
        if plate >= 25 { return 18 }
        if plate >= 10 { return 14 }
        return 12
    }
}

// Reused row component
struct StrengthRow: View {
    var percentage: Int
    var weight: Double
    var reps: Int
    
    var body: some View {
        HStack {
            Text("\(percentage)%")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(FriendlyTheme.apexGreen)
                .frame(width: 60, alignment: .leading)
            Spacer()
            Text("\(String(format: "%.1f", weight)) lbs")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .center)
            Spacer()
            Text("\(reps)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

#Preview {
    ToolsView()
}
