import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class InvoiceCameraPreview extends StatelessWidget {
  final bool isInitializing;
  final CameraController? cameraController;
  final String? errorText;

  const InvoiceCameraPreview({
    super.key,
    required this.isInitializing,
    required this.cameraController,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final controller = cameraController;
    if (errorText != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorText ?? 'Camera unavailable.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return CameraPreview(controller);
  }
}
