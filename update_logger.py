import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/FoodLoggerModal.swift"
with open(path, "r") as f:
    content = f.read()

# Replace TechnicalFoodLabelView with FoodActionSheetView
old = """            .sheet(item: $selectedFood) { food in
                TechnicalFoodLabelView(food: food) {
                    logFood(name: food.name, cal: Int(food.calories), pro: Int(food.protein), fat: Int(food.fat), carb: Int(food.carbs), sod: Int(food.sodium), pot: 0, mag: 0)
                }
            }"""

new = """            .sheet(item: $selectedFood) { food in
                FoodActionSheetView(food: food) { multiplier in
                    logFood(
                        name: food.name,
                        cal: Int(food.calories * multiplier),
                        pro: Int(food.protein * multiplier),
                        fat: Int(food.fat * multiplier),
                        carb: Int(food.carbs * multiplier),
                        sod: Int(food.sodium * multiplier),
                        pot: 0,
                        mag: 0
                    )
                }
            }"""

content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)
