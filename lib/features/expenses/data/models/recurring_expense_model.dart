import '../../domain/models/expense_nature.dart';

class RecurringExpenseModel {
  const RecurringExpenseModel({
    required this.id,
    required this.title,
    this.amount,
    required this.category,
    required this.subCategory,
    required this.dayOfMonth,
    this.sharedExp = 0,
    this.amountVariable = false,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    this.lastGeneratedMonth,
    required this.createdAt,
    this.chargedThisMonth = false,
  });

  final String id;
  final String title;
  final double? amount;
  final String category;
  final String subCategory;
  final int dayOfMonth;
  final int sharedExp;
  final bool amountVariable;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastGeneratedMonth;
  final DateTime createdAt;

  /// Whether a charge already exists for the current calendar month.
  final bool chargedThisMonth;

  double get actualAmount =>
      amount == null ? 0 : SharedExpenseFlag.actualAmount(amount!, sharedExp);

  bool get isShared => SharedExpenseFlag.isShared(sharedExp);

  String get scheduleLabel => 'כל $dayOfMonth לחודש';

  String get amountLabel {
    if (amountVariable) {
      if (amount != null && amount! > 0) {
        return 'משתנה · אחרון ${_formatMoney(amount!)}';
      }
      return 'סכום משתנה';
    }
    if (amount == null) return '—';
    return _formatMoney(amount!);
  }

  factory RecurringExpenseModel.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] == null ? null : _parseAmount(json['amount']),
      category: json['category'] as String,
      subCategory: (json['sub_category'] as String?)?.trim() ?? 'כללי',
      dayOfMonth: (json['day_of_month'] as num?)?.toInt() ?? 1,
      sharedExp: (json['shared_exp'] as num?)?.toInt() ?? 0,
      amountVariable: json['amount_variable'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      lastGeneratedMonth: json['last_generated_month'] == null
          ? null
          : DateTime.parse(json['last_generated_month'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'sub_category': subCategory,
      'day_of_month': dayOfMonth,
      'shared_exp': sharedExp,
      'amount_variable': amountVariable,
      'is_active': isActive,
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      ...toJsonForInsert(),
      'last_generated_month': _dateOnly(lastGeneratedMonth),
    };
  }

  RecurringExpenseModel copyWith({
    String? title,
    double? amount,
    bool clearAmount = false,
    String? category,
    String? subCategory,
    int? dayOfMonth,
    int? sharedExp,
    bool? amountVariable,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? lastGeneratedMonth,
    bool clearLastGenerated = false,
    bool? chargedThisMonth,
  }) {
    return RecurringExpenseModel(
      id: id,
      title: title ?? this.title,
      amount: clearAmount ? null : (amount ?? this.amount),
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      sharedExp: sharedExp ?? this.sharedExp,
      amountVariable: amountVariable ?? this.amountVariable,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      lastGeneratedMonth: clearLastGenerated
          ? null
          : (lastGeneratedMonth ?? this.lastGeneratedMonth),
      createdAt: createdAt,
      chargedThisMonth: chargedThisMonth ?? this.chargedThisMonth,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return '₪${value.toInt()}';
    }
    return '₪${value.toStringAsFixed(2)}';
  }
}

DateTime recurringMonthStart(DateTime value) =>
    DateTime(value.year, value.month);

DateTime recurringNextMonth(DateTime monthStart) =>
    DateTime(monthStart.year, monthStart.month + 1);
