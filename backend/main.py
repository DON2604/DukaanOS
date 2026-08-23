from PIL import Image
from pyzbar.pyzbar import decode
import requests

def scan_and_get_info(image_path: str):
    # 1. Read the image and extract the barcode string
    try:
        img = Image.open(image_path)
    except Exception as e:
        return f"Error opening image: {e}"

    barcodes = decode(img)
    if not barcodes:
        return "No barcode detected in the image."

    barcode_data = barcodes[0].data.decode('utf-8')

    # 2. Query UPCItemDB API for product info, prices, and images
    url = f"https://api.upcitemdb.com/prod/trial/lookup?upc={barcode_data}"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        if data.get("items"):
            item = data["items"][0]
            
            # Extract price offers
            offers = item.get("offers", [])
            prices = [o.get("price") for o in offers if o.get("price")]
            
            # Extract images (returns a list of image URLs)
            images = item.get("images", [])
            primary_image = images[0] if images else None

            return {
                "barcode": barcode_data,
                "title": item.get("title"),
                "brand": item.get("brand"),
                "image_url": primary_image,
                "lowest_price": min(prices) if prices else "N/A",
                "offers": [{"merchant": o.get("merchant"), "price": o.get("price")} for o in offers]
            }

    return {"barcode": barcode_data, "message": "Product not found in database"}

# Run the function
result = scan_and_get_info("barcode.jpeg")
print(result)