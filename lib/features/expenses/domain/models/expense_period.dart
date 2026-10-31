import '../../data/models/expense_model.dart';
import 'expense_calendar.dart';

/// Time window used to filter expenses for the dashboard / ledger insights.
enum ExpensePeriod {
  thisMonth,
  last3Months,
  yearToDate,
  all,
}

extension ExpensePeriodX on ExpensePeriod {
  String get label {
    switch (this) {
      case ExpensePeriod.thisMonth:
        return 'החודש';
      case ExpensePeriod.last3Months:
        return '3 חודשים';
      case ExpensePeriod.yearToDate:
        return 'מתחילת השנה';
      case ExpensePeriod.all:
        return 'הכל';
    }
  }
}

/// Inclusive start of the selected period (null = no lower bound).
DateTime? periodStart(ExpensePeriod period, {DateTime? now}) {
  final n = now ?? DateTime.now();
  switch (period) {
    case ExpensePeriod.thisMonth:
      return expenseMonthStart(n.year, n.month);
    case ExpensePeriod.last3Months:
      return expenseMonthStart(n.year, n.month - 2);
    case ExpensePeriod.yearToDate:
      return expenseMonthStart(n.year, 1);
    case ExpensePeriod.all:
      return null;
  }
}

/// Exclusive end of the selected period.
///
/// Caps at the start of next calendar month so future installment / recurring
/// charges never leak into "החודש" / trend / period totals.
DateTime? periodEndExclusive(ExpensePeriod period, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final nextMonth = expenseMonthStart(n.year, n.month + 1);
  switch (period) {
    case ExpensePeriod.thisMonth:
    case ExpensePeriod.last3Months:
    case ExpensePeriod.yearToDate:
    case ExpensePeriod.all:
      return nextMonth;
  }
}

/// Filters expenses to those whose calendar date falls inside [period].
List<ExpenseModel> filterExpensesByPeriod(
  List<ExpenseModel> expenses,
  ExpensePeriod period, {
  DateTime? now,
  bool includeFuture = false,
}) {
  final start = periodStart(period, now: now);
  final end = includeFuture ? null : periodEndExclusive(period, now: now);

  return expenses
      .where(
        (e) => expenseInRange(
          e.createdAt,
          startInclusive: start,
          endExclusive: end,
        ),
      )
      .toList();
}
