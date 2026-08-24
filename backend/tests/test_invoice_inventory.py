import unittest
from decimal import Decimal

from app.services.gemini import GeminiResponseError, parse_invoice_response
from app.services.inventory import normalize_product_text


class InvoiceResponseParsingTests(unittest.TestCase):
    def test_parses_fenced_json_with_decimal_values(self):
        result = parse_invoice_response(
            """```json
            {
              "invoice_number": "INV-7",
              "date": "2026-08-24",
              "supplier": {"name": "Acme", "phone": null},
              "items": [{"name": "Rice", "quantity": 2.5, "unit": "kg",
                         "unit_price": 10.25, "total": 25.625}],
              "subtotal": 25.625, "tax": null, "grand_total": 25.625
            }
            ```"""
        )

        self.assertEqual(result.items[0].quantity, Decimal("2.5"))
        self.assertEqual(result.grand_total, Decimal("25.625"))

    def test_extracts_json_from_surrounding_text(self):
        result = parse_invoice_response(
            'Here is the result: {"invoice_number":null,"date":null,'
            '"supplier":{"name":null,"phone":null},'
            '"items":[{"name":"Soap","quantity":null,"unit":null,'
            '"unit_price":null,"total":null}],"subtotal":null,'
            '"tax":null,"grand_total":null}'
        )
        self.assertEqual(result.items[0].name, "Soap")

    def test_rejects_non_json_response(self):
        with self.assertRaises(GeminiResponseError):
            parse_invoice_response("I could not read this invoice")


class InventoryNormalizationTests(unittest.TestCase):
    def test_normalizes_case_unicode_and_whitespace(self):
        self.assertEqual(normalize_product_text("  RICE   Flour "), "rice flour")
        self.assertEqual(normalize_product_text("ＫＧ"), "kg")


if __name__ == "__main__":
    unittest.main()
