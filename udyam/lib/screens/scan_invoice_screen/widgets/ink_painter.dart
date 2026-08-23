import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as digital_ink;

class InkPainter extends CustomPainter {
  final List<digital_ink.Stroke> strokes;

  const InkPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C2926)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final stroke in strokes) {
      for (var index = 1; index < stroke.points.length; index++) {
        final start = stroke.points[index - 1];
        final end = stroke.points[index];
        canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) => true;
}
