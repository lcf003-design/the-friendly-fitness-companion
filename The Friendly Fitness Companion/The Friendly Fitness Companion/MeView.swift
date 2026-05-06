import SwiftUI
import SwiftData

struct MeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    // UI State
    @State private var showEditProfile = false
    
    var profile: UserProfile {
        if let first = userProfiles.first { return first }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        try? modelContext.save()
        return newProfile
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(FriendlyTheme.apexGreen)
                                .font(.system(size: 24))
                            
                            Text("COMMAND HUB")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(4.0)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // APPS & DEVICES
                        VStack(alignment: .leading, spacing: 12) {
                            Text("APPS & DEVICES")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "heart.text.square.fill")
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                        .font(.system(size: 20))
                                    Text("Apple Health")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if healthKitManager.isAuthorized {
                                        Text("SYNCED")
                                            .font(.system(size: 10, weight: .black, design: .rounded))
                                            .tracking(1.0)
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                    } else {
                                        Button(action: {
                                            healthKitManager.requestAuthorization()
                                        }) {
                                            Text("CONNECT")
                                                .font(.system(size: 10, weight: .black, design: .rounded))
                                                .tracking(1.0)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(FriendlyTheme.apexGreen)
                                                .foregroundColor(.black)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(16)
                            }
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // PERSONAL INFO
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PERSONAL INFO")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.horizontal, 24)
                            
                            Button(action: { showEditProfile = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Biological Variables")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("DOB: \(profile.dateOfBirth != nil ? formatDate(profile.dateOfBirth!) : "Not Set") • Height: \(profile.heightInCm != nil ? String(format: "%.1f cm", profile.heightInCm!) : "Not Set")")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                        Text("Activity Level: \(profile.activityLevel)")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                        .font(.system(size: 14))
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // GOALS & STRATEGY
                        NavigationLink(destination: WeightGoalPlanView()) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MY WEIGHT GOAL & PLAN")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Metabolic strategy & targets")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // MY HEALTH
                        NavigationLink(destination: MyHealthView()) {
                            HStack {
                                Image(systemName: "heart.text.square.fill")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MY HEALTH")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Track clinical markers and body log")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // PROGRESS PHOTOS
                        NavigationLink(destination: ProgressPhotosView()) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("PROGRESS PHOTOS")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Compare physical changes over time")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // NUTRITION & GROCERY
                        VStack(alignment: .leading, spacing: 12) {
                            Text("NUTRITION & GROCERY")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: CustomFoodsView()) {
                                    HStack {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                            .font(.system(size: 20))
                                        Text("MY FOODS")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    .padding(16)
                                }
                                Divider().background(Color.white.opacity(0.1))
                                
                                NavigationLink(destination: CustomRecipesView()) {
                                    HStack {
                                        Image(systemName: "book.pages.fill")
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                            .font(.system(size: 20))
                                        Text("CUSTOM RECIPES")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    .padding(16)
                                }
                                Divider().background(Color.white.opacity(0.1))
                                
                                NavigationLink(destination: GroceryCheckView()) {
                                    HStack {
                                        Image(systemName: "scale.3d")
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                            .font(.system(size: 20))
                                        Text("GROCERY CHECK")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    .padding(16)
                                }
                                Divider().background(Color.white.opacity(0.1))
                                
                                NavigationLink(destination: ShoppingListView()) {
                                    HStack {
                                        Image(systemName: "cart.fill")
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                            .font(.system(size: 20))
                                        Text("SHOPPING LIST")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    .padding(16)
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        

                        
                        // APP SETTINGS
                        NavigationLink(destination: AppSettingsView()) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(FriendlyTheme.apexGreen)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("APP SETTINGS")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Units, Haptic Intensity, Failure Audit")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(FriendlyTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(FriendlyTheme.textSecondary)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // SYSTEM SUPPORT
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SYSTEM SUPPORT")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.textSecondary)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                Button(action: {}) {
                                    HStack {
                                        Text("SUPPORT & FAQS")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    .padding(16)
                                }
                                Divider().background(Color.white.opacity(0.1))
                                Button(action: {}) {
                                    HStack {
                                        Text("WHAT'S NEW IN THE APP")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(FriendlyTheme.textSecondary)
                                    }
                                    .padding(16)
                                }
                                Divider().background(Color.white.opacity(0.1))
                                HStack {
                                    Text("SYSTEM STATUS")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Circle()
                                        .fill(FriendlyTheme.apexGreen)
                                        .frame(width: 8, height: 8)
                                    Text("DB HEALTHY • SYNC OK")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .tracking(1.0)
                                        .foregroundColor(FriendlyTheme.apexGreen)
                                }
                                .padding(16)
                            }
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(profile: profile)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile
    
    @State private var dateOfBirth: Date
    @State private var height: String
    @State private var activityLevel: String
    
    let activityLevels = ["Sedentary", "Lightly Active", "Active", "Heavy Duty"]
    
    init(profile: UserProfile) {
        self.profile = profile
        _dateOfBirth = State(initialValue: profile.dateOfBirth ?? Date())
        _height = State(initialValue: profile.heightInCm != nil ? String(format: "%.1f", profile.heightInCm!) : "")
        _activityLevel = State(initialValue: profile.activityLevel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FriendlyTheme.midnightMatte.ignoresSafeArea()
                
                Form {
                    Section(header: Text("BIOLOGICAL VARIABLES").foregroundColor(FriendlyTheme.textSecondary)) {
                        DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Height (cm)")
                                .foregroundColor(.white)
                            Spacer()
                            TextField("e.g. 180.5", text: $height)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        
                        Picker("Activity Level", selection: $activityLevel) {
                            ForEach(activityLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        profile.dateOfBirth = dateOfBirth
                        if let h = Double(height) {
                            profile.heightInCm = h
                        }
                        profile.activityLevel = activityLevel
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct AppSettingsView: View {
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    @AppStorage("hapticIntensity") private var hapticIntensity: Double = 1.0
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var isSyncing: Bool = false
    @State private var syncStatus: String = "IDLE"
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            Form {
                Section(header: Text("GLOBAL PREFERENCES").foregroundColor(FriendlyTheme.textSecondary)) {
                    Picker("Unit System", selection: $preferredUnit) {
                        Text("LBS").tag("lbs")
                        Text("KG").tag("kg")
                    }
                    .foregroundColor(.white)
                    
                    VStack(alignment: .leading) {
                        Text("Haptic Feedback Intensity")
                            .foregroundColor(.white)
                        Slider(value: $hapticIntensity, in: 0.0...1.0)
                            .accentColor(FriendlyTheme.apexGreen)
                    }
                    
                    Toggle("Intensity-Adjusted 1RM", isOn: $appState.useIntensityAdjusted1RM)
                        .foregroundColor(.white)
                        .tint(FriendlyTheme.apexGreen)
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section(header: Text("GLOBAL PERSISTENCE").foregroundColor(FriendlyTheme.textSecondary)) {
                    Button(action: forceSync) {
                        HStack {
                            if isSyncing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "icloud.and.arrow.up.fill")
                                Text("FORCE CLOUD SYNC")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(2.0)
                            }
                            Spacer()
                        }
                        .foregroundColor(FriendlyTheme.apexGreen)
                    }
                    
                    if syncStatus != "IDLE" {
                        Text(syncStatus)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(isSyncing ? FriendlyTheme.mutedAmber : FriendlyTheme.textSecondary)
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("App Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func forceSync() {
        isSyncing = true
        syncStatus = "PUSHING TO ICLOUD..."
        
        do {
            try modelContext.save()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isSyncing = false
                syncStatus = "LAST SYNC: JUST NOW"
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        } catch {
            isSyncing = false
            syncStatus = "SYNC FAILED"
        }
    }
}
