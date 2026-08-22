import '../../data/models/income_model.dart';

class IncomeMonthSection {
  const IncomeMonthSection({
    required this.year,
    required this.month,
    required this.items,
  });

  final int year;
  final int month;
  final List<IncomeModel> items;

  double get total => items.fold<double>(0, (sum, item) => sum + item.amount);
}

List<IncomeMonthSection> buildIncomeLedger(List<IncomeModel> incomes) {
  final grouped = <String, List<IncomeModel>>{};
  for (final income in incomes) {
    final key = '${income.createdAt.year}-${income.createdAt.month}';
    grouped.putIfAbsent(key, () => []).add(income);
  }

  final sections = grouped.entries.map((entry) {
    final parts = entry.key.split('-');
    final items = [...entry.value]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return IncomeMonthSection(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      items: items,
    );
  }).toList();

  sections.sort((a, b) {
    if (a.year != b.year) return b.year.compareTo(a.year);
    return b.month.compareTo(a.month);
  });
  return sections;
}

List<IncomeModel> filterIncomesByMonth(
  List<IncomeModel> incomes,
  DateTime month,
) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  return incomes
      .where((income) =>
          !income.createdAt.isBefore(start) && income.createdAt.isBefore(end))
      .toList();
}
