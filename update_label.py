import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/TechnicalFoodLabelView.swift"
with open(path, "r") as f:
    content = f.read()

# Add onLog callback
content = content.replace("let food: UnifiedFoodItem\n    @Environment", "let food: UnifiedFoodItem\n    var onLog: (() -> Void)? = nil\n    @Environment")

# Add Log button before Spacer
log_btn = """                        
                        if let onLog = onLog {
                            Button(action: {
                                onLog()
                                dismiss()
                            }) {
                                Text("LOG FOOD")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(FriendlyTheme.apexGreen)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        
                        Spacer(minLength: 40)"""
content = content.replace("Spacer(minLength: 40)", log_btn)

with open(path, "w") as f:
    f.write(content)
