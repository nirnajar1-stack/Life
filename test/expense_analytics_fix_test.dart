import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/expenses/data/models/expense_model.dart';
import 'package:life_app/features/expenses/domain/models/expense_dashboard.dart';
import 'package:life_app/features/expenses/domain/models/expense_period.dart';

ExpenseModel _expense({
  required int id,
  required DateTime createdAt,
  required double amount,
}) {
  return ExpenseModel(
    id: id,
    createdAt: createdAt,
    itemName: 'item-$id',
    amount: amount,
    category: 'מזון',
    subCategory: '',
    source: 'life_app',
    uuid: 'uuid-$id',
    insertedAt: createdAt,
  );
}

void main() {
  final now = DateTime(2026, 10, 15);

  group('filterExpensesByPeriod', () {
    final expenses = [
      _expense(id: 1, createdAt: DateTime(2026, 9, 10), amount: 100),
      _expense(id: 2, createdAt: DateTime(2026, 10, 5), amount: 200),
      _expense(id: 3, createdAt: DateTime(2026, 11, 1), amount: 144),
    ];

    test('thisMonth excludes future charges', () {
      final filtered = filterExpensesByPeriod(
        expenses,
        ExpensePeriod.thisMonth,
        now: now,
      );
      expect(filtered.map((e) => e.id), [2]);
    });

    test('all still excludes future by default', () {
      final filtered = filterExpensesByPeriod(
        expenses,
        ExpensePeriod.all,
        now: now,
      );
      expect(filtered.map((e) => e.id), [1, 2]);
    });
  });

  group('buildExpenseDashboard MoM', () {
    test('previous month stays correct when period is thisMonth', () {
      final all = [
        _expense(id: 1, createdAt: DateTime(2026, 9, 10), amount: 1000),
        _expense(id: 2, createdAt: DateTime(2026, 10, 5), amount: 500),
        _expense(id: 3, createdAt: DateTime(2026, 11, 1), amount: 144),
      ];
      final filtered = filterExpensesByPeriod(
        all,
        ExpensePeriod.thisMonth,
        now: now,
      );

      final dashboard = buildExpenseDashboard(
        filtered,
        period: ExpensePeriod.thisMonth,
        now: now,
        calendarExpenses: all,
      );

      expect(dashboard.thisMonthTotal, 500);
      expect(dashboard.previousMonthTotal, 1000);
      expect(dashboard.monthlyTrend.map((m) => m.month), [10, 9]);
      expect(dashboard.grandTotal, 500);
    });
  });
}
