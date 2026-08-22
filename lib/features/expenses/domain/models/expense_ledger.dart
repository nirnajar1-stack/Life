import '../../data/models/expense_model.dart';
import 'expense_nature.dart';

/// A single ledger row: either one expense, or a receipt-style group
/// of line items that share the same [messageId] (e.g. a supermarket run).
class ExpenseTransaction {
  const ExpenseTransaction({
    required this.items,
    required this.date,
    this.messageId,
  });

  /// Line items in this transaction (always at least one).
  final List<ExpenseModel> items;

  /// Transaction date (taken from the earliest item's createdAt).
  final DateTime date;

  /// Shared message_id when this is a grouped receipt; null for singles.
  final String? messageId;

  bool get isGrouped => items.length > 1;

  int get itemCount => items.length;

  double get total =>
      items.fold(0, (sum, item) => sum + item.amount);

  /// Personal share after shared-expense split.
  double get actualTotal =>
      items.fold(0, (sum, item) => sum + item.actualAmount);

  int? get sharedSplit {
    int? value;
    for (final item in items) {
      final split = SharedExpenseFlag.splitCount(item.sharedExp);
      if (split == null) continue;
      value ??= split;
      if (split != value) return value;
    }
    return value;
  }

  bool get isShared =>
      items.any((item) => SharedExpenseFlag.isShared(item.sharedExp));

  /// Dominant / primary category for the header row.
  String get primaryCategory {
    if (items.isEmpty) return 'ללא קטגוריה';
    if (!isGrouped) return items.first.normalizedCategory;

    final counts = <String, int>{};
    for (final item in items) {
      final key = item.normalizedCategory.isEmpty
          ? 'ללא קטגוריה'
          : item.normalizedCategory;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// Display title for the collapsed row.
  String get title {
    if (!isGrouped) {
      final name = items.first.itemName;
      return name.isEmpty ? '(ללא שם)' : name;
    }
    return 'קנייה · $primaryCategory';
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (title.toLowerCase().contains(q)) return true;
    if (primaryCategory.toLowerCase().contains(q)) return true;
    return items.any((item) {
      return item.itemName.toLowerCase().contains(q) ||
          item.normalizedCategory.toLowerCase().contains(q) ||
          item.subCategory.toLowerCase().contains(q) ||
          (item.installmentLabel?.toLowerCase().contains(q) ?? false);
    });
  }

  /// Short preview of line items for the collapsed subtitle.
  String get itemsPreview {
    if (!isGrouped) {
      final sub = items.first.subCategory.trim();
      return sub.isEmpty ? primaryCategory : '$primaryCategory · $sub';
    }
    final names = items
        .map((e) => e.itemName.trim())
        .where((n) => n.isNotEmpty)
        .take(3)
        .toList();
    final preview = names.join(' · ');
    final remaining = itemCount - names.length;
    if (remaining > 0) return '$preview · +$remaining';
    return preview;
  }
}

/// One calendar month of transactions, newest first inside.
class ExpenseMonthSection {
  const ExpenseMonthSection({
    required this.year,
    required this.month,
    required this.transactions,
  });

  final int year;
  final int month;
  final List<ExpenseTransaction> transactions;

  DateTime get monthStart => DateTime(year, month);

  double get total =>
      transactions.fold(0, (sum, tx) => sum + tx.actualTotal);

  int get transactionCount => transactions.length;

  int get lineItemCount =>
      transactions.fold(0, (sum, tx) => sum + tx.itemCount);
}

/// Builds a chronological ledger: groups by message_id, then by month.
///
/// Financial presentation rules:
/// - Newest months first
/// - Within a month, newest transactions first
/// - Rows with the same non-empty message_id collapse into one receipt
/// - Rows without message_id stay as single-line transactions
List<ExpenseMonthSection> buildExpenseLedger(List<ExpenseModel> expenses) {
  if (expenses.isEmpty) return const [];

  final Map<String, List<ExpenseModel>> byMessage = {};
  final List<ExpenseModel> singles = [];

  for (final expense in expenses) {
    final mid = expense.messageId?.trim();
    if (mid == null || mid.isEmpty) {
      singles.add(expense);
      continue;
    }
    byMessage.putIfAbsent(mid, () => []).add(expense);
  }

  final List<ExpenseTransaction> transactions = [];

  for (final entry in byMessage.entries) {
    final items = List<ExpenseModel>.from(entry.value)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final date = items
        .map((e) => e.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    transactions.add(ExpenseTransaction(
      items: items,
      date: date,
      messageId: entry.key,
    ));
  }

  for (final expense in singles) {
    transactions.add(ExpenseTransaction(
      items: [expense],
      date: expense.createdAt,
      messageId: null,
    ));
  }

  transactions.sort((a, b) => b.date.compareTo(a.date));

  final Map<String, List<ExpenseTransaction>> byMonth = {};
  for (final tx in transactions) {
    final key =
        '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
    byMonth.putIfAbsent(key, () => []).add(tx);
  }

  final monthKeys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

  return monthKeys.map((key) {
    final parts = key.split('-');
    return ExpenseMonthSection(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      transactions: byMonth[key]!,
    );
  }).toList();
}
