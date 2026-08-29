import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'scanner_frame_corner.dart';
import 'image_scanner_overlay.dart';
import '../models/product.dart';

class ScannerColumn extends StatelessWidget {
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final String scannerStatus;
  final String? lastScannedBadge;
  final bool isImageScanMode;
  final VoidCallback onToggleScanMode;
  final Function(Product) onProductIdentified;

  const ScannerColumn({
    super.key,
    required this.cameraController,
    required this.isCameraInitialized,
    required this.scannerStatus,
    this.lastScannedBadge,
    required this.isImageScanMode,
    required this.onToggleScanMode,
    required this.onProductIdentified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          isCameraInitialized && cameraController != null
              ? AspectRatio(
                  aspectRatio: cameraController!.value.aspectRatio,
                  child: CameraPreview(cameraController!),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB8490C)),
                ),

          // Scanner mode toggle
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Mode indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isImageScanMode
                        ? Colors.orange.withOpacity(0.9)
                        : Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isImageScanMode
                            ? Icons.image_search
                            : Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isImageScanMode ? 'Image Mode' : 'Barcode Mode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Toggle button
                GestureDetector(
                  onTap: onToggleScanMode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isImageScanMode ? Icons.qr_code : Icons.image,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status text
          if (!isImageScanMode)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Text(
                scannerStatus,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),

          // Scanning overlay based on mode
          if (isImageScanMode)
            Positioned.fill(
              child: ImageScannerOverlay(
                onProductIdentified: onProductIdentified,
                cameraController: cameraController,
              ),
            )
          else
            Center(
              child: Container(
                width: 220,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Stack(
                  children: [
                    Center(
                      child: ColoredBox(
                        color: Colors.greenAccent,
                        child: SizedBox(height: 2, width: 200),
                      ),
                    ),
                    ScannerFrameCorner(alignment: Alignment.topLeft),
                    ScannerFrameCorner(alignment: Alignment.topRight),
                    ScannerFrameCorner(alignment: Alignment.bottomLeft),
                    ScannerFrameCorner(alignment: Alignment.bottomRight),
                  ],
                ),
              ),
            ),

          // Last scanned badge
          if (lastScannedBadge != null && !isImageScanMode)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          lastScannedBadge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Camera status
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isCameraInitialized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
