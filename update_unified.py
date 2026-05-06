import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/FoodActionSheetView.swift"
with open(path, "r") as f:
    content = f.read()

content = content.replace("var isVerified: Bool = false\n}", "var isVerified: Bool = false\n    var servingSize: String? = \"1 serving (100g)\"\n}")

with open(path, "w") as f:
    f.write(content)

path2 = "The Friendly Fitness Companion/The Friendly Fitness Companion/ManageMyFoodsView.swift"
with open(path2, "r") as f:
    content2 = f.read()

content2 = content2.replace(
    "UnifiedFoodItem(name: result.name, brand: result.brand, calories: result.calories, protein: result.protein, fat: result.fat, carbs: result.carbs, sodium: result.sodium, isVerified: true)",
    "UnifiedFoodItem(name: result.name, brand: result.brand, calories: result.calories, protein: result.protein, fat: result.fat, carbs: result.carbs, sodium: result.sodium, isVerified: true, servingSize: result.servingSize)"
)

with open(path2, "w") as f:
    f.write(content2)

