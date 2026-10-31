import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/expenses/data/models/expense_model.dart';
import 'package:life_app/features/expenses/domain/models/expense_calendar.dart';
import 'package:life_app/features/expenses/domain/models/expense_period.dart';

ExpenseModel _expense({
  required int id,
  required DateTime createdAt,
  required double amount,
  int? isFixed,
}) {
  return ExpenseModel(
    id: id,
    createdAt: createdAt,
    itemName: 'item-$id',
    amount: amount,
    category: 'דיור',
    subCategory: '',
    isFixed: isFixed,
    source: 'life_app_recurring',
    uuid: 'uuid-$id',
    insertedAt: createdAt,
  );
}

void main() {
  test('UTC midnight recurring charge stays in October for US-local bounds', () {
    // Simulates a charge stored as 2026-10-01T00:00:00Z (legacy recurring).
    final rent = _expense(
      id: 1,
      createdAt: DateTime.utc(2026, 10, 1),
      amount: 3100,
      isFixed: 1,
    );
    final coffee = _expense(
      id: 2,
      createdAt: DateTime(2026, 10, 15, 18),
      amount: 20,
      isFixed: 0,
    );

    final day = expenseCalendarDate(rent.createdAt);
    expect(day, DateTime(2026, 10, 1));

    final filtered = filterExpensesByPeriod(
      [rent, coffee],
      ExpensePeriod.thisMonth,
      now: DateTime(2026, 10, 20),
    );
    expect(filtered.map((e) => e.id), [1, 2]);

    expect(
      expenseInRange(
        rent.createdAt,
        startInclusive: DateTime(2026, 10, 1),
        endExclusive: DateTime(2026, 11, 1),
      ),
      isTrue,
    );
  });

  test('expenseChargeTimestamp uses noon UTC', () {
    final stamp = expenseChargeTimestamp(2026, 10, 1);
    expect(stamp.isUtc, isTrue);
    expect(stamp.hour, 12);
    expect(expenseCalendarDate(stamp), DateTime(2026, 10, 1));
  });
}
