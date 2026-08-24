import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'models/cart_item.dart';
import 'models/product.dart';
import 'services/barcode_product_service.dart';
import 'services/camera_input_image.dart';
import 'services/product_catalog.dart';
import 'widgets/add_custom_item_dialog.dart';
import 'widgets/add_discount_dialog.dart';
import 'widgets/cart_column.dart';
import 'widgets/checkout_complete_dialog.dart';
import 'widgets/item_added_snackbar.dart';
import 'widgets/pos_app_bar.dart';
import 'widgets/scanner_column.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  String _scannerStatus = "Point at barcode to scan";
  String? _lastScannedBadge;

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final BarcodeProductService _barcodeProductService =
      const BarcodeProductService();

  final List<CartItem> _cart = [];
  double _discount = 0.0;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Product> _catalog = createDefaultCatalog();

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
    _barcodeScanner.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final controller = CameraController(
        _cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });

      _startScanner();
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.stopImageStream();
      await controller.dispose();
    }
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  void _startScanner() {
    if (_cameraController == null) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;

      final now = DateTime.now();
      if (_lastScanTime != null &&
          now.difference(_lastScanTime!).inMilliseconds < 1500) {
        return;
      }

      _isProcessing = true;

      try {
        final inputImage = inputImageFromCameraImage(
          image: image,
          camera: _cameras[0],
        );
        if (inputImage != null) {
          final barcodes = await _barcodeScanner.processImage(inputImage);
          if (barcodes.isNotEmpty && mounted) {
            final barcodeValue = barcodes.first.rawValue;
            if (barcodeValue != null && barcodeValue.isNotEmpty) {
              await _handleBarcodeScanned(barcodeValue);
            }
          }
        } else if (_lastScanTime == null ||
            now.difference(_lastScanTime!).inSeconds > 5) {
          setState(() {
            _scannerStatus = "Camera format not supported - use manual entry";
          });
        }
      } catch (e) {
        debugPrint("Error processing barcode: $e");
        if (mounted) {
          setState(() {
            _scannerStatus = "Scanner issue - try manual entry";
          });
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    _lastScanTime = DateTime.now();

    if (_catalog.containsKey(barcode)) {
      final product = _catalog[barcode]!;
      _addProductToCart(product);
      setState(() {
        _scannerStatus = "Scanned: ${product.name}";
      });
      return;
    }

    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();

    setState(() {
      _scannerStatus = "Looking up barcode: $barcode...";
    });

    final info = await _barcodeProductService.getProductInfoByBarcode(barcode);

    if (!mounted) return;

    if (info.containsKey('title') &&
        info['title'] != null &&
        info['title'].toString().trim().isNotEmpty) {
      final title = info['title'] as String;
      final brand = (info['brand'] as String?) ?? '';
      final imageUrl = (info['imageUrl'] as String?) ?? '';
      final double price = (info['lowestPrice'] as num?)?.toDouble() ?? 0.0;

      final newProduct = Product(
        barcode: barcode,
        name: title,
        description: brand.isNotEmpty ? brand : 'UPC: $barcode',
        price: price,
        imageUrl: imageUrl,
      );

      _catalog[barcode] = newProduct;
      _addProductToCart(newProduct);
      setState(() {
        _scannerStatus = "Added: ${newProduct.name}";
      });
    } else {
      final fallbackProduct = Product(
        barcode: barcode,
        name: 'Item #$barcode',
        description: 'Scanned item',
        price: 0.0,
        imageUrl: '',
      );

      _catalog[barcode] = fallbackProduct;
      _addProductToCart(fallbackProduct);
      setState(() {
        _scannerStatus = "Added: Item #$barcode (₹0.00)";
      });
    }
  }

  void _addProductToCart(Product product) {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();

    int newQuantity = 1;
    bool isExisting = false;

    for (var item in _cart) {
      if (item.product.barcode == product.barcode) {
        setState(() {
          item.quantity++;
          newQuantity = item.quantity;
          isExisting = true;
          _lastScannedBadge = "${product.name} (${newQuantity}x)";
        });
        break;
      }
    }

    if (!isExisting) {
      setState(() {
        _cart.add(CartItem(product: product));
        _lastScannedBadge = "${product.name} (1x)";
      });
    }

    showItemAddedSnackBar(context, product: product, quantity: newQuantity);
  }

  Future<void> _onAddCustomItem() async {
    final product = await showAddCustomItemDialog(context);
    if (product != null) {
      _addProductToCart(product);
    }
  }

  Future<void> _onAddDiscount() async {
    final discount = await showAddDiscountDialog(
      context,
      currentDiscount: _discount,
    );
    if (discount != null) {
      setState(() {
        _discount = discount;
      });
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      final nextFlash = !_isFlashOn;
      await _cameraController!.setFlashMode(
        nextFlash ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isFlashOn = nextFlash;
      });
    } catch (e) {
      debugPrint("Error toggling flash: $e");
    }
  }

  void _clearBill() {
    setState(() {
      _cart.clear();
      _discount = 0.0;
    });
  }

  double get _subtotal {
    return _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _total {
    final finalPrice = _subtotal - _discount;
    return finalPrice < 0 ? 0.0 : finalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: PosAppBar(isFlashOn: _isFlashOn, onToggleFlash: _toggleFlash),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final scanner = ScannerColumn(
            cameraController: _cameraController,
            isCameraInitialized: _isCameraInitialized,
            scannerStatus: _scannerStatus,
            lastScannedBadge: _lastScannedBadge,
          );
          final cart = CartColumn(
            cart: _cart,
            discount: _discount,
            subtotal: _subtotal,
            total: _total,
            onAddCustomItem: _onAddCustomItem,
            onAddDiscount: _onAddDiscount,
            onSaveDraft: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sale saved as draft')),
              );
              _clearBill();
            },
            onCheckout: () {
              showCheckoutCompleteDialog(
                context,
                total: _total,
                onConfirm: _clearBill,
              );
            },
            onIncrement: (index) {
              setState(() {
                _cart[index].quantity++;
              });
            },
            onDecrement: (index) {
              setState(() {
                if (_cart[index].quantity > 1) {
                  _cart[index].quantity--;
                } else {
                  _cart.removeAt(index);
                }
              });
            },
            onRemove: (index) {
              setState(() {
                _cart.removeAt(index);
              });
            },
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 12, child: scanner),
                const VerticalDivider(width: 1, color: Color(0xFFE5DFC9)),
                Expanded(flex: 13, child: cart),
              ],
            );
          }

          return Column(
            children: [
              Expanded(flex: 3, child: scanner),
              const Divider(height: 1, color: Color(0xFFE5DFC9)),
              Expanded(flex: 4, child: cart),
            ],
          );
        },
      ),
    );
  }
}
