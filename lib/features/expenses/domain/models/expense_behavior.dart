import '../../data/models/expense_model.dart';
import '../../data/models/recurring_expense_model.dart';

/// Behavioral classification of an expense for UI / forecast / budget.
enum ExpenseBehaviorType {
  fixedCommitment,
  recurringVariable,
  variableDiscretionary,
  oneTime,
}

extension ExpenseBehaviorTypeX on ExpenseBehaviorType {
  String get dbValue {
    switch (this) {
      case ExpenseBehaviorType.fixedCommitment:
        return 'fixed_commitment';
      case ExpenseBehaviorType.recurringVariable:
        return 'recurring_variable';
      case ExpenseBehaviorType.variableDiscretionary:
        return 'variable_discretionary';
      case ExpenseBehaviorType.oneTime:
        return 'one_time';
    }
  }

  String get labelHe {
    switch (this) {
      case ExpenseBehaviorType.fixedCommitment:
        return 'התחייבות קבועה';
      case ExpenseBehaviorType.recurringVariable:
        return 'חוזרת משתנה';
      case ExpenseBehaviorType.variableDiscretionary:
        return 'משתנה';
      case ExpenseBehaviorType.oneTime:
        return 'חד־פעמית';
    }
  }

  String get shortLabelHe {
    switch (this) {
      case ExpenseBehaviorType.fixedCommitment:
        return 'קבועה';
      case ExpenseBehaviorType.recurringVariable:
        return 'חוזרת משתנה';
      case ExpenseBehaviorType.variableDiscretionary:
        return 'משתנה';
      case ExpenseBehaviorType.oneTime:
        return 'חד־פעמית';
    }
  }

  /// Legacy `is_fixed` column mapping for writes.
  int get isFixedDbValue {
    switch (this) {
      case ExpenseBehaviorType.fixedCommitment:
        return 1;
      case ExpenseBehaviorType.recurringVariable:
      case ExpenseBehaviorType.variableDiscretionary:
      case ExpenseBehaviorType.oneTime:
        return 0;
    }
  }

  /// Included in daily variable spending pace / forecast.
  bool get countsInDailyPace {
    switch (this) {
      case ExpenseBehaviorType.variableDiscretionary:
        return true;
      case ExpenseBehaviorType.fixedCommitment:
      case ExpenseBehaviorType.recurringVariable:
      case ExpenseBehaviorType.oneTime:
        return false;
    }
  }

  /// Included in monthly cashflow / expected outflow / balance.
  bool get countsInMonthlyCashflow => true;

  static ExpenseBehaviorType? tryParse(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'fixed_commitment':
        return ExpenseBehaviorType.fixedCommitment;
      case 'recurring_variable':
        return ExpenseBehaviorType.recurringVariable;
      case 'variable_discretionary':
        return ExpenseBehaviorType.variableDiscretionary;
      case 'one_time':
        return ExpenseBehaviorType.oneTime;
      default:
        return null;
    }
  }
}

/// Generic derivation for new + legacy records (no DB backfill required).
///
/// Priority:
/// 1. Stored [expenseBehaviorType] when set
/// 2. Known fixed commitments (rent, car loan, insurance, subscriptions…)
/// 3. Known recurring-variable utilities (electricity, water…)
/// 4. Installment group → committed payment ([fixedCommitment])
/// 5. Else [variableDiscretionary]
///
/// Note: ordinary one-off shopping (clothes, restaurant, small home goods)
/// stays [variableDiscretionary]. [oneTime] is only when explicitly stored
/// or strong exceptional signals (flight/hotel/major furniture/computer).
ExpenseBehaviorType deriveExpenseBehaviorType({
  String? expenseBehaviorType,
  String? itemName,
  String? category,
  String? subCategory,
  int? isFixed,
  String? installmentGroupId,
  bool? amountVariable,
}) {
  final stored = ExpenseBehaviorTypeX.tryParse(expenseBehaviorType);
  if (stored != null) return stored;

  final name = (itemName ?? '').toLowerCase().trim();
  final cat = (category ?? '').toLowerCase().trim();
  final sub = (subCategory ?? '').toLowerCase().trim();
  final blob = '$name $cat $sub'.trim();

  if (_matchesAny(blob, _fixedCommitmentSignals)) {
    return ExpenseBehaviorType.fixedCommitment;
  }
  // Utilities: prefer item name (avoids mis-tagged snack rows with sub=מים).
  // Also accept housing subcategory when the title itself looks utility-like
  // or is a short label equal to the subcategory.
  if (_nameHasSignal(name, _recurringVariableSignals) ||
      (cat.contains('דיור') &&
          _matchesAny(sub, _recurringVariableSignals) &&
          (name.isEmpty ||
              name == sub ||
              _nameHasSignal(name, _recurringVariableSignals)))) {
    return ExpenseBehaviorType.recurringVariable;
  }

  final mid = installmentGroupId?.trim();
  if (mid != null && mid.isNotEmpty) {
    return ExpenseBehaviorType.fixedCommitment;
  }

  // Template flag from recurring_expenses (amount_variable).
  if (amountVariable == true) {
    return ExpenseBehaviorType.recurringVariable;
  }
  if (amountVariable == false && isFixed == 1) {
    return ExpenseBehaviorType.fixedCommitment;
  }

  if (_nameHasSignal(name, _oneTimeSignals) ||
      _matchesAny('$cat $sub', _oneTimeCategorySignals)) {
    return ExpenseBehaviorType.oneTime;
  }

  // Soft legacy: is_fixed alone is not enough for UI correctness, but when
  // no better signal exists and the row was marked fixed, treat as commitment.
  if (isFixed == 1) {
    return ExpenseBehaviorType.fixedCommitment;
  }

  return ExpenseBehaviorType.variableDiscretionary;
}

ExpenseBehaviorType deriveExpenseBehavior(ExpenseModel e) {
  return deriveExpenseBehaviorType(
    expenseBehaviorType: e.expenseBehaviorType,
    itemName: e.itemName,
    category: e.category,
    subCategory: e.subCategory,
    isFixed: e.isFixed,
    installmentGroupId: e.installmentGroupId,
  );
}

ExpenseBehaviorType deriveRecurringTemplateBehavior(RecurringExpenseModel t) {
  return deriveExpenseBehaviorType(
    expenseBehaviorType: t.expenseBehaviorType,
    itemName: t.title,
    category: t.category,
    subCategory: t.subCategory,
    isFixed: t.amountVariable ? 0 : 1,
    amountVariable: t.amountVariable,
  );
}

bool _matchesAny(String blob, List<String> signals) {
  for (final s in signals) {
    if (blob.contains(s)) return true;
  }
  return false;
}

/// Name match that avoids glued prefixes (e.g. "מדבקות למחשב נייד").
bool _nameHasSignal(String name, List<String> signals) {
  for (final s in signals) {
    if (s.isEmpty) continue;
    if (name == s || name.startsWith('$s ')) return true;
    var start = 0;
    while (true) {
      final idx = name.indexOf(s, start);
      if (idx < 0) break;
      if (idx == 0) return true;
      final prev = name[idx - 1];
      if (prev == ' ' || prev == '-' || prev == ',' || prev == '/') {
        return true;
      }
      start = idx + 1;
    }
  }
  return false;
}

const _fixedCommitmentSignals = [
  'הלוואת רכב',
  'הלוואה לקניית הרכב',
  'הלוואה לרכב',
  'שכירות',
  'שכר דירה',
  'שכ"ד',
  'שכ״ד',
  'ביטוח רכב',
  'ביטוח בריאות',
  'ביטוח',
  'מנוי',
  'נטפליקס',
  'netflix',
  'spotify',
  'paddle',
  'cursor',
  'open ai',
  'openai',
  'hot mobile',
  'ועד בית',
  'אינטרנט',
  'טלוויזיה',
];

const _recurringVariableSignals = [
  'חשמל',
  'מים',
  'ארנונה',
  'גז',
  'צריכה ביתית',
];

/// Exceptional / significant one-offs — NOT ordinary shopping.
/// Matched primarily against item name (avoid accessory false-positives).
const _oneTimeSignals = [
  'טיסה',
  'טיסות',
  'מלון',
  'מלונות',
  'חופשה',
  'נופש',
  'בודפשט',
  'ניו יורק',
  'מחשב נייד',
  'לפטופ',
  'macbook',
  'iphone',
  'ריהוט',
];

/// Category/sub signals that imply exceptional one-offs.
const _oneTimeCategorySignals = [
  'טיסות',
  'מלונות',
  'הוצאות חופשה',
  'נסיעות ונופש',
];
