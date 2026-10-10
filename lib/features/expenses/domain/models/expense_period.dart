import '../../data/models/expense_model.dart';

/// Time window used to filter expenses for the dashboard / ledger insights.
enum ExpensePeriod {
  thisMonth,
  last3Months,
  yearToDate,
  all,
  custom,
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
      case ExpensePeriod.custom:
        return 'מותאם';
    }
  }
}

/// Inclusive start of the selected period (null = no lower bound).
DateTime? periodStart(
  ExpensePeriod period, {
  DateTime? now,
  DateTime? customStart,
}) {
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
    case ExpensePeriod.custom:
      return customStart == null
          ? null
          : DateTime(customStart.year, customStart.month, customStart.day);
  }
}

/// Exclusive end of the selected period (null = no upper bound).
DateTime? periodEndExclusive(
  ExpensePeriod period, {
  DateTime? now,
  DateTime? customEnd,
}) {
  switch (period) {
    case ExpensePeriod.custom:
      if (customEnd == null) return null;
      return DateTime(customEnd.year, customEnd.month, customEnd.day)
          .add(const Duration(days: 1));
    case ExpensePeriod.thisMonth:
    case ExpensePeriod.last3Months:
    case ExpensePeriod.yearToDate:
    case ExpensePeriod.all:
      return null;
  }
}

/// Filters expenses to those whose [createdAt] falls inside [period].
List<ExpenseModel> filterExpensesByPeriod(
  List<ExpenseModel> expenses,
  ExpensePeriod period, {
  DateTime? now,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final start = periodStart(
    period,
    now: now,
    customStart: customStart,
  );
  final end = periodEndExclusive(
    period,
    now: now,
    customEnd: customEnd,
  );

  return expenses.where((e) {
    if (start != null && e.createdAt.isBefore(start)) return false;
    if (end != null && !e.createdAt.isBefore(end)) return false;
    return true;
  }).toList();
}
