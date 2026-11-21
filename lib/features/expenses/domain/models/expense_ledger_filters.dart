import 'expense_behavior.dart';
import 'expense_ledger.dart';

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

/// Behavior filter for the expenses ledger (`all` = no filter).
enum ExpenseBehaviorFilter {
  all,
  fixedCommitment,
  recurringVariable,
  variableDiscretionary,
  oneTime,
}

extension ExpenseBehaviorFilterX on ExpenseBehaviorFilter {
  String get label {
    switch (this) {
      case ExpenseBehaviorFilter.all:
        return 'הכל';
      case ExpenseBehaviorFilter.fixedCommitment:
        return 'התחייבות קבועה';
      case ExpenseBehaviorFilter.recurringVariable:
        return 'חוזרת משתנה';
      case ExpenseBehaviorFilter.variableDiscretionary:
        return 'משתנה';
      case ExpenseBehaviorFilter.oneTime:
        return 'חד־פעמית';
    }
  }

  ExpenseBehaviorType? get behavior {
    switch (this) {
      case ExpenseBehaviorFilter.all:
        return null;
      case ExpenseBehaviorFilter.fixedCommitment:
        return ExpenseBehaviorType.fixedCommitment;
      case ExpenseBehaviorFilter.recurringVariable:
        return ExpenseBehaviorType.recurringVariable;
      case ExpenseBehaviorFilter.variableDiscretionary:
        return ExpenseBehaviorType.variableDiscretionary;
      case ExpenseBehaviorFilter.oneTime:
        return ExpenseBehaviorType.oneTime;
    }
  }
}

/// Client-side ledger filters (on top of period + search).
class ExpenseLedgerFilters {
  const ExpenseLedgerFilters({
    this.shared = ExpenseSharedFilter.all,
    this.behavior = ExpenseBehaviorFilter.all,
  });

  final ExpenseSharedFilter shared;
  final ExpenseBehaviorFilter behavior;

  bool get isActive =>
      shared != ExpenseSharedFilter.all ||
      behavior != ExpenseBehaviorFilter.all;

  ExpenseLedgerFilters copyWith({
    ExpenseSharedFilter? shared,
    ExpenseBehaviorFilter? behavior,
  }) {
    return ExpenseLedgerFilters(
      shared: shared ?? this.shared,
      behavior: behavior ?? this.behavior,
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

  final wanted = filters.behavior.behavior;
  if (wanted != null) {
    final behaviors = tx.items.map(deriveExpenseBehavior).toSet();
    if (!behaviors.contains(wanted)) return false;
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
