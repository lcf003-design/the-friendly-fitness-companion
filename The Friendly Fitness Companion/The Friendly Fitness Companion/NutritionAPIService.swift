import Foundation

// MARK: - OpenFoodFacts Models (UK / Global Primary)
struct OFFResponse: Codable {
    let products: [OFFProduct]
}

struct OFFProduct: Codable {
    let productName: String?
    let brands: String?
    let ingredientsText: String?
    let nutriments: OFFNutriments?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
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

// MARK: - USDA FoodData Central Models (Fallback)
struct USDAResponse: Codable {
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let description: String?
    let brandOwner: String?
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
    let containsSeedOils: Bool
    let containsRefinedSugars: Bool
}

// MARK: - API Service
class NutritionAPIService {
    static let shared = NutritionAPIService()
    
    private let usdaApiKey = "DEMO_KEY"
    
    func searchFood(query: String) async throws -> [FoodSearchResult] {
        var results: [FoodSearchResult] = []
        
        do {
            let ukResults = try await searchOpenFoodFactsUK(query: query)
            if !ukResults.isEmpty {
                results = ukResults
            }
        } catch {
            print("OpenFoodFacts UK failed or offline: \(error.localizedDescription)")
        }
        
        if results.isEmpty {
            print("Falling back to USDA Database...")
            results = try await searchUSDA(query: query)
        }
        
        // Filter out duplicate names
        var uniqueNames = Set<String>()
        var deduplicatedResults: [FoodSearchResult] = []
        
        for result in results {
            if !uniqueNames.contains(result.name) {
                uniqueNames.insert(result.name)
                deduplicatedResults.append(result)
            }
        }
        
        return deduplicatedResults
    }
    
    private func searchOpenFoodFactsUK(query: String) async throws -> [FoodSearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://uk.openfoodfacts.org/api/v2/search?categories_tags_en=\(encodedQuery)&fields=product_name,brands,ingredients_text,nutriments&page_size=20") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("FriendlyFitnessCompanion/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(OFFResponse.self, from: data)
        
        return decodedResponse.products.compactMap { product in
            guard let name = product.productName, !name.isEmpty else { return nil }
            
            let brand = product.brands ?? ""
            let finalName = brand.isEmpty ? name.capitalized : "\(brand.capitalized) - \(name.capitalized)"
            
            let fat = product.nutriments?.fat100g ?? 0.0
            let protein = product.nutriments?.proteins100g ?? 0.0
            let carbs = product.nutriments?.carbohydrates100g ?? 0.0
            let ingredients = (product.ingredientsText ?? "").lowercased()
            
            let hasSeedOils = FriendlyScanner.containsSeedOils(in: ingredients)
            let hasSugars = FriendlyScanner.containsRefinedSugars(in: ingredients)
            
            return FoodSearchResult(
                name: finalName,
                fatGrams: fat,
                proteinGrams: protein,
                carbsGrams: carbs,
                containsSeedOils: hasSeedOils,
                containsRefinedSugars: hasSugars
            )
        }
    }
    
    private func searchUSDA(query: String) async throws -> [FoodSearchResult] {
        // We request a larger page size so we can filter duplicates effectively
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(usdaApiKey)&query=\(encodedQuery)&pageSize=25") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(USDAResponse.self, from: data)
        
        return decodedResponse.foods.compactMap { food in
            guard let name = food.description, !name.isEmpty else { return nil }
            
            let brand = food.brandOwner ?? ""
            let finalName = brand.isEmpty ? name.capitalized : "\(brand.capitalized) - \(name.capitalized)"
            
            var fat = 0.0
            var protein = 0.0
            var carbs = 0.0
            
            if let nutrients = food.foodNutrients {
                for nutrient in nutrients {
                    let nName = nutrient.nutrientName?.lowercased() ?? ""
                    if nName.contains("protein") { protein = nutrient.value ?? 0.0 }
                    else if nName.contains("lipid (fat)") || nName.contains("total fat") { fat = nutrient.value ?? 0.0 }
                    else if nName.contains("carbohydrate") { carbs = nutrient.value ?? 0.0 }
                }
            }
            
            let ingredients = (food.ingredients ?? "").lowercased()
            let hasSeedOils = FriendlyScanner.containsSeedOils(in: ingredients)
            let hasSugars = FriendlyScanner.containsRefinedSugars(in: ingredients)
            
            return FoodSearchResult(
                name: finalName,
                fatGrams: fat,
                proteinGrams: protein,
                carbsGrams: carbs,
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
        "safflower", "grapeseed", "rice bran", "canola", "rapeseed", "vegetable oil"
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
}
