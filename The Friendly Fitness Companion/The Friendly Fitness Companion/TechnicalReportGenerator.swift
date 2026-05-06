import SwiftUI
import SwiftData

struct TechnicalReportPDFView: View {
    var dailyLogs: [DailyLog]
    var primeInsight: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                // Origin Hexagon Branding placeholder
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 24))
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .padding(.bottom, 8)
                
                Text("THE FRIENDLY FITNESS COMPANION")
                    .font(.system(size: 10, weight: .black))
                    .tracking(4.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                
                Text("METABOLIC BRIEF")
                    .font(.system(size: 24, weight: .black))
                    .tracking(2.0)
                    .foregroundColor(.white)
                
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FriendlyTheme.apexGreen)
            }
            .padding(.bottom, 10)
            
            // Prime Performance Insight Section
            if let insight = primeInsight {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRIME PERFORMANCE INSIGHT")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    
                    Text(insight)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FriendlyTheme.limeSignal)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FriendlyTheme.limeSignal.opacity(0.1))
                .cornerRadius(8)
                .padding(.bottom, 10)
            }
            
            // Mentzer Math Log
            Text("MENTZER MATH PROGRESSION")
                .font(.system(size: 14, weight: .bold))
                .tracking(2.0)
                .foregroundColor(FriendlyTheme.textSecondary)
            
            let recentLogs = dailyLogs.prefix(14)
            ForEach(Array(recentLogs), id: \.id) { log in
                if !log.workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(log.date.formatted(date: .abbreviated, time: .omitted).uppercased())
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(FriendlyTheme.apexGreen)
                        
                        ForEach(log.workouts) { workout in
                            ForEach(workout.sets) { set in
                                if !set.isWarmup && (set.isAbsoluteFailure == true || set.forcedRepsCount > 0) {
                                    HStack {
                                        Text(workout.exerciseName.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        
                                        if set.isAbsoluteFailure == true {
                                            Text("HEAVY DUTY CERTIFIED")
                                                .font(.system(size: 8, weight: .black))
                                                .padding(4)
                                                .background(FriendlyTheme.limeSignal.opacity(0.2))
                                                .foregroundColor(FriendlyTheme.limeSignal)
                                                .cornerRadius(4)
                                        }
                                        
                                        Text("\(Int(set.weight))\(set.unit) × \(set.totalReps)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    .padding(.vertical, 4)
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
            }
            
            Spacer()
        }
        .padding(40)
        .frame(width: 612, height: 792) // Standard Letter Size
        .background(FriendlyTheme.midnightMatte)
    }
}

@MainActor
class TechnicalReportGenerator {
    static func generatePDF(dailyLogs: [DailyLog], primeInsight: String? = nil) -> URL? {
        let view = TechnicalReportPDFView(dailyLogs: dailyLogs, primeInsight: primeInsight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Technical_Report_\(UUID().uuidString).pdf")
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        return url
    }
}
