import '../../domain/models/income_type.dart';

class IncomeModel {
  const IncomeModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.amount,
    required this.category,
    required this.subCategory,
    required this.incomeType,
    required this.source,
    this.recurringIncomeId,
    this.notes,
    required this.insertedAt,
  });

  final int id;
  final DateTime createdAt;
  final String title;
  final double amount;
  final String category;
  final String subCategory;
  final IncomeType incomeType;
  final String source;
  final String? recurringIncomeId;
  final String? notes;
  final DateTime insertedAt;

  bool get isSalary => incomeType == IncomeType.salary;

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      title: json['title'] as String,
      amount: _parseAmount(json['amount']),
      category: json['category'] as String,
      subCategory: (json['sub_category'] as String?)?.trim() ?? 'כללי',
      incomeType: IncomeTypeX.fromDb(json['income_type'] as String?),
      source: json['source'] as String? ?? 'life_app',
      recurringIncomeId: json['recurring_income_id'] as String?,
      notes: json['notes'] as String?,
      insertedAt: DateTime.parse(json['inserted_at'] as String),
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'amount': amount,
      'category': category,
      'sub_category': subCategory,
      'income_type': incomeType.dbValue,
      'source': source,
      'recurring_income_id': recurringIncomeId,
      'notes': notes,
    };
  }

  IncomeModel copyWith({
    String? title,
    double? amount,
    String? category,
    String? subCategory,
    IncomeType? incomeType,
    DateTime? createdAt,
    String? notes,
    bool clearNotes = false,
  }) {
    return IncomeModel(
      id: id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      incomeType: incomeType ?? this.incomeType,
      source: source,
      recurringIncomeId: recurringIncomeId,
      notes: clearNotes ? null : (notes ?? this.notes),
      insertedAt: insertedAt,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

DateTime incomeMonthStart(DateTime value) => DateTime(value.year, value.month);

DateTime incomeNextMonth(DateTime monthStart) =>
    DateTime(monthStart.year, monthStart.month + 1);
