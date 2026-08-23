class InvoiceFields {
  final String number;
  final String date;
  final String total;

  const InvoiceFields({
    required this.number,
    required this.date,
    required this.total,
  });

  bool get hasMissingFields =>
      number == 'Not detected' ||
      date == 'Not detected' ||
      total == 'Not detected';

  factory InvoiceFields.fromText(String text) {
    String find(RegExp pattern) =>
        pattern.firstMatch(text)?.group(1)?.trim() ?? 'Not detected';

    return InvoiceFields(
      number: find(
        RegExp(
          r'(?:invoice|bill|inv)[\s._-]*(?:no|number|#)?\s*[:#-]?\s*([A-Z0-9][A-Z0-9./_-]*)',
          caseSensitive: false,
        ),
      ),
      date: find(
        RegExp(
          r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b',
        ),
      ),
      total: find(
        RegExp(
          r'(?:grand\s+total|net\s+total|total\s+due|total)\s*[:.-]?\s*(?:rs\.?|inr|₹)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)',
          caseSensitive: false,
        ),
      ),
    );
  }
}
