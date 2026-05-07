import SwiftUI
import CoreHaptics

@MainActor
class HapticManager {
    static let shared = HapticManager()
    private var engine: CHHapticEngine?
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
        
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics error: \(error)")
        }
    }
    
    func triggerFailure() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0.1, duration: 0.4)
        
        events.append(event1)
        events.append(event2)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error)")
        }
    }
    
    func heavy() {
        heavyGenerator.prepare()
        heavyGenerator.impactOccurred()
    }
    
    func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }
    
    func error() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.error)
    }
    
    func light() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred()
    }
    
    func medium() {
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred()
    }
    
    func rigid() {
        rigidGenerator.prepare()
        rigidGenerator.impactOccurred()
    }
}
