import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
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
        TabView(selection: $selectedTab) {
            // 1. Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: "gauge.with.dots.needle.bottom.100percent")
                    Text("Dashboard")
                }
                .tag(0)
            
            // 2. The Forge Tab
            ForgeLogbookView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("The Forge")
                }
                .tag(1)
            
            // 3. Progress Tab
            ProgressViewTab()
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Progress")
                }
                .tag(2)
        }
        .preferredColorScheme(.dark)
        .accentColor(Color(red: 0, green: 1, blue: 0)) // Apex Green fallback
    }
}

#Preview {
    ContentView()
}
