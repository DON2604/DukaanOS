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

  static double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  factory Product.fromInventoryJson(Map<String, dynamic> json) {
    return Product(
      barcode:
          json['id'] ??
          '', // Use inventory ID as barcode for image-recognized items
      name: json['name'] ?? '',
      description: json['category'] ?? 'Image recognized item',
      price: Product._toDouble(json['selling_price']),
      imageUrl: '',
      inventoryItemId: json['id']?.toString(),
      quantity: Product._toDouble(json['quantity'], fallback: 0.0),
      unit: json['unit']?.toString(),
      category: json['category']?.toString(),
    );
  }
}
