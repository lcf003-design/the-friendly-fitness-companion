import SwiftUI

struct IntensityShareGraphic: View {
    var exerciseName: String
    var intensityAdjustedLoad: String
    var machineBrand: String
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Hexagon Logo Watermark
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 150))
                    .foregroundColor(Color.white.opacity(0.05))
                    .padding(.bottom, 60)
                
                Text("THE FORGE")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(6.0)
                    .foregroundColor(FriendlyTheme.textSecondary)
                
                Text(exerciseName.uppercased())
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.horizontal, 40)
                
                Text(machineBrand.uppercased())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(FriendlyTheme.textSecondary)
                    .padding(.top, 10)
                
                VStack(spacing: 10) {
                    Text("1RM EFFORT")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(3.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                    
                    Text(intensityAdjustedLoad)
                        .font(.system(size: 100, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                Spacer()
                
                Text("HEAVY DUTY CERTIFIED")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(4.0)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(FriendlyTheme.limeSignal)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                    .padding(.bottom, 100)
            }
        }
        .frame(width: 1080, height: 1920) // Story Size
    }
}

@MainActor
class IntensityShareGenerator {
    static func generateImage(exerciseName: String, load: String, brand: String) -> Image? {
        let view = IntensityShareGraphic(exerciseName: exerciseName, intensityAdjustedLoad: load, machineBrand: brand)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        
        if let cgImage = renderer.cgImage {
            return Image(cgImage, scale: 1.0, label: Text("Share Graphic"))
        }
        return nil
    }
}
