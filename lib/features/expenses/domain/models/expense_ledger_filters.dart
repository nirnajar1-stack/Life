import 'expense_ledger.dart';
import 'expense_nature.dart';

/// Ownership filter for the expenses ledger.
enum ExpenseSharedFilter {
  all,
  shared,
  personal,
}

extension ExpenseSharedFilterX on ExpenseSharedFilter {
  String get label {
    switch (this) {
      case ExpenseSharedFilter.all:
        return 'הכל';
      case ExpenseSharedFilter.shared:
        return 'משותף';
      case ExpenseSharedFilter.personal:
        return 'אישי';
    }
  }
}

/// Nature filter for the expenses ledger (`null` = all).
enum ExpenseNatureFilter {
  all,
  variable,
  fixed,
  installment,
}

extension ExpenseNatureFilterX on ExpenseNatureFilter {
  String get label {
    switch (this) {
      case ExpenseNatureFilter.all:
        return 'הכל';
      case ExpenseNatureFilter.variable:
        return 'משתנה';
      case ExpenseNatureFilter.fixed:
        return 'קבועה';
      case ExpenseNatureFilter.installment:
        return 'תשלומים';
    }
  }

  ExpenseNature? get nature {
    switch (this) {
      case ExpenseNatureFilter.all:
        return null;
      case ExpenseNatureFilter.variable:
        return ExpenseNature.variable;
      case ExpenseNatureFilter.fixed:
        return ExpenseNature.fixed;
      case ExpenseNatureFilter.installment:
        return ExpenseNature.installment;
    }
  }
}

/// Client-side ledger filters (on top of period + search).
class ExpenseLedgerFilters {
  const ExpenseLedgerFilters({
    this.shared = ExpenseSharedFilter.all,
    this.nature = ExpenseNatureFilter.all,
  });

  final ExpenseSharedFilter shared;
  final ExpenseNatureFilter nature;

  bool get isActive =>
      shared != ExpenseSharedFilter.all || nature != ExpenseNatureFilter.all;

  ExpenseLedgerFilters copyWith({
    ExpenseSharedFilter? shared,
    ExpenseNatureFilter? nature,
  }) {
    return ExpenseLedgerFilters(
      shared: shared ?? this.shared,
      nature: nature ?? this.nature,
    );
  }
}

bool transactionMatchesLedgerFilters(
  ExpenseTransaction tx,
  ExpenseLedgerFilters filters,
) {
  switch (filters.shared) {
    case ExpenseSharedFilter.all:
      break;
    case ExpenseSharedFilter.shared:
      if (!tx.isShared) return false;
    case ExpenseSharedFilter.personal:
      if (tx.isShared) return false;
  }

  final wanted = filters.nature.nature;
  if (wanted != null) {
    final natures = tx.items
        .map(
          (item) => ExpenseNatureX.resolve(
            isFixed: item.isFixed,
            installmentGroupId: item.installmentGroupId,
          ),
        )
        .toSet();
    if (!natures.contains(wanted)) return false;
  }

  return true;
}

List<ExpenseMonthSection> filterLedgerMonths({
  required List<ExpenseMonthSection> months,
  required String query,
  required ExpenseLedgerFilters filters,
}) {
  return months
      .map(
        (month) => ExpenseMonthSection(
          year: month.year,
          month: month.month,
          transactions: month.transactions
              .where(
                (tx) =>
                    tx.matchesQuery(query) &&
                    transactionMatchesLedgerFilters(tx, filters),
              )
              .toList(),
        ),
      )
      .where((month) => month.transactions.isNotEmpty)
      .toList();
}
