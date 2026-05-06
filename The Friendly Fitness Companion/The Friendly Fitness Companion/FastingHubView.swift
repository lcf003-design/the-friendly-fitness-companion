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
    @Query private var profiles: [UserProfile]
    
    @State private var activeSession: FastingSession?
    @State private var currentTime: Date = Date()
    @State private var showHistory = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Pulse animation
    @State private var isPulsing = false
    
    private var targetHours: Double {
        profiles.first?.selectedFastingProtocol ?? 16.0
    }
    
    private var dynamicStages: [FastingStage] {
        let t = targetHours
        let autophagyStart = max(12.0, t - 3.0) // e.g. 13h for 16:8, 20h for 23:1
        let ketosisStart = max(8.0, t - 6.0) // e.g. 10h for 16:8, 17h for 23:1
        
        return [
            FastingStage(stageNumber: 1, title: "Fed State / Anabolic Phase", timeRange: "0-4h", startHour: 0, endHour: 4, biologicalAction: "Storing Glycogen", description: "Blood sugar rises, and insulin is secreted to transport glucose into cells for energy or storage.", benefits: ["Energy replenishment", "Muscle protein synthesis", "Glycogen restocking"]),
            FastingStage(stageNumber: 2, title: "Early Fasting State", timeRange: "4-\(Int(ketosisStart))h", startHour: 4, endHour: ketosisStart, biologicalAction: "Burning Glycogen", description: "Insulin levels drop, and blood sugar normalizes. The body starts pulling glycogen from the liver.", benefits: ["Stabilized blood sugar", "Lowered insulin levels"]),
            FastingStage(stageNumber: 3, title: "Ketosis / Fat Burning Zone", timeRange: "\(Int(ketosisStart))-\(Int(autophagyStart))h", startHour: ketosisStart, endHour: autophagyStart, biologicalAction: "Producing Ketones", description: "Liver glycogen is significantly depleted. The body ramps up lipolysis, breaking down body fat into ketones.", benefits: ["Accelerated fat loss", "Mental clarity and focus", "Reduced systemic inflammation"]),
            FastingStage(stageNumber: 4, title: "Autophagy & Anti-aging", timeRange: "\(Int(autophagyStart))-\(Int(t))h", startHour: autophagyStart, endHour: t, biologicalAction: "Cellular Recycling", description: "The body initiates a deep cellular recycling process. Old, damaged proteins, organelles, and senescent cells are broken down.", benefits: ["Cellular renewal", "Anti-aging effects", "Neurodegenerative protection"]),
            FastingStage(stageNumber: 5, title: "Immune Regeneration", timeRange: "\(Int(t))+h", startHour: t, endHour: 999, biologicalAction: "Stem Cell Rebirth", description: "Extended fasting leads to a significant drop in IGF-1 and PKA, signaling the body to generate fresh stem cells.", benefits: ["Immune system reset", "Deep metabolic healing", "Stem cell proliferation"])
        ]
    }
    
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
                                    
                                    // Dynamic hours is the max for the bar
                                    let progress = min(hours / targetHours, 1.0)
                                    
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
                                Text("\(Int(targetHours))h+")
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
                        ForEach(dynamicStages) { stage in
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
        return dynamicStages.first(where: { hours >= $0.startHour && hours < $0.endHour }) ?? dynamicStages.last!
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

// MARK: - Fasting Protocol Selection View
struct FastingProtocolOption: Identifiable {
    let id = UUID()
    let hours: Double
    let label: String
    let subtitle: String
    let description: String
    let color: Color
}

struct FastingProtocolSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Bindable var profile: UserProfile
    
    let protocols: [FastingProtocolOption] = [
        FastingProtocolOption(hours: 12.0, label: "12:12", subtitle: "Circadian Rhythm", description: "Align your eating window with your waking hours.", color: .orange),
        FastingProtocolOption(hours: 14.0, label: "14:10", subtitle: "Early Fasting", description: "A great entry point for fat adaptation.", color: .blue),
        FastingProtocolOption(hours: 16.0, label: "16:8", subtitle: "The Standard", description: "The most popular protocol for sustained fat loss.", color: FriendlyTheme.apexGreen),
        FastingProtocolOption(hours: 18.0, label: "18:6", subtitle: "Deep Ketosis", description: "Pushes the body deeper into fat burning.", color: .indigo),
        FastingProtocolOption(hours: 20.0, label: "20:4", subtitle: "Advanced Fasting", description: "Maximizes insulin sensitivity and fat loss.", color: .purple),
        FastingProtocolOption(hours: 21.0, label: "21:3", subtitle: "The Warrior Diet", description: "A highly resilient eating window.", color: Color(red: 0.3, green: 0.0, blue: 0.5)),
        FastingProtocolOption(hours: 23.0, label: "23:1", subtitle: "OMAD", description: "One Meal A Day. Ultimate metabolic reset.", color: .red)
    ]
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    Text("Select your target fasting window. This will automatically update your Fasting Hub stages.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                        .padding(.top, 24)
                    
                    ForEach(protocols) { option in
                        ProtocolCard(option: option, isSelected: profile.selectedFastingProtocol == option.hours) {
                            HapticManager.shared.light()
                            profile.selectedFastingProtocol = option.hours
                            try? modelContext.save()
                        }
                    }
                    
                    // Custom Protocol Button
                    Button(action: {
                        HapticManager.shared.light()
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom Protocol")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Set a personalized window")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(FriendlyTheme.textSecondary)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Fasting Protocol")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProtocolCard: View {
    let option: FastingProtocolOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(option.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Text(option.label)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(option.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.subtitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(option.description)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .font(.system(size: 24))
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? FriendlyTheme.apexGreen.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
}
