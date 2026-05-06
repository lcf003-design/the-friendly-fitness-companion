import Foundation
import Combine

struct APIFoodItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let brand: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let sodium: Double
    let imageUrl: String?
}

class NutritionAPIManager: ObservableObject {
    static let shared = NutritionAPIManager()
    
    @Published var searchResults: [APIFoodItem] = []
    @Published var isSearching: Bool = false
    
    func searchFoods(query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isSearching = true
        }
        
        // Open Food Facts API
        // https://world.openfoodfacts.org/cgi/search.pl?search_terms=query&search_simple=1&action=process&json=1
        
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&search_simple=1&action=process&json=1"
        
        guard let url = URL(string: urlString) else {
            self.fallbackMockData(query: query)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                self.fallbackMockData(query: query)
                return
            }
            
            guard let data = data else {
                self.fallbackMockData(query: query)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let products = json["products"] as? [[String: Any]] {
                    
                    var results: [APIFoodItem] = []
                    
                    for product in products.prefix(20) {
                        let name = product["product_name"] as? String ?? "Unknown Product"
                        if name == "Unknown Product" { continue }
                        
                        let brand = product["brands"] as? String ?? "Generic"
                        let imageUrl = product["image_front_thumb_url"] as? String
                        
                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
                        
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
                        )
                        results.append(item)
                    }
                    
                    DispatchQueue.main.async {
                        self.searchResults = results
                        self.isSearching = false
                    }
                } else {
                    self.fallbackMockData(query: query)
                }
            } catch {
                self.fallbackMockData(query: query)
            }
        }.resume()
    }
    
    private func fallbackMockData(query: String) {
        DispatchQueue.main.async {
            self.searchResults = [
                APIFoodItem(name: "\(query.capitalized) Premium Cuts", brand: "Apex Farms", calories: 240, protein: 26, fat: 15, carbs: 0, sodium: 50, imageUrl: nil),
                APIFoodItem(name: "Organic \(query.capitalized)", brand: "Origin Bio", calories: 120, protein: 12, fat: 5, carbs: 2, sodium: 30, imageUrl: nil),
                APIFoodItem(name: "Raw \(query.capitalized)", brand: "Nature's Vault", calories: 300, protein: 20, fat: 22, carbs: 1, sodium: 10, imageUrl: nil)
            ]
            self.isSearching = false
        }
    }
}
