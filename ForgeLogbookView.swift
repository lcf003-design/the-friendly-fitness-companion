import SwiftUI

struct ForgeLogbookView: View {
    @State private var exerciseName: String = "Incline Machine Press"
    @State private var weight: String = "225"
    @State private var reps: String = "8"
    @State private var rpe: Double = 8.0
    
    // Intensity Modifiers
    @State private var forcedReps: Bool = false
    @State private var negatives: Bool = false
    @State private var restPause: Bool = false
    @State private var restPauseTimer: Int = 15
    @State private var isTimerRunning: Bool = false
    
    // Calculated Henneman Recruitment
    var recruitmentPercentage: Double {
        // Base recruitment based on RPE (Proximity to failure)
        var base = min(rpe / 10.0, 0.90) // Caps at 90% without intensity techniques
        
        // Intensity modifiers give the final push to 100%
        if forcedReps { base += 0.05 }
        if negatives { base += 0.05 }
        if restPause { base += 0.05 }
        
        return min(base, 1.0)
    }
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(FriendlyTheme.apexGreen)
                        Text("THE FORGE")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Henneman Meter (Live Feedback)
                    HennemanMeterView(recruitmentLevel: recruitmentPercentage)
                        .padding(.top, -10)
                    
                    // Logging Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("CURRENT SET")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                            .tracking(1.5)
                        
                        // Exercise Name
                        TextField("Exercise Name", text: $exerciseName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        // Weight and Reps
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("WEIGHT (LBS)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("0", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("REPS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                TextField("0", text: $reps)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.vertical, 8)
                        
                        // RPE Slider
                        VStack(alignment: .leading) {
                            HStack {
                                Text("PROXIMITY TO FAILURE (RPE)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FriendlyTheme.textSecondary)
                                Spacer()
                                Text("\(Int(rpe)) / 10")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FriendlyTheme.limeSignal)
                            }
                            
                            Slider(value: $rpe, in: 1...10, step: 1)
                                .accentColor(FriendlyTheme.limeSignal)
                        }
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.vertical, 8)
                        
                        // Heavy Duty Modifiers
                        Text("HEAVY DUTY MODIFIERS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        HStack(spacing: 12) {
                            IntensityButton(title: "FORCED REPS", isSelected: $forcedReps)
                            IntensityButton(title: "NEGATIVES", isSelected: $negatives)
                        }
                        
                        // Rest-Pause Timer Button
                        Button(action: toggleRestPause) {
                            HStack {
                                Image(systemName: "timer")
                                Text(restPause ? (isTimerRunning ? "REST-PAUSE: \(restPauseTimer)s" : "REST-PAUSE LOGGED") : "REST-PAUSE")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(restPause ? FriendlyTheme.mutedAmber : FriendlyTheme.midnightMatte)
                            .foregroundColor(restPause ? FriendlyTheme.midnightMatte : FriendlyTheme.mutedAmber)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(FriendlyTheme.mutedAmber, lineWidth: restPause ? 0 : 2)
                            )
                        }
                    }
                    .padding(24)
                    .background(FriendlyTheme.midnightMatteLight)
                    .cornerRadius(30)
                    .padding(.horizontal, 20)
                    
                    // Log Set Button
                    Button(action: {
                        // Log logic here
                    }) {
                        Text("LOG SET")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.5)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func toggleRestPause() {
        if !restPause {
            restPause = true
            isTimerRunning = true
            restPauseTimer = 15
            startTimer()
        } else {
            restPause = false
            isTimerRunning = false
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !isTimerRunning || restPauseTimer <= 0 {
                isTimerRunning = false
                timer.invalidate()
            } else {
                restPauseTimer -= 1
            }
        }
    }
}

struct IntensityButton: View {
    var title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? FriendlyTheme.apexGreen : FriendlyTheme.midnightMatte)
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FriendlyTheme.apexGreen, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

struct ForgeLogbookView_Previews: PreviewProvider {
    static var previews: some View {
        ForgeLogbookView()
    }
}
