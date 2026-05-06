import urllib.request
import json
import urllib.parse

query = "beef mince"
url = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=" + urllib.parse.quote(query) + "&search_simple=1&action=process&json=1"

req = urllib.request.Request(url, headers={'User-Agent': 'FriendlyFitnessApp/1.0 (test@example.com)'})
with urllib.request.urlopen(req) as response:
    data = json.loads(response.read())

if data.get("products"):
    product = data["products"][0]
    print("Serving size string:", product.get("serving_size"))
    nutriments = product.get("nutriments", {})
    print("kcal 100g:", nutriments.get("energy-kcal_100g"))
    print("kcal serving:", nutriments.get("energy-kcal_serving"))
    
    print("\nKeys in nutriments:")
    print([k for k in nutriments.keys() if "energy" in k or "protein" in k])
