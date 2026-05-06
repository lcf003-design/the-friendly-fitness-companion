import SwiftUI

struct HealthDataSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var visibleMarkers: [HealthMarkerType]
    @AppStorage("visibleHealthMarkers") private var visibleMarkersData: Data = Data()
    
    @State private var localMarkers: [HealthMarkerType] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                List {
                    Section {
                        ForEach(localMarkers, id: \.self) { marker in
                            HStack {
                                Text(marker.displayName)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                
                                Spacer()
                                
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        .onMove(perform: moveMarker)
                        .onDelete(perform: deleteMarker)
                    } header: {
                        Text("ACTIVE MARKERS")
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.0)
                    }
                    
                    let inactive = HealthMarkerType.allCases.filter { !localMarkers.contains($0) }
                    if !inactive.isEmpty {
                        Section {
                            ForEach(inactive, id: \.self) { marker in
                                Button(action: {
                                    withAnimation {
                                        localMarkers.append(marker)
                                    }
                                }) {
                                    HStack {
                                        Text(marker.displayName)
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                        } header: {
                            Text("INACTIVE MARKERS")
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1.0)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Select Health Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FriendlyTheme.apexGreen)
                }
            }
        }
        .onAppear {
            localMarkers = visibleMarkers
        }
    }
    
    private func moveMarker(from source: IndexSet, to destination: Int) {
        localMarkers.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteMarker(at offsets: IndexSet) {
        localMarkers.remove(atOffsets: offsets)
    }
    
    private func savePreferences() {
        visibleMarkers = localMarkers
        if let encoded = try? JSONEncoder().encode(localMarkers) {
            visibleMarkersData = encoded
        }
    }
}
