import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as digital_ink;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanInvoiceScreen extends StatefulWidget {
  const ScanInvoiceScreen({super.key});

  @override
  State<ScanInvoiceScreen> createState() => _ScanInvoiceScreenState();
}

class _ScanInvoiceScreenState extends State<ScanInvoiceScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  final int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isFlashOn = false;
  bool _isReadingInvoice = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorText = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorText = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }

      final camera = _cameras[_selectedCameraIndex];
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
        _isFlashOn = false;
      });
    } on CameraException catch (error) {
      setState(() {
        _errorText = _cameraErrorMessage(error);
        _isInitializing = false;
      });
    } catch (_) {
      setState(() {
        _errorText = 'Failed to initialize camera.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'cameraPermission':
        return 'Camera permission denied. Please allow access in settings.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access denied without prompt. Open app settings.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';
      default:
        return 'Camera error: ${error.description ?? error.code}';
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      final nextFlashState = !_isFlashOn;
      await controller.setFlashMode(
        nextFlashState ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) return;
      setState(() {
        _isFlashOn = nextFlashState;
      });
    } on CameraException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to toggle flash on this camera.')),
      );
    }
  }

  Future<void> _captureBill() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isTakingPicture) {
      return;
    }

    setState(() {
      _isReadingInvoice = true;
    });

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = await controller.takePicture();
      final recognizedText = await textRecognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final extractedText = recognizedText.text.trim();

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceOcrResultScreen(text: extractedText),
        ),
      );
    } on CameraException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture failed. Please try again.')),
      );
    } catch (_) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const InvoiceOcrResultScreen(text: ''),
        ),
      );
    } finally {
      await textRecognizer.close();
      if (mounted) {
        setState(() {
          _isReadingInvoice = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCameraPreview(),
                    _buildScanOverlay(),
                  ],
                ),
              ),
              _buildCapturePanel(),
              _buildBottomTabBar(),
            ],
          ),
          if (_isReadingInvoice) _buildReadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildReadingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF8AFFC8)),
              const SizedBox(height: 18),
              const Text(
                'Reading invoice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Extracting items, dates and totals',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final controller = _cameraController;
    if (_errorText != null || controller == null || !controller.value.isInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorText ?? 'Camera unavailable.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return CameraPreview(controller);
  }

  Widget _buildScanOverlay() {
    return Column(
      children: [
        SizedBox(height: 24,),
        Container(
          height: 64,
          color: const Color(0x66000000),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Back',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
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
                onPressed: _toggleFlash,
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
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
          child: Stack(
            children: [
              _buildFrameCorner(alignment: Alignment.topLeft),
              _buildFrameCorner(alignment: Alignment.topRight),
              _buildFrameCorner(alignment: Alignment.bottomLeft),
              _buildFrameCorner(alignment: Alignment.bottomRight),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildCapturePanel() {
    return Container(
      color: const Color(0xFF151716),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: _captureBill,
          child: Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7D847E), width: 2),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTabBar() {
    return Container(
      height: 78,
      color: const Color(0xFFF9F5EE),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomTabItem(icon: Icons.home_outlined, label: 'Home', active: false),
          _BottomTabItem(icon: Icons.point_of_sale_outlined, label: 'Sales', active: true),
          _BottomTabItem(icon: Icons.inventory_2_outlined, label: 'Inventory', active: false),
          _BottomTabItem(icon: Icons.account_balance_wallet_outlined, label: 'Khata', active: false),
          _BottomTabItem(icon: Icons.menu, label: 'More', active: false),
        ],
      ),
    );
  }

  Widget _buildFrameCorner({required Alignment alignment}) {
    const cornerSize = 26.0;
    const stroke = 4.0;
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: cornerSize,
        height: cornerSize,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: 0,
              right: 0,
              child: Container(height: stroke, color: const Color(0xFF8AFFC8)),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(width: stroke, color: const Color(0xFF8AFFC8)),
            ),
          ],
        ),
      ),
    );
  }

}

class InvoiceOcrResultScreen extends StatefulWidget {
  final String text;

  const InvoiceOcrResultScreen({super.key, required this.text});

  @override
  State<InvoiceOcrResultScreen> createState() => _InvoiceOcrResultScreenState();
}

class _InvoiceOcrResultScreenState extends State<InvoiceOcrResultScreen> {
  late String _text = widget.text;

  @override
  Widget build(BuildContext context) {
    final fields = _InvoiceFields.fromText(_text);
    final needsHelp = _text.isEmpty || fields.hasMissingFields;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5EE),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        title: const Text('Invoice details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Extracted text',
            style: TextStyle(
              color: Color(0xFF2C2926),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _text.isEmpty
                ? 'No text was detected. Try capturing the invoice in better light.'
                : 'Review the details before saving them to your records.',
            style: const TextStyle(color: Color(0xFF6C625C), fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (_text.isNotEmpty) _buildSummary(fields),
          if (needsHelp) ...[
            const SizedBox(height: 16),
            _buildHandwritingFallback(context),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE3D9D0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _text.isEmpty ? 'No text detected.' : _text,
              style: const TextStyle(
                color: Color(0xFF2C2926),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan another invoice'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8490C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandwritingFallback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        border: Border.all(color: const Color(0xFFF0C9A9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Some details may be missing',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF71300E)),
          ),
          const SizedBox(height: 5),
          const Text(
            'Write the unreadable number, date or total by hand and we will try a second recognizer.',
            style: TextStyle(color: Color(0xFF8B5A3B), height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final handwriting = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const HandwritingInputScreen()),
              );
              if (handwriting != null && handwriting.trim().isNotEmpty) {
                setState(() {
                  _text = '$_text\n${handwriting.trim()}'.trim();
                });
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Try handwriting input'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB8490C)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(_InvoiceFields fields) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Invoice number', value: fields.number),
          _SummaryRow(label: 'Date', value: fields.date),
          _SummaryRow(label: 'Total', value: fields.total),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF55705D)))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF263B2B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceFields {
  final String number;
  final String date;
  final String total;

  const _InvoiceFields({required this.number, required this.date, required this.total});

  bool get hasMissingFields =>
      number == 'Not detected' || date == 'Not detected' || total == 'Not detected';

  factory _InvoiceFields.fromText(String text) {
    String find(RegExp pattern) =>
        pattern.firstMatch(text)?.group(1)?.trim() ?? 'Not detected';

    return _InvoiceFields(
      number: find(RegExp(
        r'(?:invoice|bill|inv)[\s._-]*(?:no|number|#)?\s*[:#-]?\s*([A-Z0-9][A-Z0-9./_-]*)',
        caseSensitive: false,
      )),
      date: find(RegExp(
        r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b',
      )),
      total: find(RegExp(
        r'(?:grand\s+total|net\s+total|total\s+due|total)\s*[:.-]?\s*(?:rs\.?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)',
        caseSensitive: false,
      )),
    );
  }
}

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
        setState(() => _errorText = 'No handwriting was recognized. Please try again.');
      } else {
        Navigator.of(context).pop(candidates.first.text);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Handwriting recognition failed. Check your connection and try again.');
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
            const Text('Write the missing detail', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Use one line at a time. The downloaded language model recognizes your pen strokes on-device.'),
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
                    border: Border.all(color: const Color(0xFFB8490C), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: _InkPainter(
                      strokes: [
                        ..._strokes,
                        ...(_currentStroke == null ? <digital_ink.Stroke>[] : [_currentStroke!]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(_errorText!, style: const TextStyle(color: Color(0xFFB3261E))),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isRecognizing ? null : () => setState(() => _strokes.clear()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isRecognizing ? null : _recognize,
                  icon: _isRecognizing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.text_fields),
                  label: Text(_isRecognizing ? 'Recognizing...' : 'Recognize'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB8490C)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<digital_ink.Stroke> strokes;

  const _InkPainter({required this.strokes});

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
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

class _BottomTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomTabItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFB8490C);
    final idleColor = const Color(0xFF4D3E39);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? activeColor : idleColor, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? activeColor : idleColor,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}