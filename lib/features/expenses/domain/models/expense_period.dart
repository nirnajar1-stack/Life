import '../../data/models/expense_model.dart';

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
      return DateTime(n.year, n.month);
    case ExpensePeriod.last3Months:
      return DateTime(n.year, n.month - 2);
    case ExpensePeriod.yearToDate:
      return DateTime(n.year);
    case ExpensePeriod.all:
      return null;
  }
}

/// Filters expenses to those whose [createdAt] falls inside [period].
List<ExpenseModel> filterExpensesByPeriod(
  List<ExpenseModel> expenses,
  ExpensePeriod period, {
  DateTime? now,
}) {
  final start = periodStart(period, now: now);
  if (start == null) return List<ExpenseModel>.from(expenses);

  return expenses.where((e) => !e.createdAt.isBefore(start)).toList();
}
