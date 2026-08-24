enum BusinessType { kirana, bakery, vegetable, hardware, other }

extension BusinessTypeApiValue on BusinessType {
  String toApiValue(String customValue) {
    if (this == BusinessType.other) return customValue.trim();
    return name;
  }
}
