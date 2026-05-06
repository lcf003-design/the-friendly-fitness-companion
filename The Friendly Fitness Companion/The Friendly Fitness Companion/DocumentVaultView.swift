import SwiftUI
import SwiftData
import QuickLook

struct DocumentVaultView: View {
    @State private var files: [URL] = []
    @State private var previewUrl: URL?
    
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyLogs: [DailyLog]
    @Query private var healthRecords: [HealthRecord]
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            // Background Watermark
            Image(systemName: "hexagon")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .foregroundColor(FriendlyTheme.textSecondary.opacity(0.05))
                .rotationEffect(.degrees(15))
                .offset(x: 100, y: -100)
            
            VStack(spacing: 0) {
                // Raw Data Export Button
                Button(action: generateCSVExport) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("RAW DATA EXPORT (CSV)")
                    }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.0)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(FriendlyTheme.apexGreen.opacity(0.1))
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(FriendlyTheme.apexGreen.opacity(0.5), lineWidth: 1))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                if files.isEmpty {
                    Spacer()
                    Text("NO DOCUMENTS IN VAULT")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(files, id: \.self) { url in
                                DocumentCard(url: url, onPreview: {
                                    previewUrl = url
                                })
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
        .navigationTitle("Document Vault")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadFiles)
        .quickLookPreview($previewUrl)
    }
    
    private func loadFiles() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            self.files = fileURLs.filter { $0.pathExtension == "pdf" || $0.pathExtension == "csv" }.sorted(by: { u1, u2 in
                let d1 = (try? u1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let d2 = (try? u2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return d1 > d2
            })
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    private func generateCSVExport() {
        HapticManager.shared.light()
        
        var csvString = "Timestamp,Glucose(mg/dL),BreathKetones(ppm),BloodKetones(mmol/L),UrineKetones(mg/dL),SystolicBP,DiastolicBP,RestingHR,TotalCholesterol,HDL,LDL,Triglycerides,BodyWeight(lbs)\n"
        
        // Merge daily logs and health records into a combined timeline
        let allDates = Set(dailyLogs.map { Calendar.current.startOfDay(for: $0.date) } + healthRecords.map { Calendar.current.startOfDay(for: $0.timestamp) }).sorted(by: <)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for date in allDates {
            let logsOnDate = dailyLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            let recordsOnDate = healthRecords.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
            
            let glucose = recordsOnDate.last?.bloodGlucose ?? 0
            let breath = recordsOnDate.last?.breathKetones ?? 0.0
            let blood = recordsOnDate.last?.bloodKetones ?? 0.0
            let urine = recordsOnDate.last?.urineKetones ?? 0.0
            let sys = recordsOnDate.last?.bloodPressureSystolic ?? 0
            let dia = recordsOnDate.last?.bloodPressureDiastolic ?? 0
            let rhr = recordsOnDate.last?.restingHeartRate ?? 0
            let tc = recordsOnDate.last?.totalCholesterol ?? 0
            let hdl = recordsOnDate.last?.hdl ?? 0
            let ldl = recordsOnDate.last?.ldl ?? 0
            let tg = recordsOnDate.last?.triglycerides ?? 0
            
            let weight = logsOnDate.last?.bodyMeasurements.last?.bodyWeight ?? 0.0
            
            let line = "\(formatter.string(from: date)),\(glucose),\(breath),\(blood),\(urine),\(sys),\(dia),\(rhr),\(tc),\(hdl),\(ldl),\(tg),\(weight)\n"
            csvString.append(line)
        }
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")
        let fileURL = documentDirectory.appendingPathComponent("Health_Ledger_\(timestamp).csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            loadFiles()
            HapticManager.shared.success()
        } catch {
            print("Failed to write CSV: \(error)")
        }
    }
}

struct DocumentCard: View {
    let url: URL
    let onPreview: () -> Void
    
    var fileName: String {
        url.deletingPathExtension().lastPathComponent
    }
    
    var fileExtension: String {
        url.pathExtension.uppercased()
    }
    
    var fileSizeString: String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return "Unknown Size"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var creationDateString: String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let date = attributes[.creationDate] as? Date else {
            return "Unknown Date"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 50, height: 60)
                    .cornerRadius(8)
                
                Text(fileExtension)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(fileExtension == "PDF" ? .red : FriendlyTheme.apexGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(creationDateString)
                    Text("•")
                    Text(fileSizeString)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            Spacer()
            
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .padding(8)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.02))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .cornerRadius(12)
        .onTapGesture(perform: onPreview)
    }
}
