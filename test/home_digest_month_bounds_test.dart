import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/core/home/home_digest.dart';
import 'package:life_app/features/expenses/data/models/expense_model.dart';
import 'package:life_app/features/income/data/models/income_model.dart';
import 'package:life_app/features/income/domain/models/income_type.dart';

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

IncomeModel _income({
  required int id,
  required DateTime createdAt,
  required double amount,
}) {
  return IncomeModel(
    id: id,
    title: 'salary-$id',
    amount: amount,
    category: 'משכורת',
    subCategory: 'כללי',
    incomeType: IncomeType.salary,
    source: 'life_app',
    createdAt: createdAt,
    insertedAt: createdAt,
  );
}

void main() {
  test('HomeDigest month totals exclude future charges like Money hub', () {
    final now = DateTime(2026, 10, 15);
    final digest = HomeDigest.from(
      tasks: const [],
      expenses: [
        _expense(id: 1, createdAt: DateTime(2026, 10, 5), amount: 500),
        _expense(id: 2, createdAt: DateTime(2026, 11, 1), amount: 1148),
      ],
      incomes: [
        _income(id: 1, createdAt: DateTime(2026, 10, 1), amount: 8000),
        _income(id: 2, createdAt: DateTime(2026, 11, 1), amount: 8000),
      ],
      now: now,
    );

    expect(digest.monthTotal, 500);
    expect(digest.monthIncome, 8000);
    expect(digest.monthNet, 7500);
  });
}
