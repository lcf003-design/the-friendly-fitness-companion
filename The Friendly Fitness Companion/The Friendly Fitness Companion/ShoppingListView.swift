import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingItem.createdAt) private var items: [ShoppingItem]
    
    @State private var newItemName: String = ""
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Input Field
                HStack {
                    TextField("Add new item...", text: $newItemName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    Button(action: addItem) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(16)
                            .background(FriendlyTheme.apexGreen)
                            .cornerRadius(12)
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
                .padding(24)
                
                // List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                item.isChecked.toggle()
                                try? modelContext.save()
                            }) {
                                HStack {
                                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isChecked ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary)
                                        .font(.system(size: 24))
                                    
                                    Text(item.name.uppercased())
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .tracking(2.0)
                                        .foregroundColor(item.isChecked ? FriendlyTheme.textSecondary : .white)
                                        .strikethrough(item.isChecked, color: FriendlyTheme.textSecondary)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .cornerRadius(12)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(item)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("SHOPPING LIST")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newItem = ShoppingItem(name: trimmed)
        modelContext.insert(newItem)
        try? modelContext.save()
        
        newItemName = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
