import 'dart:convert';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/invoice_parse_result.dart';

/// Parses OCR text locally with SmolLM2 135M. The model is deliberately asked
/// for a sentinel first, so ordinary camera text is never treated as an invoice.
class InvoiceAiParser {
  InvoiceAiParser._();

  static final instance = InvoiceAiParser._();
  static const _modelUrl =
      'https://huggingface.co/litert-community/SmolLM2-135M-Instruct/'
      'resolve/main/SmolLM2_135M_Instruct.litertlm';

  Future<void>? _prepareModel;

  Future<InvoiceParseResult> parse(String text) async {
    if (text.trim().isEmpty) return const InvoiceParseResult.notInvoice();

    try {
      await (_prepareModel ??= _ensureModel());
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 1280,
        preferredBackend: PreferredBackend.cpu,
      );
      try {
        final chat = await model.createChat(
          modelType: ModelType.general,
          temperature: 0.1,
          maxOutputTokens: 400,
        );
        await chat.addQueryChunk(
          Message.text(text: _prompt(text), isUser: true),
        );
        final response = await chat.generateChatResponse();
        if (response is! TextResponse) {
          return const InvoiceParseResult.notInvoice();
        }
        return _parseResponse(response.token);
      } finally {
        await model.close();
      }
    } catch (_) {
      // Do not guess an invoice from OCR text when the local model cannot run.
      return const InvoiceParseResult.notInvoice();
    }
  }

  Future<void> _ensureModel() async {
    try {
      final model = await FlutterGemma.getActiveModel(maxTokens: 1280);
      await model.close();
    } catch (_) {
      await FlutterGemma.installModel(
        modelType: ModelType.general,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(_modelUrl).install();
    }
  }

  String _prompt(String text) =>
      '''
You extract structured data from OCR text.
Decide whether the text is a business invoice. If it is not an invoice, reply
with exactly: NOT_AN_INVOICE

If it is an invoice, reply with exactly one valid JSON object and no Markdown,
explanation, or extra keys. Use this exact schema:
{"invoice_number": string|null, "date": "YYYY-MM-DD"|null, "supplier": {"name": string|null, "phone": string|null}, "items": [{"name": string, "quantity": number|null, "unit": string|null, "unit_price": number|null, "total": number|null}], "subtotal": number|null, "tax": number|null, "grand_total": number|null}

Never invent values. Convert dates only when the date is unambiguous. Keep phone
numbers as strings and money/quantities as JSON numbers.

OCR text:
${text.trim().substring(0, text.trim().length > 1800 ? 1800 : text.trim().length)}
''';

  InvoiceParseResult _parseResponse(String response) {
    final trimmed = response
        .trim()
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    if (trimmed == 'NOT_AN_INVOICE') {
      return const InvoiceParseResult.notInvoice();
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) return const InvoiceParseResult.notInvoice();

    try {
      final decoded = jsonDecode(trimmed.substring(start, end + 1));
      if (decoded is! Map<String, dynamic> || !_hasInvoiceSchema(decoded)) {
        return const InvoiceParseResult.notInvoice();
      }
      return InvoiceParseResult.invoice(decoded);
    } on FormatException {
      return const InvoiceParseResult.notInvoice();
    }
  }

  bool _hasInvoiceSchema(Map<String, dynamic> value) {
    const keys = {
      'invoice_number',
      'date',
      'supplier',
      'items',
      'subtotal',
      'tax',
      'grand_total',
    };
    final supplier = value['supplier'];
    return value.keys.toSet().containsAll(keys) &&
        supplier is Map &&
        supplier.containsKey('name') &&
        supplier.containsKey('phone') &&
        value['items'] is List;
  }
}
