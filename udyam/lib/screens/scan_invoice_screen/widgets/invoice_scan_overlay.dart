import 'dart:math' as math;

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
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The old fixed 680px frame overflowed the scanner's tab body
                // on compact devices. Keep a document-like frame, but size it
                // from the space left after the header and capture controls.
                final frameWidth = math.max(0.0, constraints.maxWidth - 32);
                final frameHeight = math.min(
                  constraints.maxHeight - 24,
                  frameWidth * 1.45,
                );
                return Center(
                  child: SizedBox(
                    width: frameWidth,
                    height: math.max(0.0, frameHeight),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xCCFFFFFF),
                          width: 1,
                        ),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
