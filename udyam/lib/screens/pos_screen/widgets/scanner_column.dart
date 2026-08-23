import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'scanner_frame_corner.dart';

class ScannerColumn extends StatelessWidget {
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final String scannerStatus;
  final String? lastScannedBadge;

  const ScannerColumn({
    super.key,
    required this.cameraController,
    required this.isCameraInitialized,
    required this.scannerStatus,
    this.lastScannedBadge,
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
          isCameraInitialized && cameraController != null
              ? AspectRatio(
                  aspectRatio: cameraController!.value.aspectRatio,
                  child: CameraPreview(cameraController!),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB8490C)),
                ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 8, height: 8),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Scanner active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  scannerStatus,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
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
          if (lastScannedBadge != null)
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
