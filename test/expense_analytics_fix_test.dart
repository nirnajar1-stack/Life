import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/expenses/data/models/expense_model.dart';
import 'package:life_app/features/expenses/domain/models/expense_dashboard.dart';
import 'package:life_app/features/expenses/domain/models/expense_period.dart';

ExpenseModel _expense({
  required int id,
  required DateTime createdAt,
  required double amount,
  int? isFixed,
  String? installmentGroupId,
}) {
  return ExpenseModel(
    id: id,
    createdAt: createdAt,
    itemName: 'item-$id',
    amount: amount,
    category: 'מזון',
    subCategory: '',
    isFixed: isFixed,
    installmentGroupId: installmentGroupId,
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

    test('daily trend and monthly nature stack', () {
      final all = [
        _expense(
          id: 1,
          createdAt: DateTime(2026, 9, 10),
          amount: 1000,
          isFixed: 1,
        ),
        _expense(id: 2, createdAt: DateTime(2026, 10, 5), amount: 200),
        _expense(
          id: 3,
          createdAt: DateTime(2026, 10, 12),
          amount: 300,
          isFixed: 1,
        ),
        _expense(
          id: 4,
          createdAt: DateTime(2026, 10, 12),
          amount: 100,
          installmentGroupId: 'plan-1',
        ),
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

      expect(dashboard.dailyTrend.length, 15); // Oct 1..15
      expect(
        dashboard.dailyTrend.where((d) => d.date.day == 12).single.total,
        400,
      );
      expect(dashboard.averageDailySpend, closeTo(600 / 15, 0.01));
      expect(dashboard.peakDaySpend, 400);
      expect(dashboard.peakDayLabel, '12/10');

      final october = dashboard.monthlyTrend.firstWhere((m) => m.month == 10);
      expect(october.variableTotal, 200);
      expect(october.fixedTotal, 300);
      expect(october.installmentTotal, 100);
      expect(october.committedTotal, 400);
      expect(dashboard.committedShare, closeTo(400 / 600, 0.01));
    });
  });
}
