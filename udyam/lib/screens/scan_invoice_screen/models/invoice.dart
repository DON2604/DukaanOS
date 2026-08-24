double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

class InvoiceSupplier {
  const InvoiceSupplier({this.name, this.phone});

  final String? name;
  final String? phone;

  factory InvoiceSupplier.fromJson(Map<String, dynamic>? json) {
    return InvoiceSupplier(
      name: json?['name']?.toString(),
      phone: json?['phone']?.toString(),
    );
  }
}

class InvoiceItem {
  const InvoiceItem({
    required this.name,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.total,
  });

  final String name;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final double? total;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      name: json['name']?.toString().trim() ?? '',
      quantity: _asDouble(json['quantity']),
      unit: json['unit']?.toString(),
      unitPrice: _asDouble(json['unit_price']),
      total: _asDouble(json['total']),
    );
  }

  Map<String, dynamic> toInventoryJson({
    String? supplierName,
    String? invoiceNumber,
  }) {
    return {
      'name': name,
      'quantity': quantity ?? 1,
      'unit': unit ?? 'unit',
      'purchase_unit_price': unitPrice,
      'line_total': total,
      'supplier_name': supplierName,
      'invoice_number': invoiceNumber,
    };
  }
}

class Invoice {
  const Invoice({
    this.invoiceNumber,
    this.date,
    required this.supplier,
    required this.items,
    this.subtotal,
    this.tax,
    this.grandTotal,
  });

  final String? invoiceNumber;
  final String? date;
  final InvoiceSupplier supplier;
  final List<InvoiceItem> items;
  final double? subtotal;
  final double? tax;
  final double? grandTotal;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Invoice(
      invoiceNumber: json['invoice_number']?.toString(),
      date: json['date']?.toString(),
      supplier: InvoiceSupplier.fromJson(
        json['supplier'] is Map
            ? Map<String, dynamic>.from(json['supplier'] as Map)
            : null,
      ),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      InvoiceItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((item) => item.name.isNotEmpty)
                .toList()
          : const [],
      subtotal: _asDouble(json['subtotal']),
      tax: _asDouble(json['tax']),
      grandTotal: _asDouble(json['grand_total']),
    );
  }
}
