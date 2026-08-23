import 'package:flutter/material.dart';

import 'invoice_frame_corner.dart';

class InvoiceScanOverlay extends StatelessWidget {
  final bool isFlashOn;
  final VoidCallback onToggleFlash;

  const InvoiceScanOverlay({
    super.key,
    required this.isFlashOn,
    required this.onToggleFlash,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          height: 64,
          color: const Color(0x66000000),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (Navigator.of(context).canPop()) ...[
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: Text(
                  'Scan invoice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleFlash,
                icon: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
                tooltip: 'Toggle flash',
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 680,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xCCFFFFFF), width: 1),
          ),
          child: const Stack(
            children: [
              InvoiceFrameCorner(alignment: Alignment.topLeft),
              InvoiceFrameCorner(alignment: Alignment.topRight),
              InvoiceFrameCorner(alignment: Alignment.bottomLeft),
              InvoiceFrameCorner(alignment: Alignment.bottomRight),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
