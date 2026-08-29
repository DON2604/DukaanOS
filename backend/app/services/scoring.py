from dataclasses import dataclass
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Literal

from app.models.khata import KhataEntry

ZERO = Decimal("0")
ONE_HUNDRED = Decimal("100")


@dataclass
class CustomerScoreResult:
    score: int
    category: Literal["good", "moderate", "bad"]
    trust_label: str
    payment_count: int
    credit_count: int
    total_credit: Decimal
    total_paid: Decimal
    repayment_rate: Decimal
    payment_probability_pct: int
    payment_probability_label: str
    credit_recommendation: str
    reasons: list[str]


def calculate_customer_score(
    entries: list[KhataEntry],
    balance: Decimal,
    as_of: datetime | None = None,
) -> CustomerScoreResult:
    """
    Evaluates customer debt repayment history and returns a 0-100 score,
    risk category ('good', 'moderate', 'bad'), repayment metrics, and likelihood
    of paying future debts.
    """
    as_of_date = (as_of or datetime.now(timezone.utc)).date()

    valid_entries = [e for e in entries if not e.is_deleted]
    credit_entries = [e for e in valid_entries if e.entry_type == "credit"]
    payment_entries = [e for e in valid_entries if e.entry_type == "payment"]

    credit_count = len(credit_entries)
    payment_count = len(payment_entries)

    total_credit = sum((Decimal(str(e.amount)) for e in credit_entries), ZERO)
    total_paid = sum((Decimal(str(e.amount)) for e in payment_entries), ZERO)

    reasons: list[str] = []

    # Case 1: No previous credit or payment transactions
    if credit_count == 0 and payment_count == 0:
        return CustomerScoreResult(
            score=70,
            category="moderate",
            trust_label="Moderate (New Customer)",
            payment_count=0,
            credit_count=0,
            total_credit=ZERO,
            total_paid=ZERO,
            repayment_rate=ONE_HUNDRED,
            payment_probability_pct=70,
            payment_probability_label="Moderate (70%)",
            credit_recommendation="Eligible for initial trial credit up to ₹1,000 (15 days terms).",
            reasons=["New customer with no prior credit history."],
        )

    # Repayment Rate
    if total_credit > ZERO:
        raw_rate = (total_paid / total_credit) * ONE_HUNDRED
        repayment_rate = max(ZERO, min(ONE_HUNDRED, round(raw_rate, 2)))
    else:
        repayment_rate = ONE_HUNDRED

    # 1. Repayment Volume & Clearance Component (Max 40 pts)
    if total_credit > ZERO:
        rate_points = float(repayment_rate / ONE_HUNDRED) * 40.0
    else:
        rate_points = 40.0

    # 2. Payment Consistency & Frequency Component (Max 30 pts)
    if credit_count > 0:
        freq_ratio = min(1.0, payment_count / credit_count)
        consistency_points = freq_ratio * 25.0
        if payment_count >= credit_count and payment_count > 0:
            consistency_points += 5.0
    else:
        consistency_points = 30.0

    # 3. Current Outstanding Balance & Overdue Component (Max 30 pts)
    has_overdue = False
    for e in credit_entries:
        if e.due_date and e.due_date < as_of_date and balance > ZERO:
            has_overdue = True
            break

    if balance <= ZERO:
        balance_points = 30.0
    else:
        if total_credit > ZERO:
            unpaid_ratio = float(min(Decimal("1.0"), balance / total_credit))
        else:
            unpaid_ratio = 1.0
        balance_points = max(0.0, 30.0 * (1.0 - unpaid_ratio))
        if has_overdue:
            balance_points = max(0.0, balance_points - 15.0)

    # Calculate final composite score (0-100)
    raw_score = int(round(rate_points + consistency_points + balance_points))
    score = max(0, min(100, raw_score))

    # Reasons & insights explanation
    if payment_count > 0:
        reasons.append(
            f"Paid debt {payment_count} time{'s' if payment_count > 1 else ''} "
            f"out of {credit_count} credit transaction{'s' if credit_count > 1 else ''} "
            f"({repayment_rate:.0f}% cumulative repayment rate)."
        )
    else:
        reasons.append(
            f"No payments recorded yet against {credit_count} credit transaction{'s' if credit_count > 1 else ''} "
            f"(₹{total_credit:.2f} total credit taken)."
        )

    if balance <= ZERO:
        reasons.append("Zero outstanding debt • All dues fully cleared.")
    else:
        reasons.append(f"Current outstanding balance: ₹{balance:.2f}.")

    if has_overdue:
        reasons.append("Has overdue debt past the promised due date.")

    # Segregation & Categorization
    if score >= 75:
        category: Literal["good", "moderate", "bad"] = "good"
        trust_label = "Good (Trusted Payer)"
        payment_prob = max(80, min(98, score))
        payment_prob_label = f"Very High ({payment_prob}%)" if payment_prob >= 90 else f"High ({payment_prob}%)"
        credit_recommendation = (
            "Safe for high credit up to ₹5,000 • 30 days terms • Auto-approval recommended."
        )
    elif score >= 50:
        category = "moderate"
        trust_label = "Moderate (Average Payer)"
        payment_prob = max(50, min(79, score))
        payment_prob_label = f"Moderate ({payment_prob}%)"
        credit_recommendation = (
            "Safe for moderate credit up to ₹1,500 • 15 days terms • Regular follow-up advised."
        )
    else:
        category = "bad"
        trust_label = "High Risk (Poor Payer)"
        payment_prob = max(5, min(45, score))
        payment_prob_label = f"Low ({payment_prob}%)"
        credit_recommendation = (
            "High risk of default • Cash-only recommended or max ₹300 micro-credit with upfront terms."
        )

    return CustomerScoreResult(
        score=score,
        category=category,
        trust_label=trust_label,
        payment_count=payment_count,
        credit_count=credit_count,
        total_credit=total_credit,
        total_paid=total_paid,
        repayment_rate=repayment_rate,
        payment_probability_pct=payment_prob,
        payment_probability_label=payment_prob_label,
        credit_recommendation=credit_recommendation,
        reasons=reasons,
    )
