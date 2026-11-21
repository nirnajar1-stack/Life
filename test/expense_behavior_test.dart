import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/expenses/data/models/expense_model.dart';
import 'package:life_app/features/expenses/domain/models/expense_behavior.dart';
import 'package:life_app/features/expenses/domain/models/variable_pace_forecast.dart';

ExpenseModel _e({
  required int id,
  required String name,
  String category = '',
  String sub = '',
  int? isFixed,
  String? installmentGroupId,
  String? behavior,
  double amount = 100,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 11, 10, 12);
  return ExpenseModel(
    id: id,
    createdAt: now,
    itemName: name,
    amount: amount,
    category: category,
    subCategory: sub,
    isFixed: isFixed,
    installmentGroupId: installmentGroupId,
    expenseBehaviorType: behavior,
    source: 'test',
    uuid: 'u-$id',
    insertedAt: now,
    purchaseDate: DateTime(now.year, now.month, now.day),
  );
}

void main() {
  group('deriveExpenseBehaviorType', () {
    test('stored column wins', () {
      expect(
        deriveExpenseBehaviorType(
          expenseBehaviorType: 'one_time',
          itemName: 'שכירות',
          isFixed: 1,
        ),
        ExpenseBehaviorType.oneTime,
      );
    });

    test('legacy rent / car loan / insurance / subscription → fixed', () {
      expect(
        deriveExpenseBehaviorType(itemName: 'שכ״ד דירה', isFixed: 1),
        ExpenseBehaviorType.fixedCommitment,
      );
      expect(
        deriveExpenseBehaviorType(
          itemName: 'הלוואה לקניית הרכב',
          category: 'תחבורה',
          subCategory: 'הלוואת רכב',
          installmentGroupId: 'plan-1',
        ),
        ExpenseBehaviorType.fixedCommitment,
      );
      expect(
        deriveExpenseBehaviorType(itemName: 'ביטוח רכב', category: 'תחבורה'),
        ExpenseBehaviorType.fixedCommitment,
      );
      expect(
        deriveExpenseBehaviorType(itemName: 'Netflix', category: 'מנויים ושירותים'),
        ExpenseBehaviorType.fixedCommitment,
      );
    });

    test('legacy electricity / water → recurring_variable', () {
      expect(
        deriveExpenseBehaviorType(
          itemName: 'חשבון חשמל',
          category: 'דיור',
          subCategory: 'חשמל',
          isFixed: 1,
        ),
        ExpenseBehaviorType.recurringVariable,
      );
      expect(
        deriveExpenseBehaviorType(itemName: 'מים', isFixed: 1),
        ExpenseBehaviorType.recurringVariable,
      );
    });

    test('installment without keyword → fixed_commitment', () {
      expect(
        deriveExpenseBehaviorType(
          itemName: 'מחשב נייד',
          installmentGroupId: 'abc',
          isFixed: 0,
        ),
        ExpenseBehaviorType.fixedCommitment,
      );
    });

    test('ordinary shopping stays variable_discretionary, not one_time', () {
      expect(
        deriveExpenseBehaviorType(
          itemName: 'חולצה',
          category: 'ביגוד והנעלה',
          subCategory: 'ביגוד',
        ),
        ExpenseBehaviorType.variableDiscretionary,
      );
      expect(
        deriveExpenseBehaviorType(
          itemName: 'מסעדה',
          category: 'מזון',
          subCategory: 'מסעדות',
        ),
        ExpenseBehaviorType.variableDiscretionary,
      );
      expect(
        deriveExpenseBehaviorType(
          itemName: 'מוצרי ניקיון',
          category: 'דיור',
          subCategory: 'מוצרי ניקיון',
        ),
        ExpenseBehaviorType.variableDiscretionary,
      );
    });

    test('exceptional one-offs via signals', () {
      expect(
        deriveExpenseBehaviorType(
          itemName: 'טיסה לניו יורק',
          category: 'נסיעות ונופש',
          subCategory: 'טיסות',
        ),
        ExpenseBehaviorType.oneTime,
      );
      expect(
        deriveExpenseBehaviorType(
          itemName: 'מלון בבודפשט',
          category: 'נסיעות ונופש',
        ),
        ExpenseBehaviorType.oneTime,
      );
      expect(
        deriveExpenseBehaviorType(
          itemName: 'מחשב נייד',
          category: 'קניות',
          subCategory: 'אלקטרוניקה',
        ),
        ExpenseBehaviorType.oneTime,
      );
      expect(
        deriveExpenseBehaviorType(
          itemName: 'מדבקות למחשב נייד',
          category: 'קניות',
        ),
        ExpenseBehaviorType.variableDiscretionary,
      );
    });
  });

  group('daily pace vs monthly cashflow', () {
    test('installment excluded from daily pace but included in monthly balance', () {
      final installment = _e(
        id: 1,
        name: 'הלוואה לקניית הרכב',
        category: 'תחבורה',
        sub: 'הלוואת רכב',
        installmentGroupId: 'car-loan',
        amount: 1440,
      );
      final coffee = _e(
        id: 2,
        name: 'קפה',
        category: 'מזון',
        sub: 'בתי קפה',
        amount: 20,
      );

      expect(deriveExpenseBehavior(installment).countsInDailyPace, isFalse);
      expect(deriveExpenseBehavior(coffee).countsInDailyPace, isTrue);

      final forecast = buildVariablePaceForecast(
        [installment, coffee],
        now: DateTime(2026, 11, 10),
      );
      expect(forecast.variableSpendMtd, 20);

      final balance = MonthlyBalance.fromExpenses(
        expenses: [installment, coffee],
        totalIncome: 10000,
        now: DateTime(2026, 11, 10),
      );
      expect(balance.installmentExpenses, 1440);
      expect(balance.variableExpenses, 20);
      expect(balance.totalExpenses, 1460);
    });

    test('recurring_variable utility excluded from daily pace', () {
      final electric = _e(
        id: 3,
        name: 'חשמל',
        category: 'דיור',
        sub: 'חשמל',
        isFixed: 1,
        amount: 400,
      );
      expect(deriveExpenseBehavior(electric).countsInDailyPace, isFalse);
      final forecast = buildVariablePaceForecast(
        [electric],
        now: DateTime(2026, 11, 10),
      );
      expect(forecast.variableSpendMtd, 0);
    });
  });
}
