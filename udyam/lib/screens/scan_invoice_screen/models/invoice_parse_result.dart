class InvoiceParseResult {
  final Map<String, dynamic>? invoice;

  const InvoiceParseResult._(this.invoice);

  const InvoiceParseResult.notInvoice() : invoice = null;

  factory InvoiceParseResult.invoice(Map<String, dynamic> invoice) =>
      InvoiceParseResult._(invoice);

  bool get isInvoice => invoice != null;
}
