import SwiftUI
import SwiftData
import PhotosUI

struct ProgressPhotosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProgressPhoto.timestamp, order: .reverse) private var photos: [ProgressPhoto]
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedCategory: String = "Front"
    let categories = ["Front", "Side", "Back"]
    
    @State private var showCompare: Bool = false
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                let filteredPhotos = photos.filter { $0.category == selectedCategory }
                
                if filteredPhotos.isEmpty {
                    Spacer()
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(FriendlyTheme.textSecondary.opacity(0.3))
                        .padding(.bottom, 8)
                    Text("NO PHOTOS YET")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                            ForEach(filteredPhotos) { photo in
                                if let uiImage = UIImage(data: photo.imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 200)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Text(formatDate(photo.timestamp))
                                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                                        .padding(4)
                                                        .background(Color.black.opacity(0.6))
                                                        .foregroundColor(.white)
                                                        .cornerRadius(4)
                                                    Spacer()
                                                }
                                                .padding(8)
                                            }
                                        )
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                modelContext.delete(photo)
                                                try? modelContext.save()
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("ADD PHOTO")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2.0)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FriendlyTheme.apexGreen)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .onChange(of: selectedItem) { _, _ in
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                let photo = ProgressPhoto(category: selectedCategory, imageData: data)
                                modelContext.insert(photo)
                                try? modelContext.save()
                                selectedItem = nil
                            }
                        }
                    }
                    
                    Button(action: { showCompare = true }) {
                        HStack {
                            Image(systemName: "arrow.left.and.right.square.fill")
                            Text("COMPARE")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2.0)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Padding for tab bar
            }
        }
        .navigationTitle("GALLERY")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCompare) {
            ProgressCompareView(photos: photos)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct ProgressCompareView: View {
    @Environment(\.dismiss) var dismiss
    let photos: [ProgressPhoto]
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    @State private var leftPhotoId: UUID?
    @State private var rightPhotoId: UUID?
    @State private var selectedCategory: String = "Front"
    
    @Query private var dailyLogs: [DailyLog]
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                VStack {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(["Front", "Side", "Back"], id: \.self) { Text($0) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    let categoryPhotos = photos.filter { $0.category == selectedCategory }
                    
                    HStack(spacing: 8) {
                        // Left Side
                        VStack {
                            Menu {
                                ForEach(categoryPhotos) { p in
                                    Button(formatDate(p.timestamp)) { leftPhotoId = p.id }
                                }
                            } label: {
                                HStack {
                                    Text("Select Date")
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .padding()
                            }
                            
                            if let leftId = leftPhotoId, let photo = categoryPhotos.first(where: { $0.id == leftId }), let uiImage = UIImage(data: photo.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .overlay(
                                        weightOverlay(for: photo.timestamp), alignment: .bottom
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            }
                        }
                        
                        // Right Side
                        VStack {
                            Menu {
                                ForEach(categoryPhotos) { p in
                                    Button(formatDate(p.timestamp)) { rightPhotoId = p.id }
                                }
                            } label: {
                                HStack {
                                    Text("Select Date")
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .padding()
                            }
                            
                            if let rightId = rightPhotoId, let photo = categoryPhotos.first(where: { $0.id == rightId }), let uiImage = UIImage(data: photo.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .overlay(
                                        weightOverlay(for: photo.timestamp), alignment: .bottom
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("COMPARE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(FriendlyTheme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func weightOverlay(for date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        
        let log = dailyLogs.first { $0.id == dateStr }
        let measurement = log?.bodyMeasurements.first
        
        let bodyWeight = measurement?.bodyWeight
        let bodyFat = measurement?.bodyFatPercentage
        
        return VStack(spacing: 4) {
            Text(formatDate(date))
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(1.0)
            
            if let bw = bodyWeight {
                Text("\(String(format: "%.1f", bw)) \(preferredUnit)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.limeSignal)
            }
            if let bf = bodyFat {
                Text("\(String(format: "%.1f", bf))% BF")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
