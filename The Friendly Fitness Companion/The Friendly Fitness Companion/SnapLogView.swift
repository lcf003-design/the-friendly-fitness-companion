import SwiftUI
import SwiftData

struct SnapLogView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let type: SnapLogType
    
    @State private var inputValue: Double = 0
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
                    Text(type == .weight ? String(format: "%.1f", inputValue) : "\(Int(inputValue))")
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
                
                // Macro-Dial Scroller
                MacroDialView(
                    value: $inputValue,
                    range: 0...5000,
                    step: type == .weight ? 0.1 : 10,
                    label: type == .weight ? "SCROLL TO ADJUST WEIGHT" : "SCROLL TO ADJUST VALUE"
                )
                .padding(.horizontal, 24)
                
                if type == .water {
                    HStack(spacing: 16) {
                        ForEach([8, 16, 32], id: \.self) { amount in
                            Button(action: {
                                HapticManager.shared.light()
                                inputValue = Double(amount)
                                saveLog()
                            }) {
                                Text("\(amount)oz")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
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
        .onAppear {
            if type == .weight {
                if let lastWeight = dailyLogs.flatMap({ $0.bodyMeasurements }).max(by: { $0.timestamp < $1.timestamp })?.bodyWeight {
                    inputValue = lastWeight
                }
            }
        }
    }
    
    private func saveLog() {
        let valueToSave = inputValue
        guard valueToSave > 0 else { return }
        
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
            log.bodyMeasurements.append(BodyMeasurement(bodyWeight: valueToSave, timestamp: Date()))
        case .calories:
            let entry = FoodEntry(name: "Quick Calories", calories: Int(valueToSave), protein: 0, fat: 0, carbs: 0)
            log.foodEntries.append(entry)
        }
        
        try? modelContext.save()
        
        HapticManager.shared.success()
        withAnimation {
            showSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            dismiss()
        }
    }
}
