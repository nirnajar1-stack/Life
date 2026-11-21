/// One category budget row for a calendar month (`monthly_budgets`).
class MonthlyBudgetModel {
  const MonthlyBudgetModel({
    required this.id,
    required this.year,
    required this.month,
    required this.category,
    required this.budgetAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int year;
  final int month;
  final String category;
  final double budgetAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MonthlyBudgetModel.fromJson(Map<String, dynamic> json) {
    return MonthlyBudgetModel(
      id: json['id'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      category: (json['category'] as String?)?.trim() ?? '',
      budgetAmount: _parseAmount(json['budget_amount']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'year': year,
      'month': month,
      'category': category,
      'budget_amount': budgetAmount,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'budget_amount': budgetAmount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  MonthlyBudgetModel copyWith({
    String? id,
    int? year,
    int? month,
    String? category,
    double? budgetAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBudgetModel(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
