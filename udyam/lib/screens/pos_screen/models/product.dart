class Product {
  final String barcode;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? inventoryItemId;
  final double? quantity;
  final String? unit;
  final String? category;

  const Product({
    required this.barcode,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.inventoryItemId,
    this.quantity,
    this.unit,
    this.category,
  });

  factory Product.fromInventoryJson(Map<String, dynamic> json) {
    return Product(
      barcode:
          json['id'] ??
          '', // Use inventory ID as barcode for image-recognized items
      name: json['name'] ?? '',
      description: json['category'] ?? 'Image recognized item',
      price: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: '',
      inventoryItemId: json['id'],
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'],
      category: json['category'],
    );
  }
}
