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
    source: 'life_app',
    uuid: 'uuid-$id',
    insertedAt: createdAt,
    installmentGroupId: installmentGroupId,
  );
}

void main() {
  group('filterExpensesByPeriod custom range', () {
    final expenses = [
      _expense(id: 1, createdAt: DateTime(2026, 1, 5), amount: 10),
      _expense(id: 2, createdAt: DateTime(2026, 2, 10), amount: 20),
      _expense(id: 3, createdAt: DateTime(2026, 3, 15), amount: 30),
    ];

    test('keeps inclusive start/end days', () {
      final filtered = filterExpensesByPeriod(
        expenses,
        ExpensePeriod.custom,
        customStart: DateTime(2026, 2, 10),
        customEnd: DateTime(2026, 3, 15),
      );
      expect(filtered.map((e) => e.id), [2, 3]);
    });

    test('excludes dates after inclusive end', () {
      final filtered = filterExpensesByPeriod(
        expenses,
        ExpensePeriod.custom,
        customStart: DateTime(2026, 1, 1),
        customEnd: DateTime(2026, 2, 9),
      );
      expect(filtered.map((e) => e.id), [1]);
    });
  });

  group('variableDailyTrend', () {
    test('aggregates only variable expenses by day', () {
      final now = DateTime(2026, 4, 10);
      final dashboard = buildExpenseDashboard(
        [
          _expense(
            id: 1,
            createdAt: DateTime(2026, 4, 1, 9),
            amount: 40,
          ),
          _expense(
            id: 2,
            createdAt: DateTime(2026, 4, 1, 18),
            amount: 10,
          ),
          _expense(
            id: 3,
            createdAt: DateTime(2026, 4, 2),
            amount: 100,
            isFixed: 1,
          ),
          _expense(
            id: 4,
            createdAt: DateTime(2026, 4, 3),
            amount: 50,
            installmentGroupId: 'plan-1',
          ),
          _expense(
            id: 5,
            createdAt: DateTime(2026, 4, 4),
            amount: 25,
          ),
        ],
        period: ExpensePeriod.thisMonth,
        now: now,
      );

      expect(dashboard.variableDailyTrend.length, 2);
      expect(dashboard.variableDailyTrend[0].date, DateTime(2026, 4, 1));
      expect(dashboard.variableDailyTrend[0].total, 50);
      expect(dashboard.variableDailyTrend[1].date, DateTime(2026, 4, 4));
      expect(dashboard.variableDailyTrend[1].total, 25);
      expect(dashboard.variableTotal, 75);
    });
  });
}
