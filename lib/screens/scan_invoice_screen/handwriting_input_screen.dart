import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as digital_ink;

import 'widgets/ink_painter.dart';

class HandwritingInputScreen extends StatefulWidget {
  const HandwritingInputScreen({super.key});

  @override
  State<HandwritingInputScreen> createState() => _HandwritingInputScreenState();
}

class _HandwritingInputScreenState extends State<HandwritingInputScreen> {
  final List<digital_ink.Stroke> _strokes = [];
  digital_ink.Stroke? _currentStroke;
  bool _isRecognizing = false;
  String? _errorText;

  void _startStroke(DragStartDetails details) {
    _currentStroke = digital_ink.Stroke()
      ..points.add(_pointFromOffset(details.localPosition));
    setState(() => _errorText = null);
  }

  void _updateStroke(DragUpdateDetails details) {
    _currentStroke?.points.add(_pointFromOffset(details.localPosition));
    setState(() {});
  }

  void _finishStroke(DragEndDetails details) {
    if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
      _strokes.add(_currentStroke!);
    }
    _currentStroke = null;
  }

  digital_ink.StrokePoint _pointFromOffset(Offset offset) {
    return digital_ink.StrokePoint(
      x: offset.dx,
      y: offset.dy,
      t: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _recognize() async {
    if (_strokes.isEmpty || _isRecognizing) return;
    setState(() {
      _isRecognizing = true;
      _errorText = null;
    });

    final modelManager = digital_ink.DigitalInkRecognizerModelManager();
    final recognizer = digital_ink.DigitalInkRecognizer(languageCode: 'en');
    try {
      await modelManager.downloadModel('en');
      final candidates = await recognizer.recognize(
        digital_ink.Ink()..strokes = List<digital_ink.Stroke>.from(_strokes),
        context: digital_ink.DigitalInkRecognitionContext(
          writingArea: digital_ink.WritingArea(width: 360, height: 240),
        ),
      );
      if (!mounted) return;
      if (candidates.isEmpty || candidates.first.text.trim().isEmpty) {
        setState(
          () =>
              _errorText = 'No handwriting was recognized. Please try again.',
        );
      } else {
        Navigator.of(context).pop(candidates.first.text);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorText =
              'Handwriting recognition failed. Check your connection and try again.',
        );
      }
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EE),
      appBar: AppBar(
        title: const Text('Handwriting fallback'),
        backgroundColor: const Color(0xFFF9F5EE),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write the missing detail',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use one line at a time. The downloaded language model recognizes your pen strokes on-device.',
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GestureDetector(
                onPanStart: _startStroke,
                onPanUpdate: _updateStroke,
                onPanEnd: _finishStroke,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFB8490C),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: InkPainter(
                      strokes: [
                        ..._strokes,
                        ...(_currentStroke == null
                            ? <digital_ink.Stroke>[]
                            : [_currentStroke!]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isRecognizing
                      ? null
                      : () => setState(() => _strokes.clear()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isRecognizing ? null : _recognize,
                  icon: _isRecognizing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.text_fields),
                  label: Text(_isRecognizing ? 'Recognizing...' : 'Recognize'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB8490C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
