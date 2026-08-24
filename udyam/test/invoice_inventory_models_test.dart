import 'package:flutter_test/flutter_test.dart';
import 'package:udyam/screens/inventory_screen/models/inventory_item.dart';
import 'package:udyam/screens/scan_invoice_screen/models/invoice.dart';

void main() {
  test('maps Gemini invoice JSON into typed items', () {
    final invoice = Invoice.fromJson({
      'invoice_number': 'INV-42',
      'supplier': {'name': 'Acme Supplies', 'phone': '9999999999'},
      'items': [
        {
          'name': 'Rice',
          'quantity': 5,
          'unit': 'kg',
          'unit_price': '48.50',
          'total': 242.5,
        },
      ],
      'grand_total': 242.5,
    });

    expect(invoice.invoiceNumber, 'INV-42');
    expect(invoice.items.single.name, 'Rice');
    expect(invoice.items.single.quantity, 5);
    expect(invoice.items.single.unitPrice, 48.5);
    expect(
      invoice.items.single.toInventoryJson(
        supplierName: invoice.supplier.name,
        invoiceNumber: invoice.invoiceNumber,
      ),
      containsPair('supplier_name', 'Acme Supplies'),
    );
  });

  test('maps decimal strings returned by inventory API', () {
    final item = InventoryItem.fromJson({
      'id': 'item-id',
      'name': 'Rice',
      'quantity': '7.500',
      'unit': 'kg',
      'purchase_unit_price': '48.50',
      'selling_price': null,
    });

    expect(item.quantity, 7.5);
    expect(item.purchaseUnitPrice, 48.5);
    expect(item.sellingPrice, isNull);
  });
}
