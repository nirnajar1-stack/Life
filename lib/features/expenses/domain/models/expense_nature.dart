/// Commitment / payment nature of an expense.
///
/// - [variable] / [fixed] map to `is_fixed` 0 / 1
/// - [installment] is detected via `installment_group_id` (dedicated columns)
enum ExpenseNature {
  variable,
  fixed,
  installment,
}

extension ExpenseNatureX on ExpenseNature {
  String get label {
    switch (this) {
      case ExpenseNature.variable:
        return 'משתנה';
      case ExpenseNature.fixed:
        return 'קבועה';
      case ExpenseNature.installment:
        return 'תשלומים';
    }
  }

  /// Value for `is_fixed` column. Installments always store 0 there.
  int get isFixedDbValue {
    switch (this) {
      case ExpenseNature.fixed:
        return 1;
      case ExpenseNature.variable:
      case ExpenseNature.installment:
        return 0;
    }
  }

  static ExpenseNature resolve({
    required int? isFixed,
    required String? installmentGroupId,
  }) {
    if (installmentGroupId != null && installmentGroupId.trim().isNotEmpty) {
      return ExpenseNature.installment;
    }
    if (isFixed == 1) return ExpenseNature.fixed;
    return ExpenseNature.variable;
  }
}

/// Shared-expense helpers for `Shared_exp`.
///
/// When [sharedExp] is 2+, the purchase is split between that many people and
/// only `amount / sharedExp` counts toward totals.
class SharedExpenseFlag {
  const SharedExpenseFlag._();

  static const int defaultSplit = 2;

  static bool isShared(int? value) => (value ?? 0) > 0;

  /// Number of people sharing the expense; null when personal.
  static int? splitCount(int? value) {
    if (value == null || value <= 0) return null;
    return value;
  }

  /// Personal share that should count in monthly/category totals.
  static double actualAmount(double amount, int? sharedExp) {
    final split = sharedExp ?? 0;
    if (split <= 0) return amount;
    return amount / split;
  }

  static int toDb({required bool shared, int split = defaultSplit}) {
    if (!shared) return 0;
    return split < 2 ? defaultSplit : split;
  }
}
