import SwiftUI
import SwiftData

struct RestaurantScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isScanning = true
    @State private var showResults = false
    @State private var laserOffset: CGFloat = -150
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            // Mock Camera Viewfinder Background
            Color.black.ignoresSafeArea()
            
            // Laser Animation
            if isScanning {
                Rectangle()
                    .fill(FriendlyTheme.apexGreen)
                    .frame(height: 2)
                    .shadow(color: FriendlyTheme.apexGreen, radius: 10, x: 0, y: 0)
                    .offset(y: laserOffset)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                            laserOffset = 150
                        }
                        
                        // Simulate analyzing progress
                        withAnimation(.linear(duration: 3.0)) {
                            progress = 1.0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation {
                                isScanning = false
                                showResults = true
                            }
                        }
                    }
                
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("ANALYZING MENU...")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(2.0)
                            .foregroundColor(FriendlyTheme.apexGreen)
                        
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 4)
                                
                                Rectangle()
                                    .fill(FriendlyTheme.apexGreen)
                                    .frame(width: proxy.size.width * progress, height: 4)
                            }
                        }
                        .frame(width: 200, height: 4)
                    }
                    .padding(.bottom, 60)
                }
            }
            
            // UI Overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                }
                Spacer()
            }
            
            if showResults {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        HStack {
                            Text("CARNIVORE-FRIENDLY OPTIONS")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundColor(FriendlyTheme.apexGreen)
                            Spacer()
                        }
                        .padding(24)
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                ScannedDishRow(name: "Ribeye Steak (16oz)", desc: "1100 kcal • 108g P • 75g F", isConfirmed: false)
                                ScannedDishRow(name: "Double Bacon Burger (No Bun)", desc: "850 kcal • 70g P • 60g F", isConfirmed: true)
                                ScannedDishRow(name: "Wild Caught Salmon", desc: "600 kcal • 55g P • 40g F", isConfirmed: false)
                            }
                            .padding(.horizontal, 24)
                        }
                        .frame(height: 300)
                    }
                    .background(FriendlyTheme.midnightMatte)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

struct ScannedDishRow: View {
    let name: String
    let desc: String
    @State var isConfirmed: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
            }
            Spacer()
            
            Button(action: {
                withAnimation { isConfirmed.toggle() }
                HapticManager.shared.success()
            }) {
                Text(isConfirmed ? "LOGGED" : "CONFIRM & LOG")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isConfirmed ? FriendlyTheme.apexGreen : Color.white.opacity(0.1))
                    .foregroundColor(isConfirmed ? .black : .white)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
