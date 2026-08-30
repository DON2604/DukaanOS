import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants.dart';
import '../models/product.dart';

class RecognizedProduct {
  final String name;
  final String category;
  final double? estimatedWeight;
  final double confidence;
  final String description;

  RecognizedProduct({
    required this.name,
    required this.category,
    this.estimatedWeight,
    required this.confidence,
    required this.description,
  });

  static double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  factory RecognizedProduct.fromJson(Map<String, dynamic> json) {
    return RecognizedProduct(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      estimatedWeight: _toDouble(json['estimated_weight'], fallback: 0.0) == 0.0
          ? null
          : _toDouble(json['estimated_weight'], fallback: 0.0),
      confidence: _toDouble(json['confidence']),
      description: json['description'] ?? '',
    );
  }
}

class ImageAnalysisResult {
  final List<RecognizedProduct> products;
  final double? totalEstimatedWeight;
  final String imageQuality;
  final String? error;

  ImageAnalysisResult({
    required this.products,
    this.totalEstimatedWeight,
    required this.imageQuality,
    this.error,
  });

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(
      products:
          (json['products'] as List<dynamic>?)
              ?.map((p) => RecognizedProduct.fromJson(p))
              .toList() ??
          [],
      totalEstimatedWeight: json['total_estimated_weight']?.toDouble(),
      imageQuality: json['image_quality'] ?? 'poor',
      error: json['error'],
    );
  }
}

class InventoryMatch {
  final RecognizedProduct recognizedProduct;
  final Product? inventoryMatch;
  final double matchConfidence;
  final bool canDeduct;
  final double suggestedQuantity;
  final String? insufficientStockMessage;

  InventoryMatch({
    required this.recognizedProduct,
    this.inventoryMatch,
    required this.matchConfidence,
    required this.canDeduct,
    this.suggestedQuantity = 1.0,
    this.insufficientStockMessage,
  });

  static double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  factory InventoryMatch.fromJson(Map<String, dynamic> json) {
    return InventoryMatch(
      recognizedProduct: RecognizedProduct.fromJson(json['recognized_product']),
      inventoryMatch: json['inventory_match'] != null
          ? Product.fromInventoryJson(json['inventory_match'])
          : null,
      matchConfidence: _toDouble(json['match_confidence']),
      canDeduct: json['can_deduct'] ?? false,
      suggestedQuantity: _toDouble(json['suggested_quantity'], fallback: 1.0),
      insufficientStockMessage: json['insufficient_stock_message'],
    );
  }
}

/// An image recognition failure with a message already fit to show the user.
///
/// toString() returns the bare message so it does not read as
/// "Exception: Exception: ..." when interpolated into a snackbar.
class ImageRecognitionException implements Exception {
  final String message;
  final int? statusCode;

  ImageRecognitionException(this.message, {this.statusCode});

  /// True when the backend reported the Gemini quota as spent (HTTP 429).
  bool get isQuotaExceeded => statusCode == 429;

  @override
  String toString() => message;
}

class ImageRecognitionService {
  /// Turns a non-200 response into an exception carrying the server's detail.
  static ImageRecognitionException _errorFor(
    http.Response response,
    String fallback,
  ) {
    String detail = fallback;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        detail = decoded['detail'] as String;
      }
    } catch (_) {
      // Non-JSON error body (proxy error page, empty response); keep fallback.
    }
    return ImageRecognitionException(detail, statusCode: response.statusCode);
  }

  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  /// Builds the upload part for an image file.
  ///
  /// The content type must be set explicitly: without it MultipartFile defaults
  /// to application/octet-stream and the backend rejects the upload as not an
  /// image. The subtype is taken from the file extension so PNG captures are not
  /// mislabelled as JPEG.
  static Future<http.MultipartFile> _imagePart(File imageFile) async {
    final path = imageFile.path.toLowerCase();
    final String subtype;
    if (path.endsWith('.png')) {
      subtype = 'png';
    } else if (path.endsWith('.webp')) {
      subtype = 'webp';
    } else if (path.endsWith('.heic') || path.endsWith('.heif')) {
      subtype = 'heic';
    } else {
      subtype = 'jpeg';
    }

    return http.MultipartFile.fromBytes(
      'file',
      await imageFile.readAsBytes(),
      filename: 'image.${subtype == 'jpeg' ? 'jpg' : subtype}',
      contentType: MediaType('image', subtype),
    );
  }

  static Map<String, String> _getAuthHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<ImageAnalysisResult> analyzeImage(File imageFile) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.imageRecognitionAnalyze}',
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await _imagePart(imageFile));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ImageAnalysisResult.fromJson(data);
      }
      throw _errorFor(response, 'Failed to analyze image');
    } on ImageRecognitionException {
      rethrow;
    } catch (e) {
      throw ImageRecognitionException('Image analysis failed: $e');
    }
  }

  static Future<List<InventoryMatch>> matchWithInventory(File imageFile) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.imageRecognitionMatch}',
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await _imagePart(imageFile));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => InventoryMatch.fromJson(item)).toList();
      }
      throw _errorFor(response, 'Failed to match with inventory');
    } on ImageRecognitionException {
      rethrow;
    } catch (e) {
      throw ImageRecognitionException('Inventory matching failed: $e');
    }
  }

  static Future<void> deductInventory({
    required String inventoryItemId,
    required double quantity,
    String? referenceId,
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.inventoryDeduct}',
      );

      final response = await http.post(
        uri,
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'inventory_item_id': inventoryItemId,
          'quantity': quantity,
          if (referenceId != null) 'reference_id': referenceId,
        }),
      );

      if (response.statusCode != 200) {
        throw _errorFor(response, 'Failed to deduct inventory');
      }
    } on ImageRecognitionException {
      rethrow;
    } catch (e) {
      throw ImageRecognitionException('Inventory deduction failed: $e');
    }
  }
}
