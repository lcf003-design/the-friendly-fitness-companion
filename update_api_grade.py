import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/NutritionAPIManager.swift"
with open(path, "r") as f:
    content = f.read()

# Update APIFoodItem
content = content.replace("var servingSize: String? = \"100g\"\n}", "var servingSize: String? = \"100g\"\n    var grade: String? = nil\n}")

# Update parsing logic
old_parse = """                        let item = APIFoodItem(
                            name: name,
                            brand: brand,
                            calories: calories,
                            protein: protein,
                            fat: fat,
                            carbs: carbs,
                            sodium: sodium * 1000, // convert g to mg
                            imageUrl: imageUrl,
                            servingSize: finalServingSize
                        )"""

new_parse = """                        let nutriscore = product["nutriscore_grade"] as? String
                        let grade = nutriscore?.uppercased()
                        let fullImageUrl = product["image_url"] as? String ?? imageUrl
                        
                        let item = APIFoodItem(
                            name: name,
                            brand: brand,
                            calories: calories,
                            protein: protein,
                            fat: fat,
                            carbs: carbs,
                            sodium: sodium * 1000, // convert g to mg
                            imageUrl: fullImageUrl,
                            servingSize: finalServingSize,
                            grade: grade == "UNKNOWN" ? nil : grade
                        )"""
content = content.replace(old_parse, new_parse)

# Update fallback data to include grade
content = content.replace("imageUrl: nil)", "imageUrl: nil, grade: \"A\")")

with open(path, "w") as f:
    f.write(content)
