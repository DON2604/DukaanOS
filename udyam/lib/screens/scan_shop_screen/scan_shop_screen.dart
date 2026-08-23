import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../scan_invoice_screen/services/camera_error_mapper.dart';
import '../welcome_screen/welcome_screen.dart';
import 'models/detected_product.dart';
import 'shop_inventory_ready_screen.dart';
import 'widgets/shop_camera_preview.dart';
import 'widgets/shop_scan_ar_labels.dart';
import 'widgets/shop_scan_header.dart';
import 'widgets/shop_scan_hint.dart';
import 'widgets/shop_scan_line.dart';
import 'widgets/shop_scan_progress_panel.dart';

class ScanShopScreen extends StatefulWidget {
  const ScanShopScreen({super.key});

  @override
  State<ScanShopScreen> createState() => _ScanShopScreenState();
}

class _ScanShopScreenState extends State<ScanShopScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const int _totalSections = 6;

  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isFlashOn = false;
  bool _isScanning = false;
  int _completedSections = 0;
  String? _errorText;
  Timer? _progressTimer;
  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer?.cancel();
    _scanLineController.dispose();
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
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorText = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
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
      if (!mounted) return;
      setState(() {
        _errorText = cameraErrorMessage(error);
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Camera unavailable. You can still preview the scan.';
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

  void _handlePrimaryAction() {
    if (!_isScanning && _completedSections == 0) {
      _startScan();
      return;
    }
    _finishScan();
  }

  void _startScan() {
    _progressTimer?.cancel();
    setState(() {
      _isScanning = true;
      _completedSections = 0;
    });
    _scanLineController.repeat();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _completedSections += 1;
      });
      if (_completedSections >= _totalSections) {
        timer.cancel();
        _finishScan();
      }
    });
  }

  Future<void> _finishScan() async {
    _progressTimer?.cancel();
    _scanLineController.stop();
    if (!mounted) return;

    setState(() {
      _isScanning = false;
      if (_completedSections < 1) {
        _completedSections = 3;
      }
    });

    await _disposeCamera();
    if (!mounted) return;

    final visibleProducts = kDemoShelfProducts
        .where((product) => product.appearAtSection <= _completedSections)
        .toList();

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ShopInventoryReadyScreen(
          products: visibleProducts,
          shelvesScanned: _completedSections.clamp(1, _totalSections),
        ),
      ),
    );
  }

  void _leaveToWelcome() {
    _progressTimer?.cancel();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _leaveToWelcome();
  }

  @override
  Widget build(BuildContext context) {
    final visibleLabels = _isScanning || _completedSections > 0
        ? _completedSections
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B17),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ShopCameraPreview(
            isInitializing: _isInitializing,
            cameraController: _cameraController,
            errorText: _errorText,
          ),
          const _ReadableVignette(),
          if (_isScanning) ShopScanLine(animation: _scanLineController),
          ShopScanArLabels(
            products: kDemoShelfProducts,
            visibleCount: visibleLabels,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  ShopScanHeader(
                    isFlashOn: _isFlashOn,
                    canToggleFlash:
                        _cameraController?.value.isInitialized ?? false,
                    onBack: _handleBack,
                    onToggleFlash: _toggleFlash,
                  ),
                  const Spacer(),
                  ShopScanHint(isScanning: _isScanning),
                  const SizedBox(height: 20),
                  ShopScanProgressPanel(
                    completedSections: _completedSections,
                    totalSections: _totalSections,
                    isScanning: _isScanning,
                    onPrimaryPressed: _handlePrimaryAction,
                    onSkipPressed: _leaveToWelcome,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadableVignette extends StatelessWidget {
  const _ReadableVignette();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xB31E1B17),
              Color(0x00000000),
              Color(0x00000000),
              Color(0xD91E1B17),
            ],
            stops: [0, 0.22, 0.52, 1],
          ),
        ),
      ),
    );
  }
}
