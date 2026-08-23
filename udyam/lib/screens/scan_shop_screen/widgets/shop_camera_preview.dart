import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ShopCameraPreview extends StatelessWidget {
  const ShopCameraPreview({
    super.key,
    required this.isInitializing,
    required this.cameraController,
    this.errorText,
  });

  final bool isInitializing;
  final CameraController? cameraController;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return const ColoredBox(
        color: Color(0xFF2C2926),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFB8490C)),
        ),
      );
    }

    final controller = cameraController;
    if (errorText != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return _ShelfFallbackBackdrop(message: errorText);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _ShelfFallbackBackdrop extends StatelessWidget {
  const _ShelfFallbackBackdrop({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A342C), Color(0xFF1E1B17), Color(0xFF2A241C)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _ShelfSilhouettePainter()),
          Container(color: const Color(0x66000000)),
          if (message != null)
            Align(
              alignment: const Alignment(0, -0.55),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xE6F7F3EB),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShelfSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shelfPaint = Paint()
      ..color = const Color(0x33F7F3EB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final packPaint = Paint()..style = PaintingStyle.fill;
    const packColors = [
      Color(0x66B8490C),
      Color(0x551F6F46),
      Color(0x55C43B2A),
      Color(0x66C9A227),
    ];

    for (var row = 0; row < 4; row++) {
      final y = size.height * (0.22 + row * 0.18);
      canvas.drawLine(Offset(size.width * 0.08, y), Offset(size.width * 0.92, y), shelfPaint);

      for (var col = 0; col < 6; col++) {
        packPaint.color = packColors[(row + col) % packColors.length];
        final left = size.width * (0.12 + col * 0.13);
        final top = y - size.height * 0.11;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, size.width * 0.09, size.height * 0.1),
            const Radius.circular(4),
          ),
          packPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
