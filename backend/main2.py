import requests

def get_product_info_by_barcode(barcode: str):
    # Sanitize input string (remove spaces or hyphens)
    clean_barcode = str(barcode).strip().replace("-", "")

    url = f"https://api.upcitemdb.com/prod/trial/lookup?upc={clean_barcode}"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        if data.get("items"):
            item = data["items"][0]
            
            # Extract pricing offers
            offers = item.get("offers", [])
            prices = [o.get("price") for o in offers if o.get("price")]
            
            # Extract product images
            images = item.get("images", [])
            primary_image = images[0] if images else None

            return {
                "barcode": clean_barcode,
                "title": item.get("title"),
                "brand": item.get("brand"),
                "image_url": primary_image,
                "lowest_price": min(prices) if prices else "N/A",
                "offers": [{"merchant": o.get("merchant"), "price": o.get("price")} for o in offers]
            }

    return {"barcode": clean_barcode, "message": "Product not found in database"}

# Pass any barcode string or integer directly
result = get_product_info_by_barcode("4005900133342")
print(result)