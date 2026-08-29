double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.purchaseUnitPrice,
    this.sellingPrice,
    this.lineTotal,
    this.supplierName,
    this.invoiceNumber,
    this.updatedAt,
    this.category,
    this.shelfLifeDays,
    this.expiresAt,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double? purchaseUnitPrice;
  final double? sellingPrice;
  final double? lineTotal;
  final String? supplierName;
  final String? invoiceNumber;
  final DateTime? updatedAt;
  final String? category;
  final int? shelfLifeDays;
  final DateTime? expiresAt;

  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.toLocal().difference(DateTime.now()).inDays;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: _asDouble(json['quantity']) ?? 0,
      unit: json['unit']?.toString() ?? 'unit',
      purchaseUnitPrice: _asDouble(json['purchase_unit_price']),
      sellingPrice: _asDouble(json['selling_price']),
      lineTotal: _asDouble(json['line_total']),
      supplierName: json['supplier_name']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      category: json['category']?.toString(),
      shelfLifeDays: json['shelf_life_days'] is num
          ? (json['shelf_life_days'] as num).toInt()
          : int.tryParse(json['shelf_life_days']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }
}
