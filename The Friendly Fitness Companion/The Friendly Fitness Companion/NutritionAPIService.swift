import Foundation

// MARK: - OpenFoodFacts Models
struct OFFResponse: Codable {
    let products: [OFFProduct]
}

struct OFFProduct: Codable {
    let productName: String?
    let ingredientsText: String?
    let nutriments: OFFNutriments?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case ingredientsText = "ingredients_text"
        case nutriments
    }
}

struct OFFNutriments: Codable {
    let fat100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case fat100g = "fat_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
    }
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
    
    func searchFood(query: String) async throws -> [FoodSearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=10") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(OFFResponse.self, from: data)
        
        return decodedResponse.products.compactMap { product in
            guard let name = product.productName, !name.isEmpty else { return nil }
            
            let fat = product.nutriments?.fat100g ?? 0.0
            let protein = product.nutriments?.proteins100g ?? 0.0
            let carbs = product.nutriments?.carbohydrates100g ?? 0.0
            
            let ingredients = (product.ingredientsText ?? "").lowercased()
            
            // Scan for Hateful Eight & Sugars
            let hasSeedOils = FriendlyScanner.containsSeedOils(in: ingredients)
            let hasSugars = FriendlyScanner.containsRefinedSugars(in: ingredients)
            
            // Determine Tier
            let tier = FriendlyScanner.determineTier(hasSeedOils: hasSeedOils, hasSugars: hasSugars, ingredients: ingredients)
            
            return FoodSearchResult(
                name: name,
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
        // In a real app, this would be highly robust
        if ingredients.contains("beef") || ingredients.contains("egg") || ingredients.contains("butter") || ingredients.contains("tallow") {
            return "Apex"
        }
        
        if ingredients.contains("fruit") || ingredients.contains("honey") || ingredients.contains("milk") {
            return "Ancestral"
        }
        
        // Default fallback if it's clean but unknown
        return "Ancestral"
    }
}
