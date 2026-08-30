from __future__ import annotations

from decimal import Decimal

from app.schemas.khata import RestockAlert, VendorRecommendation


def build_vendor_recommendations(
    item_name: str,
    required_quantity: Decimal | int | float | str,
    unit: str = "kg",
) -> list[VendorRecommendation]:
    quantity = Decimal(str(required_quantity)).quantize(Decimal("0.01"))
    if quantity <= 0:
        quantity = Decimal("1")

    item_key = item_name.lower().strip()
    demand_multiplier = Decimal("1.00")
    if "apple" in item_key:
        demand_multiplier = Decimal("1.05")
    elif "milk" in item_key:
        demand_multiplier = Decimal("1.00")

    vendors = [
        {
            "vendor_name": "Green Valley Farms",
            "quoted_price_per_unit": Decimal("24.50") * demand_multiplier,
            "discount_pct": Decimal("18.0"),
            "lead_time_days": 2,
            "rating": Decimal("4.9"),
            "contact_number": "+91 98765 43210",
            "notes": "Best overall value and strongest discount on bulk price.",
        },
        {
            "vendor_name": "City Fresh Supply",
            "quoted_price_per_unit": Decimal("25.20") * demand_multiplier,
            "discount_pct": Decimal("15.0"),
            "lead_time_days": 1,
            "rating": Decimal("4.7"),
            "contact_number": "+91 98211 33445",
            "notes": "Fastest lead time with a competitive bulk offer.",
        },
        {
            "vendor_name": "Nirmal Traders",
            "quoted_price_per_unit": Decimal("26.75") * demand_multiplier,
            "discount_pct": Decimal("11.0"),
            "lead_time_days": 3,
            "rating": Decimal("4.6"),
            "contact_number": "+91 98100 22881",
            "notes": "Reliable supplier for repeat seasonal fruit orders.",
        },
    ]

    ranked = []
    for raw_vendor in vendors:
        quoted = raw_vendor["quoted_price_per_unit"]
        discount_pct = raw_vendor["discount_pct"]
        final_total = (quoted * quantity) * (Decimal("1") - (discount_pct / Decimal("100")))
        ranked.append(
            VendorRecommendation(
                item_name=item_name,
                vendor_name=raw_vendor["vendor_name"],
                quoted_price_per_unit=quoted.quantize(Decimal("0.01")),
                discount_pct=discount_pct,
                final_total=final_total.quantize(Decimal("0.01")),
                lead_time_days=raw_vendor["lead_time_days"],
                rating=raw_vendor["rating"],
                rank=0,
                required_quantity=quantity,
                unit=unit,
                notes=raw_vendor["notes"],
                contact_number=raw_vendor["contact_number"],
            )
        )

    ranked.sort(
        key=lambda row: (
            -row.discount_pct,
            row.final_total,
            row.lead_time_days,
            -row.rating,
        )
    )
    for index, recommendation in enumerate(ranked, start=1):
        recommendation.rank = index
        recommendation.is_notification_target = index == 1
    return ranked


def build_vendor_recommendations_for_alerts(
    alerts: list[RestockAlert],
) -> list[VendorRecommendation]:
    if not alerts:
        return []

    restock_alerts = [
        alert for alert in alerts if alert.alert_type == "restock" and alert.severity in {"critical", "warning"}
    ]
    if not restock_alerts:
        return []

    urgent = sorted(restock_alerts, key=lambda alert: (alert.severity != "critical", alert.days_until_stockout, alert.current_stock))
    top_alert = urgent[0]
    return build_vendor_recommendations(
        item_name=top_alert.item_name,
        required_quantity=top_alert.suggested_restock_qty,
        unit=top_alert.unit,
    )


def format_vendor_telegram_message(
    recommendations: list[VendorRecommendation],
    item_name: str | None = None,
    required_quantity: Decimal | int | float | str | None = None,
    unit: str | None = None,
) -> str:
    if not recommendations:
        return "No vendor recommendations available."

    first = recommendations[0]
    item_label = (
        item_name
        or getattr(first, "item_name", None)
        or "inventory item"
    )
    quantity_value = (
        required_quantity if required_quantity is not None else first.required_quantity
    )
    quantity = Decimal(str(quantity_value)).quantize(Decimal("0.01"))
    quantity_text = format(quantity.normalize(), "f")
    if "." in quantity_text:
        quantity_text = quantity_text.rstrip("0").rstrip(".")
    unit_label = unit or first.unit

    lines = [
        f"Low-stock restock request: {item_label} - {quantity_text} {unit_label}",
        "",
        "Recommended vendor ranking:",
    ]

    for recommendation in recommendations:
        target_marker = " (notification recipient)" if recommendation.is_notification_target else ""
        lines.append(
            f"{recommendation.rank}. {recommendation.vendor_name}{target_marker} | "
            f"₹{recommendation.quoted_price_per_unit}/{unit_label} | "
            f"{recommendation.discount_pct}% off | "
            f"₹{recommendation.final_total} total | "
            f"{recommendation.lead_time_days}-day lead time | "
            f"{recommendation.rating}/5 rating"
        )

    lines.append("")
    lines.append(
        f"Notification recipient: {recommendations[0].vendor_name} | "
        f"Contact: {recommendations[0].contact_number}"
    )
    return "\n".join(lines)
