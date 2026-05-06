import urllib.request
import json
import urllib.parse

query = "chicken breast"
url = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=" + urllib.parse.quote(query) + "&search_simple=1&action=process&json=1&page_size=3"

req = urllib.request.Request(url, headers={'User-Agent': 'FriendlyFitnessApp/1.0'})
with urllib.request.urlopen(req) as response:
    data = json.loads(response.read())

for p in data.get("products", []):
    print("Name:", p.get("product_name"))
    print("Grade:", p.get("nutriscore_grade"))
    print("Image:", p.get("image_url"))
    print("Thumb:", p.get("image_front_thumb_url"))
    print("---")
