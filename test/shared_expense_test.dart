import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/expenses/domain/models/expense_nature.dart';

void main() {
  test('personal expense counts full amount', () {
    expect(SharedExpenseFlag.actualAmount(100, 0), 100);
    expect(SharedExpenseFlag.actualAmount(100, null), 100);
  });

  test('shared expense divides by split count', () {
    expect(SharedExpenseFlag.actualAmount(100, 2), 50);
    expect(SharedExpenseFlag.actualAmount(90, 3), 30);
    expect(SharedExpenseFlag.actualAmount(100, 1), 100);
  });

  test('toDb stores split count or zero', () {
    expect(
      SharedExpenseFlag.toDb(shared: true, split: 3),
      3,
    );
    expect(
      SharedExpenseFlag.toDb(shared: false, split: 3),
      0,
    );
  });
}
