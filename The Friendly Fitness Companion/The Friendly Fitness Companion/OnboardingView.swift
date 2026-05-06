import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("preferredUnit") private var preferredUnit: String = "lbs"
    
    @State private var currentStep: Int = 0
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            FriendlyTheme.midnightMatte.ignoresSafeArea()
            
            if currentStep == 0 {
                // Logo slow-fade
                VStack(spacing: 16) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("ORIGIN INTL BOUTIQUE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(4.0)
                        .foregroundColor(.white)
                    
                    Text("THE FORGE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(FriendlyTheme.textSecondary)
                }
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 2.0)) {
                        logoOpacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            currentStep = 1
                        }
                    }
                }
            } else if currentStep == 1 {
                // Philosophy
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("PRECISION IS EVERYTHING.")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .tracking(3.0)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("The Forge is a high-density, enterprise-grade utility built around the principles of Heavy Duty intensity and progressive overload.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(FriendlyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation { currentStep = 2 }
                    }) {
                        Text("CONTINUE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            } else if currentStep == 2 {
                // Profile Setup
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("SYSTEM SETUP")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .tracking(3.0)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PREFERRED UNIT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        HStack(spacing: 16) {
                            Button(action: { preferredUnit = "lbs" }) {
                                Text("LBS")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(preferredUnit == "lbs" ? FriendlyTheme.apexGreen : Color.white.opacity(0.1))
                                    .foregroundColor(preferredUnit == "lbs" ? .black : .white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { preferredUnit = "kg" }) {
                                Text("KG")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(preferredUnit == "kg" ? FriendlyTheme.apexGreen : Color.white.opacity(0.1))
                                    .foregroundColor(preferredUnit == "kg" ? .black : .white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GLOBAL SYNC")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(FriendlyTheme.textSecondary)
                        
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .foregroundColor(FriendlyTheme.apexGreen)
                            Text("CloudKit Sync Enabled")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(FriendlyTheme.apexGreen)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        withAnimation { hasCompletedOnboarding = true }
                    }) {
                        Text("ENTER COMMAND CENTER")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2.0)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FriendlyTheme.apexGreen)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}
