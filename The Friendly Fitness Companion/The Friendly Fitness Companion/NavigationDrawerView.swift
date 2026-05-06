import SwiftUI

struct NavigationDrawerView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    
                    Text("THE FORGE")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(4.0)
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 24)
                
                // Navigation Items
                VStack(alignment: .leading, spacing: 10) {
                    DrawerItemView(icon: "dumbbell.fill", title: "THE FORGE (LIVE)", isSelected: appState.selectedTab == 10) {
                        appState.selectedTab = 10
                        withAnimation { appState.isDrawerOpen = false }
                    }
                    
                    DrawerItemView(icon: "list.bullet.clipboard.fill", title: "PROGRAM BUILDER", isSelected: appState.selectedTab == 11) {
                        appState.selectedTab = 11
                        withAnimation { appState.isDrawerOpen = false }
                    }
                    
                    DrawerItemView(icon: "chart.xyaxis.line", title: "TECHNICAL REPORTS", isSelected: appState.selectedTab == 12) {
                        appState.selectedTab = 12
                        withAnimation { appState.isDrawerOpen = false }
                    }
                }
                
                Spacer()
                
                // Footer
                Text("ORIGIN INTL BOUTIQUE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .frame(width: 280)
            .background(FriendlyTheme.midnightMatte)
            .ignoresSafeArea()
            
            Spacer()
        }
    }
}

struct DrawerItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1.0)
                Spacer()
            }
            .foregroundColor(isSelected ? FriendlyTheme.apexGreen : .white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(isSelected ? FriendlyTheme.apexGreen.opacity(0.1) : Color.clear)
        }
    }
}
