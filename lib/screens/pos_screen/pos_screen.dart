import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Barcode Product Lookup API
// ---------------------------------------------------------------------------
Future<Map<String, dynamic>> getProductInfoByBarcode(String barcode) async {
  final url = Uri.parse(
    'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode',
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['items'] != null && (data['items'] as List).isNotEmpty) {
        final item = data['items'][0];

        // Extract price offers
        final List offersList = item['offers'] ?? [];
        final List<double> prices = offersList
            .where((o) => o['price'] != null)
            .map<double>((o) => (o['price'] as num).toDouble())
            .toList();

        // Extract product images
        final List imagesList = item['images'] ?? [];
        final String? primaryImage = imagesList.isNotEmpty
            ? imagesList[0]
            : null;

        return {
          'barcode': barcode,
          'title': item['title'],
          'brand': item['brand'],
          'imageUrl': primaryImage,
          'lowestPrice': prices.isNotEmpty
              ? prices.reduce((a, b) => a < b ? a : b)
              : null,
          'offers': offersList
              .map((o) => {'merchant': o['merchant'], 'price': o['price']})
              .toList(),
        };
      }
    }
  } catch (e) {
    return {'barcode': barcode, 'error': e.toString()};
  }

  return {'barcode': barcode, 'message': 'Product not found'};
}

// ---------------------------------------------------------------------------
// Product Model
// ---------------------------------------------------------------------------
class Product {
  final String barcode;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  const Product({
    required this.barcode,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}

// ---------------------------------------------------------------------------
// Cart Item Model
// ---------------------------------------------------------------------------
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with WidgetsBindingObserver {
  // Camera & Scanning variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  String _scannerStatus = "Point at barcode to scan";

  // ML Kit Barcode Scanner
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  // Cart & Catalog variables
  final List<CartItem> _cart = [];
  double _discount = 0.0;
  final TextEditingController _searchController = TextEditingController();

  // Mock product catalog mapped by barcode
  final Map<String, Product> _catalog = {
    '8901063016307': const Product(
      barcode: '8901063016307',
      name: 'Parle-G',
      description: '100g',
      price: 10.00,
      imageUrl: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=200&auto=format&fit=crop&q=60', // Placeholder chocolate/biscuit image
    ),
    '8901058897089': const Product(
      barcode: '8901058897089',
      name: 'Maggi Masala',
      description: '70g',
      price: 14.00,
      imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200&auto=format&fit=crop&q=60', // Noodle bowl placeholder
    ),
    '8901764012220': const Product(
      barcode: '8901764012220',
      name: 'Coca-Cola',
      description: '750ml',
      price: 40.00,
      imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=200&auto=format&fit=crop&q=60', // Soda can placeholder
    ),
    '7622300744111': const Product(
      barcode: '7622300744111',
      name: 'Oreo Vanilla',
      description: '118g',
      price: 20.00,
      imageUrl: 'https://images.unsplash.com/photo-1558961309-dbdf71799f5a?w=200&auto=format&fit=crop&q=60', // Cookie placeholder
    ),
  };

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

  // ---------------------------------------------------------------------------
  // Camera Setup
  // ---------------------------------------------------------------------------
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

      // Start processing frames from the camera feed
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

  // ---------------------------------------------------------------------------
  // Real-time Barcode Scanning
  // ---------------------------------------------------------------------------
  void _startScanner() {
    if (_cameraController == null) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;

      // 1. Enforce cooldown to avoid multiple rapid scans of the same item
      final now = DateTime.now();
      if (_lastScanTime != null &&
          now.difference(_lastScanTime!).inMilliseconds < 1500) {
        return;
      }

      _isProcessing = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) {
          final barcodes = await _barcodeScanner.processImage(inputImage);
          if (barcodes.isNotEmpty && mounted) {
            final barcodeValue = barcodes.first.rawValue;
            if (barcodeValue != null && barcodeValue.isNotEmpty) {
              await _handleBarcodeScanned(barcodeValue);
            }
          }
        } else {
          // Only update status occasionally to avoid UI spam
          if (_lastScanTime == null ||
              now.difference(_lastScanTime!).inSeconds > 5) {
            setState(() {
              _scannerStatus = "Camera format not supported - use manual entry";
            });
          }
        }
      } catch (e) {
        debugPrint("Error processing barcode: $e");
        // Update status to inform user of the issue
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

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameras[0];
    final sensorOrientation = camera.sensorOrientation;

    // Map rotation value
    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(
      sensorOrientation,
    );
    rotation ??= InputImageRotation.rotation0deg;

    // Map format value
    // On Android, ML Kit fromBytes only supports NV21 / YV12.
    // On iOS, it supports BGRA8888.
    final InputImageFormat format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;
    } else {
      format =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.bgra8888;
    }

    // Concatenate all plane bytes into a single buffer
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final size = Size(image.width.toDouble(), image.height.toDouble());

    final metadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  String? _lastScannedBadge;

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------
  Future<void> _handleBarcodeScanned(String barcode) async {
    _lastScanTime = DateTime.now();

    // 1. If product is already known in local catalog, add immediately
    if (_catalog.containsKey(barcode)) {
      final product = _catalog[barcode]!;
      _addProductToCart(product);
      setState(() {
        _scannerStatus = "Scanned: ${product.name}";
      });
      return;
    }

    // Trigger haptic feedback for initial scan recognition
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();

    // 2. Fetch product information from the barcode lookup API
    setState(() {
      _scannerStatus = "Looking up barcode: $barcode...";
    });

    final info = await getProductInfoByBarcode(barcode);

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
      // If not found in API, still add to cart with barcode identifier
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
    // 1. Strong haptic feedback & vibration to confirm item addition
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();

    int newQuantity = 1;
    bool isExisting = false;

    // Check if product already exists in cart and increment
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

    // 2. Trigger instant pop-up notification with count & price
    _showItemAddedPopup(product, newQuantity);
  }

  void _showItemAddedPopup(Product product, int quantity) {
    if (!mounted) return;

    // Instantly hide any previous snackbar to display the latest scan immediately
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final itemTotal = (product.price * quantity).toStringAsFixed(2);
    final countLabel = quantity == 1
        ? 'Added 1st time'
        : 'Added again (${quantity}x in bill)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        backgroundColor: const Color(0xFF2C2926),
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: quantity > 1
                    ? const Color(0xFFB8490C)
                    : const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                quantity > 1
                    ? Icons.plus_one_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$countLabel • ₹$itemTotal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE5DFC9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: quantity > 1
                    ? const Color(0xFFB8490C).withValues(alpha: 0.4)
                    : Colors.white24,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: quantity > 1
                      ? const Color(0xFFB8490C)
                      : Colors.white38,
                ),
              ),
              child: Text(
                '${quantity}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F3EB),
          title: const Text(
            'Add Custom Item',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2926),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Color(0xFF6C625C)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB8490C)),
                  ),
                ),
              ),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  labelStyle: TextStyle(color: Color(0xFF6C625C)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB8490C)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6C625C)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8490C),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final price =
                    double.tryParse(priceController.text.trim()) ?? 0.0;
                if (name.isNotEmpty && price > 0) {
                  final randomBarcode =
                      'custom_${DateTime.now().millisecondsSinceEpoch}';
                  final customProduct = Product(
                    barcode: randomBarcode,
                    name: name,
                    description: 'Custom Item',
                    price: price,
                    imageUrl: '',
                  );
                  _addProductToCart(customProduct);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDiscountDialog() {
    final discountController = TextEditingController(
      text: _discount.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F3EB),
          title: const Text(
            'Apply Discount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2926),
            ),
          ),
          content: TextField(
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Discount (₹)',
              labelStyle: TextStyle(color: Color(0xFF6C625C)),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB8490C)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6C625C)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8490C),
              ),
              onPressed: () {
                setState(() {
                  _discount =
                      double.tryParse(discountController.text.trim()) ?? 0.0;
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showManualBarcodeDialog() {
    final barcodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F3EB),
          title: const Text(
            'Enter Barcode Manually',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2926),
            ),
          ),
          content: TextField(
            controller: barcodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Barcode Number',
              labelStyle: TextStyle(color: Color(0xFF6C625C)),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB8490C)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6C625C)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8490C),
              ),
              onPressed: () {
                final barcode = barcodeController.text.trim();
                if (barcode.isNotEmpty) {
                  _handleBarcodeScanned(barcode);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
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

  double get _subtotal {
    return _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _total {
    final finalPrice = _subtotal - _discount;
    return finalPrice < 0 ? 0.0 : finalPrice;
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EB),
        foregroundColor: const Color(0xFF2C2926),
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Sale',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF2C2926),
              ),
            ),
            Text(
              'Scan barcode to add products',
              style: TextStyle(fontSize: 12, color: Color(0xFF6C625C)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: const Color(0xFFB8490C),
            ),
            tooltip: 'Flash',
            onPressed: _toggleFlash,
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsively build side-by-side or stacked layout based on screen width
                final isWide = constraints.maxWidth > 600;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 12, child: _buildScannerColumn()),
                      const VerticalDivider(width: 1, color: Color(0xFFE5DFC9)),
                      Expanded(flex: 13, child: _buildCartColumn()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(flex: 3, child: _buildScannerColumn()),
                      const Divider(height: 1, color: Color(0xFFE5DFC9)),
                      Expanded(flex: 4, child: _buildCartColumn()),
                    ],
                  );
                }
              },
            ),
          ),
          //_buildBottomSearchBar(),
        ],
      ),
    );
  }

  Widget _buildScannerColumn() {
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
          // Camera Preview
          _isCameraInitialized && _cameraController != null
              ? AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB8490C)),
                ),

          // Live scanner header overlay
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
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
                  _scannerStatus,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          // Camera viewport scanning overlay brackets
          Center(
            child: Container(
              width: 220,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Laser scanning line animation
                  Center(
                    child: Container(
                      height: 2,
                      width: 200,
                      color: Colors.greenAccent,
                    ),
                  ),
                  // Green corner graphics
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // Real-time Scanned item badge overlay
          if (_lastScannedBadge != null)
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
                          _lastScannedBadge!,
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

          // Scanner bottom controls overlay
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Manual Button
                // IconButton(
                //   style: IconButton.styleFrom(
                //     backgroundColor: Colors.white24,
                //     foregroundColor: Colors.white,
                //   ),
                //   icon: const Icon(Icons.keyboard),
                //   tooltip: "Enter barcode manually",
                //   onPressed: _showManualBarcodeDialog,
                // ),

                // Scanner status indicator
                if (!_isCameraInitialized)
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
                // Zoom control badge
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 10,
                //     vertical: 5,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.white24,
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: const Text(
                //     '1.0x',
                //     style: TextStyle(
                //       color: Colors.white,
                //       fontWeight: FontWeight.bold,
                //       fontSize: 12,
                //     ),
                //   ),
                // ),
                // Add Barcode Trigger button
                // IconButton(
                //   style: IconButton.styleFrom(
                //     backgroundColor: Colors.white,
                //     foregroundColor: const Color(0xFFB8490C),
                //   ),
                //   icon: const Icon(Icons.qr_code_scanner),
                //   tooltip: "Manual barcode entry",
                //   onPressed: _showManualBarcodeDialog,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    const double length = 16.0;
    const double thickness = 3.0;
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: length,
        height: length,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: 0,
              right: 0,
              child: Container(height: thickness, color: Colors.greenAccent),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(width: thickness, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartColumn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bill title with item count badge
          Row(
            children: [
              const Text(
                'Current Bill',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2926),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6F4DF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_cart.length}',
                  style: const TextStyle(
                    color: Color(0xFF263B2B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cart Items List
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'No items in bill.\nScan a product or search to add.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6C625C), fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: _cart.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFE5DFC9)),
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Product Image / Icon
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5DFC9),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item.product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.shopping_bag_outlined,
                                                color: Color(0xFFB8490C),
                                              ),
                                    )
                                  : const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Color(0xFFB8490C),
                                    ),
                            ),
                            const SizedBox(width: 12),

                            // Item details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF2C2926),
                                    ),
                                  ),
                                  Text(
                                    item.product.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6C625C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2C2926),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Total Price & Deletion Trash Can
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF2C2926),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20,
                                        color: Color(0xFF6C625C),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (item.quantity > 1) {
                                            item.quantity--;
                                          } else {
                                            _cart.removeAt(index);
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                        color: Color(0xFFB8490C),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          item.quantity++;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _cart.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Custom Add Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB8490C),
              side: const BorderSide(color: Color(0xFFB8490C)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add custom item'),
            onPressed: _showAddCustomItemDialog,
          ),
          const SizedBox(height: 12),

          // Checkout Calculation Cards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5DFC9)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(color: Color(0xFF6C625C)),
                    ),
                    Text(
                      '₹${_subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discount',
                      style: TextStyle(color: Color(0xFF6C625C)),
                    ),
                    GestureDetector(
                      onTap: _showAddDiscountDialog,
                      child: Text(
                        _discount > 0
                            ? '-₹${_discount.toStringAsFixed(2)}'
                            : 'Add',
                        style: const TextStyle(
                          color: Color(0xFFB8490C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFE5DFC9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFB8490C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cart bottom checkout buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB8490C),
                    side: const BorderSide(color: Color(0xFFB8490C)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _cart.isEmpty
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sale saved as draft'),
                            ),
                          );
                          setState(() {
                            _cart.clear();
                            _discount = 0.0;
                          });
                        },
                  child: const Text('Save as draft'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB8490C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _cart.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFFF7F3EB),
                              title: const Text('Checkout Complete'),
                              content: Text(
                                'Collected ₹${_total.toStringAsFixed(2)} successfully!',
                              ),
                              actions: [
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB8490C),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _cart.clear();
                                      _discount = 0.0;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                  child: Text('Collect ₹${_total.toStringAsFixed(2)}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      color: const Color(0xFFF7F3EB),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5DFC9)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF6C625C)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  final text = value.trim();
                  if (text.isNotEmpty) {
                    // Search in catalog first
                    var found = false;
                    for (var product in _catalog.values) {
                      if (product.name.toLowerCase() == text.toLowerCase()) {
                        _addProductToCart(product);
                        found = true;
                        break;
                      }
                    }
                    if (!found) {
                      // Prompt dialog with input
                      final randomBarcode =
                          'manual_${DateTime.now().millisecondsSinceEpoch}';
                      final manualProduct = Product(
                        barcode: randomBarcode,
                        name: text,
                        description: 'Manual entry',
                        price: 15.00,
                        imageUrl: '',
                      );
                      _addProductToCart(manualProduct);
                    }
                    _searchController.clear();
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Search or add item manually',
                  hintStyle: TextStyle(color: Color(0xFFBFB5AE), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Icon(Icons.mic, color: Color(0xFF6C625C)),
          ],
        ),
      ),
    );
  }
}
