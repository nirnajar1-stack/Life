import '../../data/models/expense_model.dart';
import 'expense_calendar.dart';
import 'expense_nature.dart';

/// Canonical paid amount for analytics / budget / forecast.
///
/// Prefer [ExpenseModel.paidAmount] when present; otherwise fall back to
/// legacy [ExpenseModel.amount]. Shared split still applies on top.
double effectiveGrossAmount(ExpenseModel expense) {
  return expense.paidAmount ?? expense.amount;
}

/// Personal share after shared-expense split of the effective paid amount.
double effectiveAmount(ExpenseModel expense) {
  return SharedExpenseFlag.actualAmount(
    effectiveGrossAmount(expense),
    expense.sharedExp,
  );
}

/// Calendar date that owns the expense for monthly bucketing.
///
/// Delegates to [ExpenseModel.transactionDate] (installment-aware).
DateTime transactionDate(ExpenseModel expense) => expense.transactionDate;

/// Date-source labels for UI / Telegram confirmations.
class ExpenseDateSource {
  const ExpenseDateSource._();

  static const receipt = 'receipt';
  static const telegram = 'telegram';
  static const manual = 'manual';
  static const import_ = 'import';
  static const legacy = 'legacy';

  static String hebrewLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case receipt:
        return 'חשבונית';
      case telegram:
        return 'תאריך ההודעה';
      case manual:
        return 'הזנה ידנית';
      case import_:
        return 'ייבוא';
      case legacy:
        return 'נתונים ישנים';
      default:
        return 'לא ידוע';
    }
  }
}

/// Priority labels when extracting a receipt total (OCR / AI).
const List<String> receiptTotalLabelPriority = [
  'Amount Paid',
  'Total Paid',
  'Grand Total',
  'סה"כ לתשלום',
  'סה״כ לתשלום',
  'סה"כ לאחר הנחות',
  'סה״כ לאחר הנחות',
  'סכום עסקה',
  'Net Total',
];

/// Picks the best paid total from structured receipt fields.
///
/// Prefers an explicit paid/total field; never uses gross before discount
/// when a paid amount is available.
double? resolveReceiptPaidAmount({
  double? amountPaid,
  double? totalPaid,
  double? grandTotal,
  double? totalAfterDiscount,
  double? transactionAmount,
  double? netTotal,
  double? lineItemsSum,
}) {
  for (final candidate in [
    amountPaid,
    totalPaid,
    grandTotal,
    totalAfterDiscount,
    transactionAmount,
    netTotal,
  ]) {
    if (candidate != null && candidate > 0) return candidate;
  }
  if (lineItemsSum != null && lineItemsSum > 0) return lineItemsSum;
  return null;
}

/// Line total after discount — prefer final line total over qty × unit.
double resolveLineItemTotal({
  required double quantity,
  required double unitPrice,
  double? lineGross,
  double? lineDiscount,
  double? finalLineTotal,
}) {
  if (finalLineTotal != null) return finalLineTotal;
  final gross = lineGross ?? (quantity * unitPrice);
  final discount = lineDiscount ?? 0;
  return gross - discount;
}
