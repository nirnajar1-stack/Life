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

/// Shared-expense flag helpers for `Shared_exp`.
class SharedExpenseFlag {
  const SharedExpenseFlag._();

  static bool isShared(int? value) => (value ?? 0) > 0;

  static int toDb(bool shared) => shared ? 1 : 0;
}
