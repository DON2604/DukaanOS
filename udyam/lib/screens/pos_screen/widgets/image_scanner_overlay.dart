import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';

import '../services/image_recognition_service.dart';
import '../models/product.dart';

class ImageScannerOverlay extends StatefulWidget {
  final Function(Product) onProductIdentified;
  final CameraController? cameraController;

  const ImageScannerOverlay({
    super.key,
    required this.onProductIdentified,
    this.cameraController,
  });

  @override
  State<ImageScannerOverlay> createState() => _ImageScannerOverlayState();
}

class _ImageScannerOverlayState extends State<ImageScannerOverlay> {
  bool _isAnalyzing = false;
  String _status = "Tap capture to scan image for products";

  Future<void> _captureAndAnalyze() async {
    if (_isAnalyzing || widget.cameraController == null) return;

    setState(() {
      _isAnalyzing = true;
      _status = "Capturing image...";
    });

    // Declared outside the try so the temporary capture is always cleaned up,
    // including when the analysis fails or the widget unmounts mid-request.
    File? file;

    try {
      // Capture image
      final XFile imageFile = await widget.cameraController!.takePicture();
      file = File(imageFile.path);

      setState(() {
        _status = "Analyzing image for products...";
      });

      // Analyze the image and match with inventory
      final matches = await ImageRecognitionService.matchWithInventory(file);

      if (!mounted) return;

      if (matches.isEmpty) {
        setState(() {
          _status = "No products identified in image";
        });
        _showNoProductsDialog();
      } else {
        for (final match in matches) {
          _addProductToCart(match);
        }

        setState(() {
          _status = "Added ${matches.length} product${matches.length == 1 ? '' : 's'} to bill";
        });
      }
    } catch (e) {
      if (!mounted) return;

      // ImageRecognitionException.toString() is already a user-facing message
      // (e.g. the quota notice from the server), so show it as-is.
      final message = e is ImageRecognitionException
          ? e.message
          : 'Image analysis failed: $e';

      setState(() {
        _status = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: e is ImageRecognitionException && e.isQuotaExceeded
              ? Colors.orange.shade800
              : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (file != null) {
        // Best effort: a leftover temp file is not worth surfacing to the user.
        try {
          await file.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        // Reset status after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _status = "Tap capture to scan image for products";
            });
          }
        });
      }
    }
  }

  void _showNoProductsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Products Found'),
        content: const Text(
          'No products were identified in the image. Try capturing a clearer image with better lighting.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _status = "Tap capture to scan image for products";
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProductSelectionDialog(List<InventoryMatch> matches) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Identified Products'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final product = match.recognizedProduct;
              final inventory = match.inventoryMatch;

              final canAddManually = match.canDeduct || inventory == null;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    canAddManually ? Icons.check_circle : Icons.warning,
                    color: canAddManually ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${product.category}'),
                      if (product.estimatedWeight != null) ...[
                        Text(
                          'Est. Weight: ${product.estimatedWeight!.toStringAsFixed(0)}g',
                        ),
                        if (match.suggestedQuantity != 1.0 && inventory != null)
                          Text(
                            'Suggested: ${match.suggestedQuantity.toStringAsFixed(2)} ${inventory.unit ?? "units"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB8490C),
                            ),
                          ),
                      ],
                      if (inventory != null)
                        Text(
                          'Available: ${inventory.quantity?.toStringAsFixed(1)} ${inventory.unit ?? "units"}',
                          style: TextStyle(
                            color: match.canDeduct ? Colors.green : Colors.red,
                          ),
                        ),
                      if (match.insufficientStockMessage != null)
                        Text(
                          match.insufficientStockMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      Text(
                        'Confidence: ${(product.confidence * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  trailing: canAddManually
                      ? ElevatedButton(
                          onPressed: () => _addProductToCart(match),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB8490C),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add'),
                        )
                      : Text(
                          inventory == null
                              ? 'Not in\nInventory'
                              : 'Out of\nStock',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _status = "Tap capture to scan image for products";
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProductToCart(InventoryMatch match) async {
    try {
      final inventory = match.inventoryMatch;
      final referenceId = const Uuid().v4();
      final quantity = match.suggestedQuantity > 0 ? match.suggestedQuantity : 1.0;

      final product = Product(
        barcode: inventory != null
            ? 'IMG_${inventory.inventoryItemId}'
            : 'IMG_${referenceId}',
        name: match.recognizedProduct.name,
        description: inventory?.description ?? match.recognizedProduct.description,
        price: inventory?.price ?? 50.0,
        imageUrl: inventory?.imageUrl ?? '',
        inventoryItemId: inventory?.inventoryItemId,
        quantity: inventory?.quantity ?? quantity,
        unit: inventory?.unit ?? 'pcs',
        category: inventory?.category ?? match.recognizedProduct.category,
      );

      widget.onProductIdentified(product);

      HapticFeedback.heavyImpact();

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _status = "Added: ${match.recognizedProduct.name}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${match.recognizedProduct.name} to bill'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Status text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Image recognition frame
          Expanded(
            child: Center(
              child: Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Corner indicators
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: Icon(
                        Icons.crop_free,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.crop_free,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      left: 8,
                      child: Icon(
                        Icons.crop_free,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: Icon(
                        Icons.crop_free,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),

                    // Center instructions
                    if (!_isAnalyzing)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.orange,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Position fruits or vegetables\nin the frame',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    // Loading indicator
                    if (_isAnalyzing)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.orange),
                            SizedBox(height: 8),
                            Text(
                              'Analyzing...',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Capture button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _captureAndAnalyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8490C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isAnalyzing ? Icons.hourglass_empty : Icons.camera_alt),
                  const SizedBox(width: 8),
                  Text(_isAnalyzing ? 'Analyzing...' : 'Capture & Scan'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
