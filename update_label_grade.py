import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/TechnicalFoodLabelView.swift"
with open(path, "r") as f:
    content = f.read()

# Replace Grade A hardcode
old_grade = """                            VStack {
                                Text("Grade")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("A")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(FriendlyTheme.apexGreen)
                            }"""

new_grade = """                            if let grade = food.grade, !grade.isEmpty {
                                VStack {
                                    Text("Grade")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text(grade)
                                        .font(.system(size: 22, weight: .black, design: .rounded))
                                        .foregroundColor(grade == "A" || grade == "B" ? FriendlyTheme.apexGreen : (grade == "C" ? .yellow : .red))
                                }
                            }"""

content = content.replace(old_grade, new_grade)

with open(path, "w") as f:
    f.write(content)
