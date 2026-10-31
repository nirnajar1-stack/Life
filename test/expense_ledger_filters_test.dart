import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/expenses/data/models/expense_model.dart';
import 'package:life_app/features/expenses/domain/models/expense_ledger.dart';
import 'package:life_app/features/expenses/domain/models/expense_ledger_filters.dart';

ExpenseModel _item({
  required int id,
  required double amount,
  int sharedExp = 0,
  int? isFixed,
  String? installmentGroupId,
  String source = 'life_app',
  String name = 'item',
}) {
  final now = DateTime(2026, 10, 10);
  return ExpenseModel(
    id: id,
    createdAt: now,
    itemName: name,
    amount: amount,
    category: 'מזון',
    subCategory: '',
    isFixed: isFixed,
    installmentGroupId: installmentGroupId,
    source: source,
    uuid: 'uuid-$id',
    insertedAt: now,
    sharedExp: sharedExp,
  );
}

ExpenseTransaction _tx(List<ExpenseModel> items) {
  return ExpenseTransaction(
    items: items,
    date: items.first.createdAt,
    messageId: items.length > 1 ? 'msg' : null,
  );
}

void main() {
  test('shared / personal / nature filters', () {
    final shared = _tx([_item(id: 1, amount: 100, sharedExp: 2)]);
    final personal = _tx([_item(id: 2, amount: 50)]);
    final fixed = _tx([_item(id: 3, amount: 3100, isFixed: 1, name: 'שכ״ד')]);
    final installment = _tx([
      _item(id: 4, amount: 144, installmentGroupId: 'plan-1', name: 'מחשב'),
    ]);

    expect(
      transactionMatchesLedgerFilters(
        shared,
        const ExpenseLedgerFilters(shared: ExpenseSharedFilter.shared),
      ),
      isTrue,
    );
    expect(
      transactionMatchesLedgerFilters(
        personal,
        const ExpenseLedgerFilters(shared: ExpenseSharedFilter.shared),
      ),
      isFalse,
    );
    expect(
      transactionMatchesLedgerFilters(
        fixed,
        const ExpenseLedgerFilters(nature: ExpenseNatureFilter.fixed),
      ),
      isTrue,
    );
    expect(
      transactionMatchesLedgerFilters(
        installment,
        const ExpenseLedgerFilters(nature: ExpenseNatureFilter.installment),
      ),
      isTrue,
    );
  });

  test('search matches amount and source', () {
    final tx = _tx([
      _item(id: 1, amount: 54.9, name: 'Netflix', source: 'life_app_recurring'),
    ]);
    expect(tx.matchesQuery('54.9'), isTrue);
    expect(tx.matchesQuery('recurring'), isTrue);
    expect(tx.matchesQuery('netflix'), isTrue);
    expect(tx.matchesQuery('xyz'), isFalse);
  });
}
