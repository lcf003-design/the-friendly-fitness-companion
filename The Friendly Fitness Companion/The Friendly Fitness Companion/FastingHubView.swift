import SwiftUI
import SwiftData
import Combine

struct FastingStage: Identifiable, Hashable {
    let id = UUID()
    let stageNumber: Int
    let title: String
    let timeRange: String
    let startHour: Double
    let endHour: Double
    let biologicalAction: String
    let description: String
    let benefits: [String]
}

let fastingStagesData: [FastingStage] = [
    FastingStage(stageNumber: 1, title: "Fed State / Anabolic Phase", timeRange: "0-4h", startHour: 0, endHour: 4, biologicalAction: "Storing Glycogen", description: "Blood sugar rises, and insulin is secreted to transport glucose into cells for energy or storage. Digestion and nutrient absorption are the primary focus.", benefits: ["Energy replenishment", "Muscle protein synthesis", "Glycogen restocking"]),
    FastingStage(stageNumber: 2, title: "Early Fasting State", timeRange: "4-16h", startHour: 4, endHour: 16, biologicalAction: "Burning Glycogen", description: "Insulin levels drop, and blood sugar normalizes. The body starts pulling glycogen from the liver to maintain baseline energy requirements.", benefits: ["Stabilized blood sugar", "Lowered insulin levels", "Initial transition to fat metabolism"]),
    FastingStage(stageNumber: 3, title: "Ketosis / Fat Burning Zone", timeRange: "16-24h", startHour: 16, endHour: 24, biologicalAction: "Producing Ketones", description: "Liver glycogen is significantly depleted. The body ramps up lipolysis, breaking down body fat into fatty acids and converting them into ketones.", benefits: ["Accelerated fat loss", "Mental clarity and focus", "Reduced systemic inflammation"]),
    FastingStage(stageNumber: 4, title: "Autophagy & Anti-aging", timeRange: "24-72h", startHour: 24, endHour: 72, biologicalAction: "Cellular Recycling", description: "The body initiates a deep cellular recycling process. Old, damaged proteins, organelles, and senescent cells are broken down and cleared out.", benefits: ["Cellular renewal", "Anti-aging effects", "Neurodegenerative protection"]),
    FastingStage(stageNumber: 5, title: "Immune Regeneration", timeRange: "72+h", startHour: 72, endHour: 999, biologicalAction: "Stem Cell Rebirth", description: "Extended fasting leads to a significant drop in IGF-1 and PKA, signaling the body to break down old immune cells and generate fresh stem cells.", benefits: ["Immune system reset", "Deep metabolic healing", "Stem cell proliferation"])
]

struct FastingHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingSession.startTime, order: .reverse) private var sessions: [FastingSession]
    
    @State private var activeSession: FastingSession?
    @State private var currentTime: Date = Date()
    @State private var showHistory = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Pulse animation
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .font(.system(size: 24))
                        
                        Text("FASTING HUB")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(4.0)
                            .foregroundColor(.white)
                        Spacer()
                        
                        Button(action: { showHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Active Tracker
                    VStack(spacing: 16) {
                        if let session = activeSession {
                            let duration = currentTime.timeIntervalSince(session.startTime)
                            let hours = duration / 3600
                            let currentStage = currentStage(for: hours)
                            
                            Text(formatDuration(duration))
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.apexGreen)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(FriendlyTheme.apexGreen)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(isPulsing ? 1.2 : 0.8)
                                    .opacity(isPulsing ? 1.0 : 0.5)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(), value: isPulsing)
                                
                                Text(currentStage.biologicalAction.uppercased() + " ACTIVE")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(2.0)
                                    .foregroundColor(.white)
                            }
                            
                            // Stage Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    // 72 hours is the max for the bar
                                    let progress = min(hours / 72.0, 1.0)
                                    
                                    Rectangle()
                                        .fill(FriendlyTheme.apexGreen)
                                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            .padding(.top, 16)
                            
                            HStack {
                                Text("0h")
                                Spacer()
                                Text("72h+")
                            }
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            
                            Button(action: endFast) {
                                Text("END FAST")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(2.0)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 16)
                            
                        } else {
                            Text("00:00:00")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("NOT FASTING")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.textSecondary)
                            
                            Button(action: startFast) {
                                Text("START FAST")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(2.0)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(FriendlyTheme.apexGreen)
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .onAppear {
                        isPulsing = true
                    }
                    
                    // Clickable Stage Cards
                    VStack(spacing: 12) {
                        ForEach(fastingStagesData) { stage in
                            let currentHours = activeSession.map { currentTime.timeIntervalSince($0.startTime) / 3600 } ?? 0
                            let isCurrentOrCompleted = currentHours >= stage.startHour
                            
                            NavigationLink(destination: FastingStageDetailView(stage: stage, isCurrent: currentHours >= stage.startHour && currentHours < stage.endHour)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(isCurrentOrCompleted ? FriendlyTheme.apexGreen.opacity(0.2) : Color.white.opacity(0.05))
                                            .frame(width: 40, height: 40)
                                        Text("\(stage.stageNumber)")
                                            .font(.system(size: 16, weight: .black, design: .rounded))
                                            .foregroundColor(isCurrentOrCompleted ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stage.title.uppercased())
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(isCurrentOrCompleted ? .white : FriendlyTheme.textSecondary)
                                        Text(stage.timeRange)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isCurrentOrCompleted ? FriendlyTheme.apexGreen.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            findActiveSession()
        }
        .onReceive(timer) { time in
            if activeSession != nil {
                currentTime = time
            }
        }
        .sheet(isPresented: $showHistory) {
            FastingHistoryView(sessions: sessions)
        }
    }
    
    private func findActiveSession() {
        if let active = sessions.first(where: { $0.endTime == nil }) {
            activeSession = active
        }
    }
    
    private func startFast() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let newSession = FastingSession()
        modelContext.insert(newSession)
        try? modelContext.save()
        activeSession = newSession
        currentTime = Date()
    }
    
    private func endFast() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        activeSession?.endTime = Date()
        try? modelContext.save()
        activeSession = nil
    }
    
    private func currentStage(for hours: Double) -> FastingStage {
        return fastingStagesData.first(where: { hours >= $0.startHour && hours < $0.endHour }) ?? fastingStagesData.last!
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

// MARK: - Stage Detail View
struct FastingStageDetailView: View {
    let stage: FastingStage
    let isCurrent: Bool
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .center, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(isCurrent ? FriendlyTheme.apexGreen.opacity(0.2) : Color.white.opacity(0.05))
                                .frame(width: 80, height: 80)
                            Text("\(stage.stageNumber)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(isCurrent ? FriendlyTheme.apexGreen : .white)
                        }
                        
                        Text(stage.title.uppercased())
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(stage.timeRange)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(FriendlyTheme.apexGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(FriendlyTheme.apexGreen.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WHAT HAPPENS")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        Text(stage.description)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .lineSpacing(6)
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("BENEFITS")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        ForEach(stage.benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .font(.system(size: 18))
                                Text(benefit)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Fasting History
struct FastingHistoryView: View {
    @Environment(\.dismiss) var dismiss
    let sessions: [FastingSession]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                let completed = sessions.filter { $0.endTime != nil }
                
                if completed.isEmpty {
                    Text("NO HISTORY")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                } else {
                    List {
                        ForEach(completed) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(session.startTime))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Duration: \(formatDuration(session.duration))")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        .onDelete(perform: deleteSession)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("FASTING HISTORY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func deleteSession(offsets: IndexSet) {
        let completed = sessions.filter { $0.endTime != nil }
        for index in offsets {
            modelContext.delete(completed[index])
        }
        try? modelContext.save()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return "\(hours)h \(minutes)m"
    }
}
