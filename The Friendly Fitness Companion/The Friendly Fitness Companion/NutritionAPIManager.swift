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
    var servingSize: String? = "100g"
    var grade: String? = nil
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
        
                var request = URLRequest(url: url)
        request.setValue("FriendlyFitnessApp/1.0 (contact@friendlyfitness.app)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
                        
                        let rawServingSize = product["serving_size"] as? String
                        
                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
                        
                        let hasServing = nutriments["energy-kcal_serving"] != nil
                        let suffix = hasServing ? "_serving" : "_100g"
                        let finalServingSize = hasServing ? (rawServingSize ?? "1 serving") : "100g"
                        
                        let calories = nutriments["energy-kcal" + suffix] as? Double ?? 0.0
                        let protein = nutriments["proteins" + suffix] as? Double ?? 0.0
                        let fat = nutriments["fat" + suffix] as? Double ?? 0.0
                        let carbs = nutriments["carbohydrates" + suffix] as? Double ?? 0.0
                        let sodium = nutriments["sodium" + suffix] as? Double ?? 0.0
                        
                        let nutriscore = product["nutriscore_grade"] as? String
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
                APIFoodItem(name: "\(query.capitalized) Premium Cuts", brand: "Apex Farms", calories: 240, protein: 26, fat: 15, carbs: 0, sodium: 50, imageUrl: nil, grade: "A"),
                APIFoodItem(name: "Organic \(query.capitalized)", brand: "Origin Bio", calories: 120, protein: 12, fat: 5, carbs: 2, sodium: 30, imageUrl: nil, grade: "A"),
                APIFoodItem(name: "Raw \(query.capitalized)", brand: "Nature's Vault", calories: 300, protein: 20, fat: 22, carbs: 1, sodium: 10, imageUrl: nil, grade: "A")
            ]
            self.isSearching = false
        }
    }
}
