import SwiftUI
import SwiftData

struct SnapLogView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let type: SnapLogType
    
    @State private var inputString = "0"
    @State private var showSuccess = false
    
    @Query private var dailyLogs: [DailyLog]
    
    var title: String {
        switch type {
        case .water: return "LOG WATER"
        case .weight: return "WEIGH IN"
        case .calories: return "QUICK CALORIES"
        }
    }
    
    var unit: String {
        switch type {
        case .water: return "fl oz"
        case .weight: return "lbs"
        case .calories: return "kcal"
        }
    }
    
    var color: Color {
        switch type {
        case .water: return .blue
        case .weight: return .purple
        case .calories: return .orange
        }
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                    Text(title)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Save") {
                        saveLog()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Display
                HStack(alignment: .bottom, spacing: 8) {
                    Text(inputString)
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text(unit)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .padding(.bottom, 10)
                }
                .frame(height: 100)
                .padding(.horizontal, 24)
                
                // Numpad
                VStack(spacing: 16) {
                    ForEach([
                        ["1", "2", "3"],
                        ["4", "5", "6"],
                        ["7", "8", "9"],
                        [".", "0", "⌫"]
                    ], id: \.self) { row in
                        HStack(spacing: 16) {
                            ForEach(row, id: \.self) { key in
                                Button(action: {
                                    handleKeyPress(key)
                                }) {
                                    Text(key)
                                        .font(.system(size: 28, weight: .medium, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 64)
                                        .background(Color.white.opacity(0.05))
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            if showSuccess {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .scaleEffect(showSuccess ? 1.0 : 0.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showSuccess)
                    
                    Text("SAVED")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .tracking(4.0)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
            }
        }
    }
    
    private func handleKeyPress(_ key: String) {
        HapticManager.shared.light()
        
        if key == "⌫" {
            if inputString.count > 1 {
                inputString.removeLast()
            } else {
                inputString = "0"
            }
        } else if key == "." {
            if !inputString.contains(".") {
                inputString += "."
            }
        } else {
            if inputString == "0" {
                inputString = key
            } else {
                inputString += key
            }
        }
    }
    
    private func saveLog() {
        guard let value = Double(inputString), value > 0 else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        let log: DailyLog
        if let existing = dailyLogs.first(where: { $0.id == todayStr }) {
            log = existing
        } else {
            log = DailyLog(date: Date())
            modelContext.insert(log)
        }
        
        switch type {
        case .water:
            break
        case .weight:
            let measurement = BodyMeasurement(bodyWeight: value, timestamp: Date())
            log.bodyMeasurements.append(measurement)
        case .calories:
            let food = FoodEntry(name: "Quick Calories", calories: Int(value), protein: 0, fat: 0, carbs: 0)
            log.foodEntries.append(food)
        }
        
        try? modelContext.save()
        
        HapticManager.shared.success()
        withAnimation {
            showSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}
