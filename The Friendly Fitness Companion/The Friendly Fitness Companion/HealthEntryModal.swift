import SwiftUI
import SwiftData

struct HealthEntryModal: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var healthRecords: [HealthRecord]
    
    let markerType: HealthMarkerType
    
    @State private var inputString = "0"
    @State private var secondaryInputString = "0"
    @State private var isEnteringSecondary = false // For Blood Pressure Diastolic
    @State private var notes = ""
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                    Text("LOG \(markerType.displayName.uppercased())")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Save") {
                        saveLog()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FriendlyTheme.apexGreen)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Display Area
                if markerType == .bloodPressure {
                    HStack(spacing: 8) {
                        Text(inputString)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(isEnteringSecondary ? .white : FriendlyTheme.apexGreen)
                            .onTapGesture { isEnteringSecondary = false }
                        
                        Text("/")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(secondaryInputString)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(isEnteringSecondary ? FriendlyTheme.apexGreen : .white)
                            .onTapGesture { isEnteringSecondary = true }
                        
                        Text(markerType.unit)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.bottom, 8)
                    }
                    .frame(height: 80)
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(inputString)
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        Text(markerType.unit)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.bottom, 10)
                    }
                    .frame(height: 80)
                }
                
                // Numpad
                VStack(spacing: 12) {
                    ForEach([
                        ["1", "2", "3"],
                        ["4", "5", "6"],
                        ["7", "8", "9"],
                        [".", "0", "⌫"]
                    ], id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(row, id: \.self) { key in
                                Button(action: {
                                    handleKeyPress(key)
                                }) {
                                    Text(key)
                                        .font(.system(size: 28, weight: .medium, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(Color.white.opacity(0.05))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTES")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .padding(.horizontal, 24)
                    
                    TextField("Fasted for 12 hours...", text: $notes)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            
            // Success Overlay
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
        
        if markerType == .bloodPressure && isEnteringSecondary {
            updateInputString(&secondaryInputString, key: key)
        } else {
            updateInputString(&inputString, key: key)
        }
    }
    
    private func updateInputString(_ input: inout String, key: String) {
        if key == "⌫" {
            if input.count > 1 {
                input.removeLast()
            } else {
                input = "0"
            }
        } else if key == "." {
            if !input.contains(".") {
                input += "."
            }
        } else {
            if input == "0" {
                input = key
            } else {
                input += key
            }
        }
    }
    
    private func saveLog() {
        guard let value1 = Double(inputString) else { return }
        
        let record = HealthRecord(timestamp: Date(), notes: notes.isEmpty ? nil : notes)
        
        switch markerType {
        case .breathKetones: record.breathKetones = value1
        case .urineKetones: record.urineKetones = value1
        case .bloodKetones: record.bloodKetones = value1
        case .heartRate: record.heartRate = value1
        case .restingHeartRate: record.restingHeartRate = value1
        case .bloodGlucose: record.bloodGlucose = value1
        case .hba1c: record.hba1c = value1
        case .totalCholesterol: record.totalCholesterol = value1
        case .hdl: record.hdl = value1
        case .ldl: record.ldl = value1
        case .triglycerides: record.triglycerides = value1
        case .hipSize: record.hipSize = value1
        case .waistSize: record.waistSize = value1
        case .neckSize: record.neckSize = value1
        case .bloodPressure:
            guard let value2 = Double(secondaryInputString) else { return }
            record.bloodPressureSystolic = value1
            record.bloodPressureDiastolic = value2
        }
        
        modelContext.insert(record)
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
