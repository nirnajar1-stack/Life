import '../../domain/models/expense_nature.dart';

enum InstallmentPlanType {
  purchase,
  loan,
}

extension InstallmentPlanTypeX on InstallmentPlanType {
  String get label {
    switch (this) {
      case InstallmentPlanType.purchase:
        return 'קנייה בתשלומים';
      case InstallmentPlanType.loan:
        return 'הלוואה';
    }
  }

  String get dbValue {
    switch (this) {
      case InstallmentPlanType.purchase:
        return 'purchase';
      case InstallmentPlanType.loan:
        return 'loan';
    }
  }

  static InstallmentPlanType fromDb(String? value) {
    switch (value) {
      case 'loan':
        return InstallmentPlanType.loan;
      default:
        return InstallmentPlanType.purchase;
    }
  }
}

/// Header row for a finite payment plan; individual charges are in [expenses_new].
class InstallmentPlanModel {
  const InstallmentPlanModel({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.installmentsTotal,
    required this.planType,
    required this.category,
    required this.subCategory,
    this.sharedExp = 0,
    required this.firstChargeDate,
    required this.purchaseDate,
    this.isActive = true,
    required this.createdAt,
    this.paidInstallments = 0,
    this.monthlyAmount = 0,
    this.remainingAmount = 0,
    this.nextChargeDate,
  });

  final String id;
  final String title;
  final double totalAmount;
  final int installmentsTotal;
  final InstallmentPlanType planType;
  final String category;
  final String subCategory;
  final int sharedExp;
  final DateTime firstChargeDate;
  final DateTime purchaseDate;
  final bool isActive;
  final DateTime createdAt;

  /// Derived from linked charge rows.
  final int paidInstallments;
  final double monthlyAmount;
  final double remainingAmount;
  final DateTime? nextChargeDate;

  double get actualTotalAmount =>
      SharedExpenseFlag.actualAmount(totalAmount, sharedExp);

  double get actualMonthlyAmount =>
      SharedExpenseFlag.actualAmount(monthlyAmount, sharedExp);

  double get actualRemainingAmount =>
      SharedExpenseFlag.actualAmount(remainingAmount, sharedExp);

  bool get isShared => SharedExpenseFlag.isShared(sharedExp);

  bool get isComplete => paidInstallments >= installmentsTotal;

  int get remainingInstallments =>
      (installmentsTotal - paidInstallments).clamp(0, installmentsTotal);

  double get progress =>
      installmentsTotal <= 0 ? 0 : paidInstallments / installmentsTotal;

  String get progressLabel => '$paidInstallments/$installmentsTotal תשלומים';

  factory InstallmentPlanModel.fromJson(Map<String, dynamic> json) {
    return InstallmentPlanModel(
      id: json['id'] as String,
      title: json['title'] as String,
      totalAmount: _parseAmount(json['total_amount']),
      installmentsTotal: (json['installments_total'] as num).toInt(),
      planType: InstallmentPlanTypeX.fromDb(json['plan_type'] as String?),
      category: json['category'] as String,
      subCategory: (json['sub_category'] as String?)?.trim() ?? 'כללי',
      sharedExp: (json['shared_exp'] as num?)?.toInt() ?? 0,
      firstChargeDate: DateTime.parse(json['first_charge_date'] as String),
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'id': id,
      'title': title,
      'total_amount': totalAmount,
      'installments_total': installmentsTotal,
      'plan_type': planType.dbValue,
      'category': category,
      'sub_category': subCategory,
      'shared_exp': sharedExp,
      'first_charge_date': _dateOnly(firstChargeDate),
      'purchase_date': _dateOnly(purchaseDate),
      'is_active': isActive,
    };
  }

  InstallmentPlanModel copyWith({
    String? title,
    double? totalAmount,
    int? installmentsTotal,
    InstallmentPlanType? planType,
    String? category,
    String? subCategory,
    int? sharedExp,
    DateTime? firstChargeDate,
    DateTime? purchaseDate,
    bool? isActive,
    int? paidInstallments,
    double? monthlyAmount,
    double? remainingAmount,
    DateTime? nextChargeDate,
    bool clearNextChargeDate = false,
  }) {
    return InstallmentPlanModel(
      id: id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentsTotal: installmentsTotal ?? this.installmentsTotal,
      planType: planType ?? this.planType,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      sharedExp: sharedExp ?? this.sharedExp,
      firstChargeDate: firstChargeDate ?? this.firstChargeDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      nextChargeDate: clearNextChargeDate
          ? null
          : (nextChargeDate ?? this.nextChargeDate),
    );
  }

  InstallmentPlanModel withProgress({
    required int paidInstallments,
    required double monthlyAmount,
    required double remainingAmount,
    DateTime? nextChargeDate,
  }) {
    return copyWith(
      paidInstallments: paidInstallments,
      monthlyAmount: monthlyAmount,
      remainingAmount: remainingAmount,
      nextChargeDate: nextChargeDate,
      clearNextChargeDate: nextChargeDate == null,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

/// Splits [totalAmount] into [installmentsCount] monthly amounts (agorot-safe).
List<double> splitInstallmentAmounts({
  required double totalAmount,
  required int installmentsCount,
}) {
  final baseCents = (totalAmount * 100).round();
  final perCents = baseCents ~/ installmentsCount;
  final remainder = baseCents - (perCents * installmentsCount);
  return List<double>.generate(installmentsCount, (index) {
    final i = index + 1;
    final cents = perCents + (i == installmentsCount ? remainder : 0);
    return cents / 100.0;
  });
}

DateTime installmentChargeDate(DateTime firstChargeDate, int installmentNumber) {
  return DateTime(
    firstChargeDate.year,
    firstChargeDate.month + (installmentNumber - 1),
    firstChargeDate.day,
  );
}

int countPaidInstallments({
  required int installmentsTotal,
  required DateTime firstChargeDate,
  DateTime? asOf,
}) {
  final today = asOf ?? DateTime.now();
  final horizon = DateTime(today.year, today.month, today.day);
  var paid = 0;
  for (var i = 1; i <= installmentsTotal; i++) {
    final chargeDate = installmentChargeDate(firstChargeDate, i);
    if (!chargeDate.isAfter(horizon)) {
      paid = i;
    } else {
      break;
    }
  }
  return paid;
}
