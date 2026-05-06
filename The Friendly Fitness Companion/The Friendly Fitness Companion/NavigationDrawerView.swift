import SwiftUI
import SwiftData

struct NavigationDrawerView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @Query private var dailyLogs: [DailyLog]
    @Query private var routines: [RoutineTemplate]
    @Query private var allWorkouts: [WorkoutEntry]
    
    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let tab: Int
    }
    
    private var searchResults: [SearchResult] {
        var results: [SearchResult] = []
        let query = searchText.lowercased()
        
        if query.isEmpty { return results }
        
        // Match Workouts
        for w in allWorkouts where w.exerciseName.lowercased().contains(query) {
            results.append(SearchResult(title: w.exerciseName, subtitle: "Logged on \(w.timestamp.formatted(date: .abbreviated, time: .omitted))", tab: 12))
        }
        
        // Match Routines
        for r in routines where r.name.lowercased().contains(query) {
            results.append(SearchResult(title: r.name, subtitle: "Program Builder", tab: 11))
        }
        
        // Match Food/Weight in DailyLogs
        for l in dailyLogs {
            for food in l.foodEntries where food.name.lowercased().contains(query) {
                results.append(SearchResult(title: food.name, subtitle: "Food on \(l.date.formatted(date: .abbreviated, time: .omitted))", tab: 0))
            }
        }
        
        return results
    }
    
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
                .padding(.horizontal, 24)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(FriendlyTheme.textSecondary)
                    TextField("Search Command Center...", text: $searchText)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                if !searchText.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(searchResults) { result in
                                Button(action: {
                                    appState.selectedTab = result.tab
                                    withAnimation { appState.isDrawerOpen = false }
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text(result.subtitle)
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundColor(FriendlyTheme.apexGreen)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                }
                            }
                            if searchResults.isEmpty {
                                Text("No results found.")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                } else {
                    // Navigation Items
                    VStack(alignment: .leading, spacing: 10) {
                        DrawerItemView(icon: "dumbbell.fill", title: "THE FORGE (LIVE)", isSelected: appState.selectedTab == 10) {
                            appState.selectedTab = 10
                            withAnimation { appState.isDrawerOpen = false }
                        }
                        
                        DrawerItemView(icon: "book.pages.fill", title: "TRAINING LEDGER", isSelected: appState.selectedTab == 14) {
                            appState.selectedTab = 14
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
                        
                        DrawerItemView(icon: "flame.fill", title: "FASTING HUB", isSelected: appState.selectedTab == 13) {
                            appState.selectedTab = 13
                            withAnimation { appState.isDrawerOpen = false }
                        }
                    }
                    
                    Spacer()
                }
                
                // Footer
                Text("THE FRIENDLY FITNESS COMPANION")
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
