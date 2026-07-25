/// Total spent within a single (normalized) category.
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.total,
    required this.count,
  });

  final String category;
  final double total;
  final int count;
}

/// Aggregated overview of all expenses, used by the Expenses dashboard.
class ExpenseSummary {
  const ExpenseSummary({
    required this.grandTotal,
    required this.totalCount,
    required this.categories,
    this.firstDate,
    this.lastDate,
  });

  final double grandTotal;
  final int totalCount;

  /// Category totals, sorted from highest to lowest spend.
  final List<CategoryTotal> categories;

  final DateTime? firstDate;
  final DateTime? lastDate;

  static const ExpenseSummary empty = ExpenseSummary(
    grandTotal: 0,
    totalCount: 0,
    categories: [],
  );
}
