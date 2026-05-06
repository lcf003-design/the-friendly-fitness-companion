import SwiftUI
import SwiftData
import Combine

struct ComingSoonView: View {
    let title: String
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            VStack {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 60))
                    .foregroundColor(FriendlyTheme.textSecondary.opacity(0.3))
                Text(title.uppercased())
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(4.0)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                Text("COMING SOON")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(FriendlyTheme.apexGreen)
                    .padding(.top, 8)
            }
        }
    }
}

struct TabBarItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? FriendlyTheme.apexGreen : FriendlyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showShortcuts = false
    @State private var isPulsing = false
    @State private var currentDurationString = "00:00"
    
    let liveTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            ZStack(alignment: .leading) {
                ZStack(alignment: .bottom) {
                    // Main Content
                    Group {
                        switch appState.selectedTab {
                        case 0: DashboardView()
                        case 1: ToolsView()
                        case 2: DashboardView() // Center + Visual Only placeholder
                        case 3: CommunityView()
                        case 4: MeView()
                        // Drawer Navigation
                        case 10: ForgeLogbookView()
                        case 11: RoutinesView()
                        case 12: ProgressViewTab()
                        case 13: FastingHubView()
                        default: DashboardView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom Tab Bar Overlay
                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 0) {
                            TabBarItemView(icon: "chart.bar.fill", title: "Dashboard", isSelected: appState.selectedTab == 0) {
                                appState.selectedTab = 0
                            }
                            
                            TabBarItemView(icon: "wrench.and.screwdriver.fill", title: "Tools", isSelected: appState.selectedTab == 1) {
                                appState.selectedTab = 1
                            }
                            
                            // Center +
                            Button(action: {
                                HapticManager.shared.medium()
                                showShortcuts = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundColor(.black)
                                    .frame(width: 56, height: 56)
                                    .background(FriendlyTheme.apexGreen)
                                    .clipShape(Circle())
                                    .shadow(color: FriendlyTheme.apexGreen.opacity(0.3), radius: 10, y: 5)
                            }
                            .offset(y: -15)
                            .frame(maxWidth: .infinity)
                            
                            TabBarItemView(icon: "person.2.fill", title: "Community", isSelected: appState.selectedTab == 3) {
                                appState.selectedTab = 3
                            }
                            
                            TabBarItemView(icon: "person.circle.fill", title: "Me", isSelected: appState.selectedTab == 4) {
                                appState.selectedTab = 4
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                        .background(
                            FriendlyTheme.midnightMatte
                                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1)), alignment: .top)
                                .ignoresSafeArea(edges: .bottom)
                        )
                    }
                }
                
                // Navigation Drawer Overlay
                if appState.isDrawerOpen {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { appState.isDrawerOpen = false }
                        }
                    
                    NavigationDrawerView()
                        .transition(.move(edge: .leading))
                }
                
                // Active Session Indicator (Elite Status)
                if appState.isWorkoutActive && !appState.showLiveForge {
                    VStack {
                        HStack {
                            Circle()
                                .fill(FriendlyTheme.apexGreen)
                                .frame(width: 8, height: 8)
                                .opacity(isPulsing ? 1.0 : 0.3)
                            
                            Text("ACTIVE SESSION")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(2.0)
                                .foregroundColor(FriendlyTheme.apexGreen)
                            
                            Spacer()
                            
                            Text(currentDurationString)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(FriendlyTheme.midnightMatteLight)
                        .cornerRadius(20)
                        .padding(.horizontal, 24)
                        .padding(.top, 50)
                        .onTapGesture {
                            appState.showLiveForge = true
                        }
                        Spacer()
                    }
                    .zIndex(100)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onReceive(liveTimer) { _ in
                if appState.isWorkoutActive, let start = appState.workoutStartTime {
                    let interval = Date().timeIntervalSince(start)
                    let hours = Int(interval) / 3600
                    let minutes = Int(interval) / 60 % 60
                    let seconds = Int(interval) % 60
                    if hours > 0 {
                        currentDurationString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                    } else {
                        currentDurationString = String(format: "%02d:%02d", minutes, seconds)
                    }
                }
            }
            .sheet(isPresented: $showShortcuts) {
                ShortcutsMenuSheet()
                    .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $appState.showLiveForge) {
                ForgeSessionView()
            }
        }
    }
}

#Preview {
    ContentView()
}
