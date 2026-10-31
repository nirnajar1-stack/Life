import '../../data/models/expense_model.dart';
import 'expense_category_taxonomy.dart';
import 'expense_ledger.dart';
import 'expense_nature.dart';
import 'expense_period.dart';

/// Named amount bucket used across dashboard slices.
class NamedAmount {
  const NamedAmount({
    required this.label,
    required this.total,
    required this.count,
  });

  final String label;
  final double total;
  final int count;

  double shareOf(double grandTotal) =>
      grandTotal <= 0 ? 0 : (total / grandTotal).clamp(0.0, 1.0);
}

/// One calendar month aggregate for the trend chart.
class MonthSpend {
  const MonthSpend({
    required this.year,
    required this.month,
    required this.total,
    required this.itemCount,
    required this.transactionCount,
    this.fixedTotal = 0,
    this.variableTotal = 0,
    this.installmentTotal = 0,
  });

  final int year;
  final int month;
  final double total;
  final int itemCount;
  final int transactionCount;
  final double fixedTotal;
  final double variableTotal;
  final double installmentTotal;

  DateTime get monthStart => DateTime(year, month);

  double get committedTotal => fixedTotal + installmentTotal;
}

/// One calendar day aggregate for the daily burn chart.
class DaySpend {
  const DaySpend({
    required this.date,
    required this.total,
    required this.itemCount,
  });

  final DateTime date;
  final double total;
  final int itemCount;
}

/// Side-by-side category comparison between two months.
class CategoryMonthCompare {
  const CategoryMonthCompare({
    required this.category,
    required this.currentTotal,
    required this.previousTotal,
  });

  final String category;
  final double currentTotal;
  final double previousTotal;

  double get delta => currentTotal - previousTotal;

  double? get percentChange {
    if (previousTotal <= 0) return currentTotal > 0 ? 100 : null;
    return (delta / previousTotal) * 100;
  }
}

/// Financial dashboard slices over a (optionally period-filtered) dataset.
class ExpenseDashboard {
  const ExpenseDashboard({
    required this.period,
    required this.grandTotal,
    required this.totalItems,
    required this.thisMonthTotal,
    required this.previousMonthTotal,
    required this.averageMonthTotal,
    required this.monthlyTrend,
    required this.parentCategories,
    required this.rawCategories,
    required this.variableTotal,
    required this.fixedTotal,
    required this.installmentTotal,
    required this.variableCount,
    required this.fixedCount,
    required this.installmentCount,
    required this.bySource,
    required this.topTransactions,
    required this.topItems,
    required this.monthComparison,
    required this.currentMonthLabel,
    required this.previousMonthLabel,
    this.dailyTrend = const [],
    this.averageDailySpend = 0,
    this.peakDaySpend = 0,
    this.peakDayLabel = '',
    this.daysWithSpend = 0,
  });

  final ExpensePeriod period;

  final double grandTotal;
  final int totalItems;

  final double thisMonthTotal;
  final double previousMonthTotal;
  final double averageMonthTotal;

  /// Newest months first (past months only — never future).
  final List<MonthSpend> monthlyTrend;

  /// Chronological daily series for the active window (oldest → newest).
  final List<DaySpend> dailyTrend;
  final double averageDailySpend;
  final double peakDaySpend;
  final String peakDayLabel;
  final int daysWithSpend;

  final List<NamedAmount> parentCategories;

  /// Raw DB categories — secondary / diagnostic.
  final List<NamedAmount> rawCategories;

  final double variableTotal;
  final double fixedTotal;
  final double installmentTotal;
  final int variableCount;
  final int fixedCount;
  final int installmentCount;

  final List<NamedAmount> bySource;

  final List<ExpenseTransaction> topTransactions;
  final List<ExpenseModel> topItems;

  /// Parent-category MoM comparison (current calendar month vs previous).
  final List<CategoryMonthCompare> monthComparison;
  final String currentMonthLabel;
  final String previousMonthLabel;

  double get monthOverMonthDelta => thisMonthTotal - previousMonthTotal;

  double? get monthOverMonthPercent {
    if (previousMonthTotal <= 0) return null;
    return (monthOverMonthDelta / previousMonthTotal) * 100;
  }

  /// Share of period spend that is committed (fixed + installments).
  double get committedShare {
    final total = variableTotal + fixedTotal + installmentTotal;
    if (total <= 0) return 0;
    return ((fixedTotal + installmentTotal) / total).clamp(0.0, 1.0);
  }

  static ExpenseDashboard empty(ExpensePeriod period) => ExpenseDashboard(
        period: period,
        grandTotal: 0,
        totalItems: 0,
        thisMonthTotal: 0,
        previousMonthTotal: 0,
        averageMonthTotal: 0,
        monthlyTrend: const [],
        parentCategories: const [],
        rawCategories: const [],
        variableTotal: 0,
        fixedTotal: 0,
        installmentTotal: 0,
        variableCount: 0,
        fixedCount: 0,
        installmentCount: 0,
        bySource: const [],
        topTransactions: const [],
        topItems: const [],
        monthComparison: const [],
        currentMonthLabel: '',
        previousMonthLabel: '',
      );
}

const List<String> _hebrewMonths = [
  '',
  'ינואר',
  'פברואר',
  'מרץ',
  'אפריל',
  'מאי',
  'יוני',
  'יולי',
  'אוגוסט',
  'ספטמבר',
  'אוקטובר',
  'נובמבר',
  'דצמבר',
];

String _cleanSource(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'לא ידוע';
  return raw.replaceAll('"', '').trim();
}

String _hebrewSourceLabel(String source) {
  switch (source.toLowerCase()) {
    case 'whatsapp':
      return 'WhatsApp';
    case 'telegram':
      return 'Telegram';
    case 'telegram_media':
      return 'Telegram מדיה';
    case 'google_sheets':
      return 'Google Sheets';
    case 'life_app':
      return 'Life App';
    default:
      return source;
  }
}

String _monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Builds a contiguous daily series for the active window.
///
/// For "this month" fills every day from month start through today.
/// For longer periods uses the last [maxDays] days that fall inside [expenses].
List<DaySpend> _buildDailyTrend(
  List<ExpenseModel> expenses, {
  required ExpensePeriod period,
  required DateTime now,
  int maxDays = 31,
}) {
  final today = _dateOnly(now);
  late DateTime windowStart;
  late DateTime windowEnd;

  if (period == ExpensePeriod.thisMonth) {
    windowStart = DateTime(now.year, now.month);
    windowEnd = today;
  } else {
    windowEnd = today;
    windowStart = today.subtract(Duration(days: maxDays - 1));
    if (expenses.isNotEmpty) {
      final earliest = expenses
          .map((e) => _dateOnly(e.createdAt))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (earliest.isAfter(windowStart)) windowStart = earliest;
    }
  }

  final Map<String, double> dayTotals = {};
  final Map<String, int> dayCounts = {};
  for (final e in expenses) {
    final day = _dateOnly(e.createdAt);
    if (day.isBefore(windowStart) || day.isAfter(windowEnd)) continue;
    final key = _dayKey(day);
    dayTotals[key] = (dayTotals[key] ?? 0) + e.actualAmount;
    dayCounts[key] = (dayCounts[key] ?? 0) + 1;
  }

  final days = <DaySpend>[];
  for (var cursor = windowStart;
      !cursor.isAfter(windowEnd);
      cursor = cursor.add(const Duration(days: 1))) {
    final key = _dayKey(cursor);
    days.add(
      DaySpend(
        date: cursor,
        total: dayTotals[key] ?? 0,
        itemCount: dayCounts[key] ?? 0,
      ),
    );
  }
  return days;
}

/// Builds dashboard slices.
///
/// [expenses] — period-filtered rows (for period totals / categories).
/// [calendarExpenses] — preferably all past+current rows (for MoM + trend).
/// When [calendarExpenses] is null, falls back to [expenses].
ExpenseDashboard buildExpenseDashboard(
  List<ExpenseModel> expenses, {
  ExpensePeriod period = ExpensePeriod.all,
  DateTime? now,
  List<ExpenseModel>? calendarExpenses,
}) {
  final n = now ?? DateTime.now();
  final nextMonthStart = DateTime(n.year, n.month + 1);
  final prevDate = DateTime(n.year, n.month - 1);
  final thisMonthKey = _monthKey(DateTime(n.year, n.month));
  final prevMonthKey = _monthKey(prevDate);

  final calendar = (calendarExpenses ?? expenses)
      .where((e) => e.createdAt.isBefore(nextMonthStart))
      .toList();

  if (expenses.isEmpty && calendar.isEmpty) {
    return ExpenseDashboard(
      period: period,
      grandTotal: 0,
      totalItems: 0,
      thisMonthTotal: 0,
      previousMonthTotal: 0,
      averageMonthTotal: 0,
      monthlyTrend: const [],
      parentCategories: const [],
      rawCategories: const [],
      variableTotal: 0,
      fixedTotal: 0,
      installmentTotal: 0,
      variableCount: 0,
      fixedCount: 0,
      installmentCount: 0,
      bySource: const [],
      topTransactions: const [],
      topItems: const [],
      monthComparison: const [],
      currentMonthLabel: '${_hebrewMonths[n.month]} ${n.year}',
      previousMonthLabel: '${_hebrewMonths[prevDate.month]} ${prevDate.year}',
    );
  }

  double grandTotal = 0;
  double variableTotal = 0;
  double fixedTotal = 0;
  double installmentTotal = 0;
  int variableCount = 0;
  int fixedCount = 0;
  int installmentCount = 0;

  final Map<String, double> parentTotals = {};
  final Map<String, int> parentCounts = {};
  final Map<String, double> rawTotals = {};
  final Map<String, int> rawCounts = {};
  final Map<String, double> sourceTotals = {};
  final Map<String, int> sourceCounts = {};

  for (final e in expenses) {
    final personal = e.actualAmount;
    grandTotal += personal;

    final parent = ExpenseCategoryTaxonomy.resolveParent(e.category);
    parentTotals[parent] = (parentTotals[parent] ?? 0) + personal;
    parentCounts[parent] = (parentCounts[parent] ?? 0) + 1;

    final raw =
        e.normalizedCategory.isEmpty ? 'ללא קטגוריה' : e.normalizedCategory;
    rawTotals[raw] = (rawTotals[raw] ?? 0) + personal;
    rawCounts[raw] = (rawCounts[raw] ?? 0) + 1;

    final nature = ExpenseNatureX.resolve(
      isFixed: e.isFixed,
      installmentGroupId: e.installmentGroupId,
    );
    switch (nature) {
      case ExpenseNature.fixed:
        fixedTotal += personal;
        fixedCount++;
      case ExpenseNature.installment:
        installmentTotal += personal;
        installmentCount++;
      case ExpenseNature.variable:
        variableTotal += personal;
        variableCount++;
    }

    final source = _cleanSource(e.source);
    sourceTotals[source] = (sourceTotals[source] ?? 0) + personal;
    sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
  }

  // Calendar MoM + trend always use past/current months from [calendar].
  double thisMonthTotal = 0;
  double previousMonthTotal = 0;
  final Map<String, double> monthTotals = {};
  final Map<String, int> monthItems = {};
  final Map<String, Set<String>> monthTxKeys = {};
  final Map<String, double> monthFixed = {};
  final Map<String, double> monthVariable = {};
  final Map<String, double> monthInstallment = {};
  final Map<String, double> thisMonthByParent = {};
  final Map<String, double> prevMonthByParent = {};

  for (final e in calendar) {
    final personal = e.actualAmount;
    final monthKey = _monthKey(e.createdAt);
    monthTotals[monthKey] = (monthTotals[monthKey] ?? 0) + personal;
    monthItems[monthKey] = (monthItems[monthKey] ?? 0) + 1;

    final nature = ExpenseNatureX.resolve(
      isFixed: e.isFixed,
      installmentGroupId: e.installmentGroupId,
    );
    switch (nature) {
      case ExpenseNature.fixed:
        monthFixed[monthKey] = (monthFixed[monthKey] ?? 0) + personal;
      case ExpenseNature.variable:
        monthVariable[monthKey] = (monthVariable[monthKey] ?? 0) + personal;
      case ExpenseNature.installment:
        monthInstallment[monthKey] =
            (monthInstallment[monthKey] ?? 0) + personal;
    }

    final txKey = (e.messageId != null && e.messageId!.trim().isNotEmpty)
        ? 'm:${e.messageId!.trim()}'
        : 'i:${e.id}';
    monthTxKeys.putIfAbsent(monthKey, () => {}).add(txKey);

    final parent = ExpenseCategoryTaxonomy.resolveParent(e.category);
    if (monthKey == thisMonthKey) {
      thisMonthTotal += personal;
      thisMonthByParent[parent] = (thisMonthByParent[parent] ?? 0) + personal;
    }
    if (monthKey == prevMonthKey) {
      previousMonthTotal += personal;
      prevMonthByParent[parent] = (prevMonthByParent[parent] ?? 0) + personal;
    }
  }

  final monthKeys = monthTotals.keys.toList()..sort((a, b) => b.compareTo(a));
  final monthlyTrend = monthKeys.map((key) {
    final parts = key.split('-');
    return MonthSpend(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      total: monthTotals[key]!,
      itemCount: monthItems[key] ?? 0,
      transactionCount: monthTxKeys[key]?.length ?? 0,
      fixedTotal: monthFixed[key] ?? 0,
      variableTotal: monthVariable[key] ?? 0,
      installmentTotal: monthInstallment[key] ?? 0,
    );
  }).toList();

  final dailyTrend = _buildDailyTrend(expenses, period: period, now: n);
  final daysWithSpend = dailyTrend.where((d) => d.total > 0).length;
  final dailySpendSum =
      dailyTrend.fold<double>(0, (sum, d) => sum + d.total);
  final averageDailySpend = dailyTrend.isEmpty
      ? 0.0
      : dailySpendSum / dailyTrend.length;
  DaySpend? peakDay;
  for (final day in dailyTrend) {
    if (peakDay == null || day.total > peakDay.total) peakDay = day;
  }
  final peakDaySpend = peakDay?.total ?? 0;
  final peakDayLabel = peakDay == null || peakDay.total <= 0
      ? ''
      : '${peakDay.date.day}/${peakDay.date.month}';

  final activeMonths = monthlyTrend.where((m) => m.total >= 100).toList();
  final averageMonthTotal = activeMonths.isEmpty
      ? 0.0
      : activeMonths.fold<double>(0, (s, m) => s + m.total) /
          activeMonths.length;

  final parentCategories = parentTotals.entries
      .map((e) => NamedAmount(
            label: e.key,
            total: e.value,
            count: parentCounts[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  final rawCategories = rawTotals.entries
      .map((e) => NamedAmount(
            label: e.key,
            total: e.value,
            count: rawCounts[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  final bySource = sourceTotals.entries
      .map((e) => NamedAmount(
            label: _hebrewSourceLabel(e.key),
            total: e.value,
            count: sourceCounts[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  final compareKeys = <String>{
    ...thisMonthByParent.keys,
    ...prevMonthByParent.keys,
  };
  final monthComparison = compareKeys
      .map((cat) => CategoryMonthCompare(
            category: cat,
            currentTotal: thisMonthByParent[cat] ?? 0,
            previousTotal: prevMonthByParent[cat] ?? 0,
          ))
      .toList()
    ..sort((a, b) =>
        (b.currentTotal + b.previousTotal)
            .compareTo(a.currentTotal + a.previousTotal));

  final transactions = buildExpenseLedger(expenses)
      .expand((month) => month.transactions)
      .toList()
    ..sort((a, b) => b.actualTotal.compareTo(a.actualTotal));

  final topItems = List<ExpenseModel>.from(expenses)
    ..sort((a, b) => b.actualAmount.compareTo(a.actualAmount));

  return ExpenseDashboard(
    period: period,
    grandTotal: grandTotal,
    totalItems: expenses.length,
    thisMonthTotal: thisMonthTotal,
    previousMonthTotal: previousMonthTotal,
    averageMonthTotal: averageMonthTotal,
    monthlyTrend: monthlyTrend.take(8).toList(),
    dailyTrend: dailyTrend,
    averageDailySpend: averageDailySpend,
    peakDaySpend: peakDaySpend,
    peakDayLabel: peakDayLabel,
    daysWithSpend: daysWithSpend,
    parentCategories: parentCategories,
    rawCategories: rawCategories.take(8).toList(),
    variableTotal: variableTotal,
    fixedTotal: fixedTotal,
    installmentTotal: installmentTotal,
    variableCount: variableCount,
    fixedCount: fixedCount,
    installmentCount: installmentCount,
    bySource: bySource,
    topTransactions: transactions.take(5).toList(),
    topItems: topItems.take(5).toList(),
    monthComparison: monthComparison,
    currentMonthLabel: '${_hebrewMonths[n.month]} ${n.year}',
    previousMonthLabel: '${_hebrewMonths[prevDate.month]} ${prevDate.year}',
  );
}

