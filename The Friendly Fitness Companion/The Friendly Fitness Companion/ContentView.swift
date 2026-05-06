import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1) // Midnight Matte
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1) // Apex Green
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0, green: 1, blue: 0, alpha: 1)]
        itemAppearance.normal.iconColor = UIColor.gray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            TabView(selection: $appState.selectedTab) {
            // 1. Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: "gauge.with.dots.needle.bottom.100percent")
                    Text("Dashboard")
                }
                .tag(0)
            
            // 2. Routines Tab
            RoutinesView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard.fill")
                    Text("Routines")
                }
                .tag(1)
            
            // 3. The Forge Tab
            ForgeLogbookView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("The Forge")
                }
                .tag(2)
            
            // 4. Progress Tab
            ProgressViewTab()
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Progress")
                }
                .tag(3)
            
            // 5. Tools Tab
            ToolsView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Tools")
                }
                .tag(4)
        }
        .preferredColorScheme(.dark)
        .accentColor(Color(red: 0, green: 1, blue: 0)) // Apex Green fallback
        }
    }
}

#Preview {
    ContentView()
}
