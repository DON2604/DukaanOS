import 'package:flutter/material.dart';

import '../services/checkout_service.dart';

class CheckoutSelection {
  const CheckoutSelection({required this.paymentType, this.customerName});
  final PaymentType paymentType;
  final String? customerName;
}

Future<CheckoutSelection?> showCheckoutDialog(
  BuildContext context, {
  required double total,
}) {
  return showDialog<CheckoutSelection>(
    context: context,
    builder: (context) => _CheckoutDialog(total: total),
  );
}

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog({required this.total});
  final double total;

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  PaymentType _paymentType = PaymentType.cash;
  final _customer = TextEditingController();

  @override
  void dispose() {
    _customer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Collect ₹${widget.total.toStringAsFixed(2)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<PaymentType>(
            segments: const [
              ButtonSegment(
                value: PaymentType.cash,
                icon: Icon(Icons.payments_outlined),
                label: Text('Cash'),
              ),
              ButtonSegment(
                value: PaymentType.credit,
                icon: Icon(Icons.person_outline),
                label: Text('Credit'),
              ),
            ],
            selected: {_paymentType},
            onSelectionChanged: (value) {
              setState(() => _paymentType = value.first);
            },
          ),
          if (_paymentType == PaymentType.credit) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customer,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Customer name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_paymentType == PaymentType.credit &&
                _customer.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter the customer name.')),
              );
              return;
            }
            Navigator.pop(
              context,
              CheckoutSelection(
                paymentType: _paymentType,
                customerName: _customer.text.trim(),
              ),
            );
          },
          child: const Text('Confirm checkout'),
        ),
      ],
    );
  }
}

Future<void> showCheckoutCompleteDialog(
  BuildContext context, {
  required double total,
  String receiptNumber = 'RCP-000000',
  String note = 'Receipt',
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFF7F3EB),
      title: const Text('Checkout Complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Collected ₹${total.toStringAsFixed(2)} successfully!'),
          const SizedBox(height: 12),
          Text(
            'Receipt No: $receiptNumber',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(note),
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB8490C),
          ),
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
