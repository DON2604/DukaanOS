class Product {
  final String barcode;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? inventoryItemId;

  const Product({
    required this.barcode,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.inventoryItemId,
  });
}
