import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/NutritionAPIManager.swift"
with open(path, "r") as f:
    content = f.read()

# Update APIFoodItem struct
content = content.replace("let imageUrl: String?\n}", "let imageUrl: String?\n    var servingSize: String? = \"100g\"\n}")

# Update User-Agent request
request_replacement = """        var request = URLRequest(url: url)
        request.setValue("FriendlyFitnessApp/1.0 (contact@friendlyfitness.app)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in"""
content = content.replace("URLSession.shared.dataTask(with: url) { data, response, error in", request_replacement)

# Update JSON parsing
parsing_old = """                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
                        
                        let calories = nutriments["energy-kcal_100g"] as? Double ?? 0.0
                        let protein = nutriments["proteins_100g"] as? Double ?? 0.0
                        let fat = nutriments["fat_100g"] as? Double ?? 0.0
                        let carbs = nutriments["carbohydrates_100g"] as? Double ?? 0.0
                        let sodium = nutriments["sodium_100g"] as? Double ?? 0.0 // mostly in g, OFF reports in g usually, sodium_100g is often grams
                        
                        let item = APIFoodItem(
                            name: name,
                            brand: brand,
                            calories: calories,
                            protein: protein,
                            fat: fat,
                            carbs: carbs,
                            sodium: sodium * 1000, // convert g to mg
                            imageUrl: imageUrl
                        )"""

parsing_new = """                        let rawServingSize = product["serving_size"] as? String
                        
                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
                        
                        let hasServing = nutriments["energy-kcal_serving"] != nil
                        let suffix = hasServing ? "_serving" : "_100g"
                        let finalServingSize = hasServing ? (rawServingSize ?? "1 serving") : "100g"
                        
                        let calories = nutriments["energy-kcal" + suffix] as? Double ?? 0.0
                        let protein = nutriments["proteins" + suffix] as? Double ?? 0.0
                        let fat = nutriments["fat" + suffix] as? Double ?? 0.0
                        let carbs = nutriments["carbohydrates" + suffix] as? Double ?? 0.0
                        let sodium = nutriments["sodium" + suffix] as? Double ?? 0.0
                        
                        let item = APIFoodItem(
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
content = content.replace(parsing_old, parsing_new)

with open(path, "w") as f:
    f.write(content)
