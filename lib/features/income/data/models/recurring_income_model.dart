class RecurringIncomeModel {
  const RecurringIncomeModel({
    required this.id,
    required this.title,
    this.amount,
    this.amountVariable = true,
    required this.category,
    required this.subCategory,
    required this.dayOfMonth,
    this.isActive = true,
    required this.startDate,
    this.lastRecordedMonth,
    required this.createdAt,
    this.recordedThisMonth = false,
  });

  final String id;
  final String title;
  final double? amount;
  final bool amountVariable;
  final String category;
  final String subCategory;
  final int dayOfMonth;
  final bool isActive;
  final DateTime startDate;
  final DateTime? lastRecordedMonth;
  final DateTime createdAt;
  final bool recordedThisMonth;

  String get scheduleLabel => 'כל $dayOfMonth לחודש';

  String get amountLabel {
    if (amountVariable) {
      if (amount != null && amount! > 0) {
        return 'נטו משתנה · אחרון ₪${amount!.round()}';
      }
      return 'נטו משתנה';
    }
    if (amount == null) return '—';
    return '₪${amount!.round()}';
  }

  factory RecurringIncomeModel.fromJson(Map<String, dynamic> json) {
    return RecurringIncomeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] == null ? null : _parseAmount(json['amount']),
      amountVariable: json['amount_variable'] as bool? ?? true,
      category: json['category'] as String,
      subCategory: (json['sub_category'] as String?)?.trim() ?? 'כללי',
      dayOfMonth: (json['day_of_month'] as num?)?.toInt() ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      startDate: DateTime.parse(json['start_date'] as String),
      lastRecordedMonth: json['last_recorded_month'] == null
          ? null
          : DateTime.parse(json['last_recorded_month'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'title': title,
      'amount': amount,
      'amount_variable': amountVariable,
      'category': category,
      'sub_category': subCategory,
      'day_of_month': dayOfMonth,
      'is_active': isActive,
      'start_date': _dateOnly(startDate),
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      ...toJsonForInsert(),
      'last_recorded_month': _dateOnly(lastRecordedMonth),
    };
  }

  RecurringIncomeModel copyWith({
    String? title,
    double? amount,
    bool clearAmount = false,
    bool? amountVariable,
    String? category,
    String? subCategory,
    int? dayOfMonth,
    bool? isActive,
    DateTime? startDate,
    DateTime? lastRecordedMonth,
    bool? recordedThisMonth,
  }) {
    return RecurringIncomeModel(
      id: id,
      title: title ?? this.title,
      amount: clearAmount ? null : (amount ?? this.amount),
      amountVariable: amountVariable ?? this.amountVariable,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      lastRecordedMonth: lastRecordedMonth ?? this.lastRecordedMonth,
      createdAt: createdAt,
      recordedThisMonth: recordedThisMonth ?? this.recordedThisMonth,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
