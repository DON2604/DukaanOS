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
    );
  }
}
