import Foundation

// MARK: - USDA FoodData Central Models
struct USDAResponse: Codable {
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let description: String?
    let ingredients: String?
    let foodNutrients: [USDANutrient]?
}

struct USDANutrient: Codable {
    let nutrientName: String?
    let value: Double?
    let unitName: String?
}

// MARK: - Clean App Model
struct FoodSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let fatGrams: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let tier: String // "Apex", "Ancestral", "Modern"
    let containsSeedOils: Bool
    let containsRefinedSugars: Bool
}

// MARK: - API Service
class NutritionAPIService {
    static let shared = NutritionAPIService()
    
    // We are using the public USDA DEMO_KEY. It allows 30-50 requests per hour.
    private let apiKey = "DEMO_KEY"
    
    func searchFood(query: String) async throws -> [FoodSearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(apiKey)&query=\(encodedQuery)&pageSize=10") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle rate limiting or server errors
        if httpResponse.statusCode != 200 {
            print("API Error: Status Code \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(USDAResponse.self, from: data)
        
        return decodedResponse.foods.compactMap { food in
            guard let name = food.description, !name.isEmpty else { return nil }
            
            // Extract Macros
            var fat = 0.0
            var protein = 0.0
            var carbs = 0.0
            
            if let nutrients = food.foodNutrients {
                for nutrient in nutrients {
                    let nName = nutrient.nutrientName?.lowercased() ?? ""
                    if nName.contains("protein") {
                        protein = nutrient.value ?? 0.0
                    } else if nName.contains("lipid (fat)") || nName.contains("total fat") {
                        fat = nutrient.value ?? 0.0
                    } else if nName.contains("carbohydrate") {
                        carbs = nutrient.value ?? 0.0
                    }
                }
            }
            
            let ingredientList = (food.ingredients ?? "").lowercased()
            
            // Scan for Hateful Eight & Sugars
            let hasSeedOils = FriendlyScanner.containsSeedOils(in: ingredientList)
            let hasSugars = FriendlyScanner.containsRefinedSugars(in: ingredientList)
            
            // Determine Tier
            let tier = FriendlyScanner.determineTier(hasSeedOils: hasSeedOils, hasSugars: hasSugars, ingredients: ingredientList)
            
            return FoodSearchResult(
                name: name.capitalized,
                fatGrams: fat,
                proteinGrams: protein,
                carbsGrams: carbs,
                tier: tier,
                containsSeedOils: hasSeedOils,
                containsRefinedSugars: hasSugars
            )
        }
    }
}

// MARK: - The "Friendly" Dictionary Scanner
struct FriendlyScanner {
    static let hatefulEight = [
        "soybean", "corn oil", "cottonseed", "sunflower", 
        "safflower", "grapeseed", "rice bran", "canola", "rapeseed"
    ]
    
    static let refinedSugars = [
        "dextrose", "maltodextrin", "high fructose", "sucralose", 
        "aspartame", "sugar", "cane sugar", "syrup"
    ]
    
    static func containsSeedOils(in ingredients: String) -> Bool {
        guard !ingredients.isEmpty else { return false }
        return hatefulEight.contains { ingredients.contains($0) }
    }
    
    static func containsRefinedSugars(in ingredients: String) -> Bool {
        guard !ingredients.isEmpty else { return false }
        return refinedSugars.contains { ingredients.contains($0) }
    }
    
    static func determineTier(hasSeedOils: Bool, hasSugars: Bool, ingredients: String) -> String {
        // If it has toxic modern ingredients, it automatically drops to Modern
        if hasSeedOils || hasSugars {
            return "Modern"
        }
        
        // Very rudimentary logic for Apex vs Ancestral
        if ingredients.contains("beef") || ingredients.contains("egg") || ingredients.contains("butter") || ingredients.contains("tallow") || ingredients.contains("pork") || ingredients.contains("chicken") {
            return "Apex"
        }
        
        if ingredients.contains("fruit") || ingredients.contains("honey") || ingredients.contains("milk") || ingredients.contains("water") {
            return "Ancestral"
        }
        
        // Default fallback
        return "Ancestral"
    }
}
