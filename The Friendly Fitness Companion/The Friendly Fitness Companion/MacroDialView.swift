import SwiftUI

struct MacroDialView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    
    @State private var dragOffset: CGFloat = 0
    @State private var lastHapticValue: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(FriendlyTheme.textSecondary)
            
            GeometryReader { _ in
                
                ZStack {
                    // Tick marks
                    HStack(spacing: 12) {
                        ForEach(-50..<50, id: \.self) { i in
                            Rectangle()
                                .fill(i % 5 == 0 ? .white : Color.white.opacity(0.3))
                                .frame(width: 2, height: i % 5 == 0 ? 24 : 12)
                        }
                    }
                    .offset(x: (CGFloat(value.truncatingRemainder(dividingBy: step * 10)) / CGFloat(step * 10)) * -140)
                    .offset(x: dragOffset)
                    
                    // Center indicator
                    Rectangle()
                        .fill(FriendlyTheme.apexGreen)
                        .frame(width: 4, height: 40)
                        .cornerRadius(2)
                        .shadow(color: FriendlyTheme.apexGreen, radius: 4, x: 0, y: 0)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let sensitivity: Double = 0.5
                            let rawChange = -Double(gesture.translation.width) * sensitivity * step
                            let newValue = min(max(value + rawChange, range.lowerBound), range.upperBound)
                            
                            // Trigger haptics
                            if abs(newValue - lastHapticValue) >= step {
                                let stepsTaken = Int(round(newValue / step))
                                if stepsTaken % 5 == 0 {
                                    HapticManager.shared.medium()
                                } else {
                                    HapticManager.shared.light()
                                }
                                lastHapticValue = newValue
                            }
                            
                            value = newValue
                            dragOffset = gesture.translation.width.truncatingRemainder(dividingBy: 14)
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                            // Snap to nearest step
                            value = round(value / step) * step
                        }
                )
            }
            .frame(height: 60)
            .background(FriendlyTheme.midnightMatteLight)
            .cornerRadius(20)
        }
    }
}
