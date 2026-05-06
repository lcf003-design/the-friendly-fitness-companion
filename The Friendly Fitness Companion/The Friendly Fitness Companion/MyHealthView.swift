import SwiftUI
import SwiftData
import Charts

struct MyHealthView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var healthRecords: [HealthRecord]
    
    @State private var showEntryModal = false
    @State private var selectedMarker: HealthMarkerType?
    @State private var showSelectionSheet = false
    
    // Visibility Preferences (Prompt 60)
    @AppStorage("visibleHealthMarkers") private var visibleMarkersData: Data = Data()
    @State private var visibleMarkers: [HealthMarkerType] = HealthMarkerType.allCases
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                    Spacer()
                    Text("MY HEALTH")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        showSelectionSheet = true
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        healthSection(title: "HEALTH", markers: HealthMarkerType.healthMarkers)
                        healthSection(title: "BODY LOG", markers: HealthMarkerType.bodyLogMarkers)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadPreferences()
        }
        .sheet(item: $selectedMarker) { marker in
            HealthEntryModal(markerType: marker)
                .presentationDetents([.fraction(0.85)])
        }
        .sheet(isPresented: $showSelectionSheet) {
            HealthDataSelectionSheet(visibleMarkers: $visibleMarkers)
                .presentationDetents([.large])
        }
    }
    
    @ViewBuilder
    private func healthSection(title: String, markers: [HealthMarkerType]) -> some View {
        // Sort activeMarkers by the order in visibleMarkers
        let activeMarkers = visibleMarkers.filter { markers.contains($0) }
        
        if !activeMarkers.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .tracking(2.0)
                
                VStack(spacing: 12) {
                    ForEach(activeMarkers, id: \.self) { marker in
                        HealthMarkerRow(marker: marker, records: healthRecords)
                            .onTapGesture {
                                selectedMarker = marker
                            }
                    }
                }
            }
        }
    }
    
    private func loadPreferences() {
        if let decoded = try? JSONDecoder().decode([HealthMarkerType].self, from: visibleMarkersData) {
            visibleMarkers = decoded
        } else {
            visibleMarkers = HealthMarkerType.allCases
        }
    }
}

// MARK: - Health Marker Type Enum
enum HealthMarkerType: String, CaseIterable, Codable, Identifiable {
    case breathKetones, urineKetones, bloodKetones
    case bloodPressure, heartRate, restingHeartRate
    case bloodGlucose, hba1c
    case totalCholesterol, hdl, ldl, triglycerides
    case hipSize, waistSize, neckSize
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .breathKetones: return "Breath Ketones"
        case .urineKetones: return "Urine Ketones"
        case .bloodKetones: return "Blood Ketones"
        case .bloodPressure: return "Blood Pressure"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .bloodGlucose: return "Blood Glucose"
        case .hba1c: return "HbA1c"
        case .totalCholesterol: return "Total Cholesterol"
        case .hdl: return "HDL"
        case .ldl: return "LDL"
        case .triglycerides: return "Triglycerides"
        case .hipSize: return "Hip Size"
        case .waistSize: return "Waist Size"
        case .neckSize: return "Neck Size"
        }
    }
    
    var unit: String {
        switch self {
        case .breathKetones: return "PPM"
        case .urineKetones: return "mmol/L"
        case .bloodKetones: return "mmol/L"
        case .bloodPressure: return "mmHg"
        case .heartRate, .restingHeartRate: return "bpm"
        case .bloodGlucose: return "mg/dL"
        case .hba1c: return "%"
        case .totalCholesterol, .hdl, .ldl, .triglycerides: return "mg/dL"
        case .hipSize, .waistSize, .neckSize: return "in"
        }
    }
    
    static var healthMarkers: [HealthMarkerType] {
        [.breathKetones, .urineKetones, .bloodKetones, .bloodPressure, .heartRate, .restingHeartRate, .bloodGlucose, .hba1c, .totalCholesterol, .hdl, .ldl, .triglycerides]
    }
    
    static var bodyLogMarkers: [HealthMarkerType] {
        [.hipSize, .waistSize, .neckSize]
    }
}

// MARK: - Health Marker Row
struct HealthMarkerRow: View {
    let marker: HealthMarkerType
    let records: [HealthRecord]
    
    var recentRecord: HealthRecord? {
        records.sorted(by: { $0.timestamp > $1.timestamp }).first(where: { hasValue(for: marker, in: $0) })
    }
    
    var displayValue: String {
        guard let record = recentRecord else { return "--" }
        return getValueString(for: marker, in: record)
    }
    
    var dateString: String {
        guard let record = recentRecord else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: record.timestamp)
    }
    
    var trendData: [Double] {
        // Last 14 days of data
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let validRecords = records.filter { $0.timestamp >= cutoff && hasValue(for: marker, in: $0) }
            .sorted(by: { $0.timestamp < $1.timestamp })
        
        return validRecords.compactMap { getNumericValue(for: marker, in: $0) }
    }
    
    var isPositiveTrend: Bool {
        guard trendData.count >= 2 else { return true }
        let first = trendData.first!
        let last = trendData.last!
        
        switch marker {
        case .breathKetones, .urineKetones, .bloodKetones, .hdl:
            return last >= first // Higher is better
        case .restingHeartRate, .bloodGlucose, .hba1c, .totalCholesterol, .ldl, .triglycerides, .hipSize, .waistSize, .neckSize:
            return last <= first // Lower is better
        case .heartRate, .bloodPressure:
            return true // Neutral for simple trend
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(marker.displayName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    if recentRecord == nil {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(FriendlyTheme.textSecondary)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 10))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    
                    Text(recentRecord == nil ? "Not Logged" : dateString)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Sparkline
            if trendData.count > 1 {
                SparklineView(data: trendData, color: isPositiveTrend ? FriendlyTheme.apexGreen : .gray)
                    .frame(width: 60, height: 24)
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(displayValue)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(recentRecord != nil ? FriendlyTheme.apexGreen : .white)
                
                Text(marker.unit)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // Helpers
    private func hasValue(for marker: HealthMarkerType, in record: HealthRecord) -> Bool {
        switch marker {
        case .breathKetones: return record.breathKetones != nil
        case .urineKetones: return record.urineKetones != nil
        case .bloodKetones: return record.bloodKetones != nil
        case .bloodPressure: return record.bloodPressureSystolic != nil && record.bloodPressureDiastolic != nil
        case .heartRate: return record.heartRate != nil
        case .restingHeartRate: return record.restingHeartRate != nil
        case .bloodGlucose: return record.bloodGlucose != nil
        case .hba1c: return record.hba1c != nil
        case .totalCholesterol: return record.totalCholesterol != nil
        case .hdl: return record.hdl != nil
        case .ldl: return record.ldl != nil
        case .triglycerides: return record.triglycerides != nil
        case .hipSize: return record.hipSize != nil
        case .waistSize: return record.waistSize != nil
        case .neckSize: return record.neckSize != nil
        }
    }
    
    private func getValueString(for marker: HealthMarkerType, in record: HealthRecord) -> String {
        switch marker {
        case .bloodPressure:
            if let sys = record.bloodPressureSystolic, let dia = record.bloodPressureDiastolic {
                return "\(Int(sys))/\(Int(dia))"
            }
            return "--"
        default:
            if let val = getNumericValue(for: marker, in: record) {
                return val.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(val))" : String(format: "%.1f", val)
            }
            return "--"
        }
    }
    
    private func getNumericValue(for marker: HealthMarkerType, in record: HealthRecord) -> Double? {
        switch marker {
        case .breathKetones: return record.breathKetones
        case .urineKetones: return record.urineKetones
        case .bloodKetones: return record.bloodKetones
        case .bloodPressure: return record.bloodPressureSystolic // Using systolic for trend
        case .heartRate: return record.heartRate
        case .restingHeartRate: return record.restingHeartRate
        case .bloodGlucose: return record.bloodGlucose
        case .hba1c: return record.hba1c
        case .totalCholesterol: return record.totalCholesterol
        case .hdl: return record.hdl
        case .ldl: return record.ldl
        case .triglycerides: return record.triglycerides
        case .hipSize: return record.hipSize
        case .waistSize: return record.waistSize
        case .neckSize: return record.neckSize
        }
    }
}

// MARK: - Sparkline View
struct SparklineView: View {
    var data: [Double]
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard let min = data.min(), let max = data.max(), data.count > 1 else { return }
                
                let range = max - min == 0 ? 1 : max - min
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - (CGFloat((value - min) / range) * geometry.size.height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}
