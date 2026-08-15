DateTime? nextRecurrenceDate(String? rule, DateTime from) {
  if (rule == null || rule.trim().isEmpty) return null;
  final parts = <String, String>{};
  for (final chunk in rule.split(';')) {
    final pair = chunk.split('=');
    if (pair.length == 2) {
      parts[pair[0].trim().toUpperCase()] = pair[1].trim().toUpperCase();
    }
  }
  final freq = parts['FREQ'];
  final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
  final start = DateTime(from.year, from.month, from.day);
  switch (freq) {
    case 'DAILY':
      return start.add(Duration(days: interval));
    case 'WEEKLY':
      return start.add(Duration(days: 7 * interval));
    case 'MONTHLY':
      return DateTime(start.year, start.month + interval, start.day);
    default:
      return start.add(const Duration(days: 1));
  }
}
