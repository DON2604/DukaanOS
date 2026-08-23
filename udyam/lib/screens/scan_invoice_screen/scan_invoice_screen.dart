import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'invoice_ocr_result_screen.dart';
import 'services/camera_error_mapper.dart';
import 'widgets/invoice_camera_preview.dart';
import 'widgets/invoice_capture_panel.dart';
import 'widgets/invoice_reading_overlay.dart';
import 'widgets/invoice_scan_overlay.dart';

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
        _errorText = cameraErrorMessage(error);
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
      // The photo is now on disk, so release the hardware before moving to the
      // OCR/LLM result page. ML Kit only needs the image file path.
      await _disposeCamera();
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
      if (mounted) {
        await _initializeCamera();
      }
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
      if (mounted) {
        await _initializeCamera();
      }
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
                    InvoiceCameraPreview(
                      isInitializing: _isInitializing,
                      cameraController: _cameraController,
                      errorText: _errorText,
                    ),
                    InvoiceScanOverlay(
                      isFlashOn: _isFlashOn,
                      onToggleFlash: _toggleFlash,
                    ),
                  ],
                ),
              ),
              InvoiceCapturePanel(onCapture: _captureBill),
            ],
          ),
          if (_isReadingInvoice) const InvoiceReadingOverlay(),
        ],
      ),
    );
  }
}
