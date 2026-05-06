import SwiftUI
import SwiftData

struct SupplementVaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplementItems: [SupplementItem]
    @Query private var dailyLogs: [DailyLog]
    
    @State private var showAddSupplement = false
    @State private var newName = ""
    @State private var newSodium = ""
    @State private var newPotassium = ""
    @State private var newMagnesium = ""
    
    var todayLog: DailyLog? {
        let calendar = Calendar.current
        return dailyLogs.first { calendar.isDateInToday($0.date) }
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    if supplementItems.isEmpty {
                        Text("No supplements added. Build your bio-stack.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(supplementItems) { item in
                            SupplementCard(item: item, todayLog: todayLog)
                        }
                    }
                    
                    Button(action: { showAddSupplement = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("ADD SUPPLEMENT")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(FriendlyTheme.apexGreen.opacity(0.1))
                        .foregroundColor(FriendlyTheme.apexGreen)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FriendlyTheme.apexGreen.opacity(0.5), lineWidth: 1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Supplement Vault")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSupplement) {
            NavigationView {
                ZStack {
                    FriendlyTheme.midnightMatte.ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SUPPLEMENT NAME")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(FriendlyTheme.textSecondary)
                            TextField("e.g. Redmond Real Salt", text: $newName)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 16) {
                            ElectrolyteInput(label: "Sodium (mg)", text: $newSodium)
                            ElectrolyteInput(label: "Potassium (mg)", text: $newPotassium)
                            ElectrolyteInput(label: "Magnesium (mg)", text: $newMagnesium)
                        }
                        
                        Spacer()
                        
                        Button(action: saveSupplement) {
                            Text("SAVE TO STACK")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(2.0)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(FriendlyTheme.apexGreen)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                }
                .navigationTitle("New Supplement")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { showAddSupplement = false }
                            .foregroundColor(FriendlyTheme.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            if todayLog == nil {
                let newLog = DailyLog()
                modelContext.insert(newLog)
                try? modelContext.save()
            }
        }
    }
    
    private func saveSupplement() {
        let sodium = Int(newSodium) ?? 0
        let potassium = Int(newPotassium) ?? 0
        let magnesium = Int(newMagnesium) ?? 0
        
        guard !newName.isEmpty else { return }
        
        let item = SupplementItem(name: newName, sodiumMg: sodium, potassiumMg: potassium, magnesiumMg: magnesium)
        modelContext.insert(item)
        try? modelContext.save()
        
        newName = ""
        newSodium = ""
        newPotassium = ""
        newMagnesium = ""
        showAddSupplement = false
        HapticManager.shared.success()
    }
}

struct ElectrolyteInput: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
    }
}

struct SupplementCard: View {
    @Environment(\.modelContext) private var modelContext
    let item: SupplementItem
    let todayLog: DailyLog?
    
    var todaySupplementLog: SupplementLog? {
        todayLog?.supplementLogs.first { $0.supplementItem?.id == item.id }
    }
    
    var isCompleted: Bool {
        todaySupplementLog?.isCompleted ?? false
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    if item.sodiumMg > 0 {
                        Text("Na: \(item.sodiumMg)mg")
                    }
                    if item.potassiumMg > 0 {
                        Text("K: \(item.potassiumMg)mg")
                    }
                    if item.magnesiumMg > 0 {
                        Text("Mg: \(item.magnesiumMg)mg")
                    }
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: toggleCompletion) {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? FriendlyTheme.apexGreen : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Circle()
                            .fill(FriendlyTheme.apexGreen.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(FriendlyTheme.apexGreen)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isCompleted ? FriendlyTheme.apexGreen.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func toggleCompletion() {
        HapticManager.shared.light()
        
        guard let todayLog = todayLog else { return }
        
        if let existingLog = todaySupplementLog {
            existingLog.isCompleted.toggle()
        } else {
            let newLog = SupplementLog(isCompleted: true, timestamp: Date())
            newLog.supplementItem = item
            newLog.dailyLog = todayLog
            modelContext.insert(newLog)
            todayLog.supplementLogs.append(newLog)
        }
        
        try? modelContext.save()
    }
}
