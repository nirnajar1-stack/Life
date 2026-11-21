import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/expenses/data/models/expense_model.dart';
import 'package:life_app/features/expenses/domain/models/expense_amounts.dart';
import 'package:life_app/features/expenses/domain/models/variable_pace_forecast.dart';

ExpenseModel _exp({
  required double amount,
  required DateTime date,
  String category = 'מזון',
  int isFixed = 0,
  String? installmentGroupId,
  double? paidAmount,
  int? sharedExp,
  int id = 1,
}) {
  return ExpenseModel(
    id: id,
    createdAt: date,
    itemName: 'item',
    amount: amount,
    category: category,
    subCategory: 'כללי',
    isFixed: isFixed,
    source: 'life_app',
    uuid: '00000000-0000-0000-0000-00000000000$id',
    insertedAt: date,
    purchaseDate: DateTime(date.year, date.month, date.day),
    paidAmount: paidAmount,
    sharedExp: sharedExp,
    installmentGroupId: installmentGroupId,
  );
}

void main() {
  group('effectiveAmount / legacy', () {
    test('falls back to amount when paid_amount null', () {
      final e = _exp(amount: 100, date: DateTime(2026, 11, 1));
      expect(e.effectiveGross, 100);
      expect(e.actualAmount, 100);
      expect(effectiveAmount(e), 100);
    });

    test('prefers paid_amount and applies shared split', () {
      final e = _exp(
        amount: 100,
        paidAmount: 80,
        sharedExp: 2,
        date: DateTime(2026, 11, 1),
      );
      expect(e.effectiveGross, 80);
      expect(e.actualAmount, 40);
    });
  });

  group('receipt amount extraction', () {
    test('prefers paid over gross / line sum', () {
      expect(
        resolveReceiptPaidAmount(
          amountPaid: 80,
          grandTotal: 100,
          lineItemsSum: 100,
        ),
        80,
      );
    });

    test('line item uses final total after discount', () {
      expect(
        resolveLineItemTotal(
          quantity: 10,
          unitPrice: 10,
          lineGross: 100,
          lineDiscount: 20,
          finalLineTotal: 80,
        ),
        80,
      );
    });
  });

  group('transaction date', () {
    test('uses purchase_date over created_at', () {
      final e = ExpenseModel(
        id: 1,
        createdAt: DateTime.utc(2026, 10, 1, 12),
        itemName: 'x',
        amount: 10,
        category: 'מזון',
        subCategory: 'סופר',
        uuid: 'u',
        insertedAt: DateTime.utc(2026, 10, 1),
        purchaseDate: DateTime(2026, 11, 21),
        dateSource: 'telegram',
      );
      expect(e.transactionDate, DateTime(2026, 11, 21));
      expect(ExpenseDateSource.hebrewLabel('telegram'), 'תאריך ההודעה');
      expect(ExpenseDateSource.hebrewLabel('receipt'), 'חשבונית');
    });

    test('receipt date preferred conceptually over telegram fallback', () {
      // When OCR finds a date, date_source=receipt and purchase_date is set.
      final fromReceipt = _exp(
        amount: 50,
        date: DateTime(2026, 11, 15),
      ).copyWith(dateSource: 'receipt');
      expect(fromReceipt.dateSource, 'receipt');
      expect(fromReceipt.transactionDate.day, 15);
    });
  });

  group('variable pace forecast', () {
    test('scenario 1: day 1 food 100 → forecast 3000 in 30-day month', () {
      final now = DateTime(2026, 11, 1);
      final forecast = buildVariablePaceForecast(
        [_exp(amount: 100, date: now, category: 'מזון')],
        now: now,
      );
      expect(forecast.daysElapsed, 1);
      expect(forecast.daysInMonth, 30);
      expect(forecast.variableSpendMtd, 100);
      expect(forecast.dailyPace, 100);
      expect(forecast.forecastEom, 3000);
      expect(forecast.isEarlyMonth, isTrue);
    });

    test('excludes fixed expenses from forecast', () {
      final now = DateTime(2026, 11, 2);
      final forecast = buildVariablePaceForecast(
        [
          _exp(amount: 4000, date: now, category: 'דיור', isFixed: 1, id: 1),
          _exp(amount: 200, date: now, category: 'מזון', id: 2),
        ],
        now: now,
      );
      expect(forecast.variableSpendMtd, 200);
      expect(forecast.dailyPace, 100);
      expect(forecast.forecastEom, 3000);
    });

    test('forecast by category', () {
      final now = DateTime(2026, 11, 10);
      final forecast = buildVariablePaceForecast(
        [
          _exp(amount: 200, date: DateTime(2026, 11, 1), category: 'מזון', id: 1),
          _exp(
              amount: 100,
              date: DateTime(2026, 11, 2),
              category: 'תחבורה',
              id: 2),
        ],
        now: now,
      );
      expect(forecast.byCategory.length, 2);
      final food =
          forecast.byCategory.firstWhere((c) => c.category == 'מזון');
      expect(food.actualMtd, 200);
      expect(food.forecastEom, closeTo(200 / 10 * 30, 0.01));
    });

    test('empty variable → forecast 0', () {
      final now = DateTime(2026, 11, 5);
      final forecast = buildVariablePaceForecast(const [], now: now);
      expect(forecast.forecastEom, 0);
      expect(forecast.variableSpendMtd, 0);
    });

    test('ignores other-month transactions', () {
      final now = DateTime(2026, 11, 5);
      final forecast = buildVariablePaceForecast(
        [_exp(amount: 500, date: DateTime(2026, 10, 20))],
        now: now,
      );
      expect(forecast.variableSpendMtd, 0);
      expect(forecast.forecastEom, 0);
    });

    test('budget variance and over-budget status', () {
      final now = DateTime(2026, 11, 10);
      final forecast = buildVariablePaceForecast(
        [
          _exp(
            amount: 1250,
            date: DateTime(2026, 11, 1),
            category: 'מזון',
          ),
        ],
        now: now,
        budgetsByCategory: {'מזון': 2000},
      );
      final food =
          forecast.byCategory.firstWhere((c) => c.category == 'מזון');
      expect(food.remainingBudget, 750);
      expect(food.utilizationPercent, closeTo(62.5, 0.01));
      // pace 125/day * 30 = 3750 → over budget
      expect(food.forecastEom, closeTo(3750, 0.01));
      expect(food.forecastVariance, closeTo(1750, 0.01));
      expect(food.status, BudgetStatus.overBudget);
    });

    test('scenario 6 style: forecast 2400 vs budget 2000', () {
      // Day 15: actual 1250 → pace ≈ 83.33 → *30 ≈ 2500; use day 15.625 equivalent
      // Construct: day 10, actual 800 → pace 80 → *30 = 2400
      final now = DateTime(2026, 11, 10);
      final forecast = buildVariablePaceForecast(
        [
          _exp(
            amount: 800,
            date: DateTime(2026, 11, 1),
            category: 'מזון',
          ),
        ],
        now: now,
        budgetsByCategory: {'מזון': 2000},
      );
      final food =
          forecast.byCategory.firstWhere((c) => c.category == 'מזון');
      expect(food.forecastEom, 2400);
      expect(food.forecastVariance, 400);
      expect(food.status, BudgetStatus.overBudget);
    });
  });

  group('monthly balance', () {
    test('includes fixed + variable; income minus expenses', () {
      final now = DateTime(2026, 11, 15);
      final balance = MonthlyBalance.fromExpenses(
        expenses: [
          _exp(amount: 6000, date: now, isFixed: 1, category: 'דיור', id: 1),
          _exp(amount: 5000, date: now, category: 'מזון', id: 2),
        ],
        totalIncome: 15000,
        now: now,
      );
      expect(balance.totalExpenses, 11000);
      expect(balance.balance, 4000);
      expect(balance.fixedExpenses, 6000);
      expect(balance.variableExpenses, 5000);
    });
  });

  group('daily variable trend', () {
    test('excludes fixed expenses', () {
      final now = DateTime(2026, 11, 3);
      final days = buildDailyVariableTrend(
        [
          _exp(amount: 4000, date: DateTime(2026, 11, 1), isFixed: 1, id: 1),
          _exp(amount: 50, date: DateTime(2026, 11, 2), id: 2),
        ],
        now: now,
      );
      expect(days.length, 3);
      expect(days[0].total, 0); // day 1 fixed only
      expect(days[1].total, 50);
      expect(days[2].total, 0);
      expect(days[1].date.day, 2);
    });
  });

  group('budget status thresholds', () {
    test('on track / watch / over', () {
      expect(
        resolveBudgetStatus(budget: 100, forecast: 90),
        BudgetStatus.onTrack,
      );
      expect(
        resolveBudgetStatus(budget: 100, forecast: 97),
        BudgetStatus.watch,
      );
      expect(
        resolveBudgetStatus(budget: 100, forecast: 101),
        BudgetStatus.overBudget,
      );
      expect(
        resolveBudgetStatus(budget: null, forecast: 50),
        BudgetStatus.noBudget,
      );
    });
  });
}
