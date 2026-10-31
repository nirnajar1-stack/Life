import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/income_type.dart';
import '../models/income_model.dart';
import '../models/recurring_income_model.dart';

class RecurringIncomeRepository {
  RecurringIncomeRepository(this._client);

  final SupabaseClient _client;
  static const _templates = 'recurring_incomes';
  static const _ledger = 'incomes';

  Future<List<RecurringIncomeModel>> fetchAll() async {
    final rows = await _client
        .from(_templates)
        .select()
        .order('created_at', ascending: false);
    final templates = (rows as List)
        .map((row) => RecurringIncomeModel.fromJson(
            Map<String, dynamic>.from(row as Map)))
        .toList();

    final recordedTitles = await _recordedTitlesThisMonth();
    return templates
        .map(
          (template) => template.copyWith(
            recordedThisMonth:
                _titleRecordedThisMonth(template.title, recordedTitles),
          ),
        )
        .toList();
  }

  Future<RecurringIncomeModel> insert(RecurringIncomeModel template) async {
    final row = await _client
        .from(_templates)
        .insert(template.toJsonForInsert())
        .select()
        .single();
    return RecurringIncomeModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> update(RecurringIncomeModel template) async {
    await _client
        .from(_templates)
        .update(template.toJsonForUpdate())
        .eq('id', template.id);
  }

  Future<void> delete(String id) async {
    await _client.from(_templates).delete().eq('id', id);
  }

  /// Records (or updates) net salary for the calendar month of [receivedAt].
  ///
  /// Manual only — never auto-runs. Same template + month → upsert amount/date.
  Future<IncomeModel> upsertMonthlyIncome({
    required RecurringIncomeModel template,
    required double netAmount,
    required DateTime receivedAt,
  }) async {
    if (netAmount <= 0) {
      throw ArgumentError('netAmount must be > 0');
    }

    final targetMonth = incomeMonthStart(receivedAt);
    final incomeDate = DateTime(
      receivedAt.year,
      receivedAt.month,
      receivedAt.day,
    );

    final existingId = await _findIncomeIdForTemplate(template, targetMonth);
    if (existingId != null) {
      await _client.from(_ledger).update({
        'created_at': incomeDate.toIso8601String(),
        'title': template.title,
        'amount': netAmount,
        'category': template.category,
        'sub_category': template.subCategory,
        'income_type': IncomeType.salary.dbValue,
        'source': 'life_app_recurring',
        'recurring_income_id': template.id,
      }).eq('id', existingId);
    } else {
      final income = IncomeModel(
        id: 0,
        createdAt: incomeDate,
        title: template.title,
        amount: netAmount,
        category: template.category,
        subCategory: template.subCategory,
        incomeType: IncomeType.salary,
        source: 'life_app_recurring',
        recurringIncomeId: template.id,
        insertedAt: DateTime.now(),
      );
      await _client.from(_ledger).insert(income.toJsonForInsert());
    }

    await _client.from(_templates).update({
      'amount': netAmount,
      'last_recorded_month':
          '${targetMonth.year.toString().padLeft(4, '0')}-'
          '${targetMonth.month.toString().padLeft(2, '0')}-01',
    }).eq('id', template.id);

    final rows = await _client
        .from(_ledger)
        .select()
        .eq('recurring_income_id', template.id)
        .gte('created_at', targetMonth.toIso8601String())
        .lt('created_at', incomeNextMonth(targetMonth).toIso8601String())
        .limit(1);
    final row = (rows as List).first;
    return IncomeModel.fromJson(Map<String, dynamic>.from(row as Map));
  }

  /// Kept for older call sites — delegates to [upsertMonthlyIncome].
  Future<void> recordMonthlyIncome({
    required RecurringIncomeModel template,
    required double netAmount,
    DateTime? month,
    DateTime? receivedAt,
  }) async {
    final date = receivedAt ??
        (month == null
            ? DateTime.now()
            : DateTime(
                month.year,
                month.month,
                template.dayOfMonth.clamp(1, 28),
              ));
    await upsertMonthlyIncome(
      template: template,
      netAmount: netAmount,
      receivedAt: date,
    );
  }

  Future<int?> _findIncomeIdForTemplate(
    RecurringIncomeModel template,
    DateTime month,
  ) async {
    final byId = await _incomeIdByRecurringId(template.id, month);
    if (byId != null) return byId;
    return _incomeIdBySimilarTitle(template.title, month);
  }

  Future<int?> _incomeIdByRecurringId(String templateId, DateTime month) async {
    final start = incomeMonthStart(month);
    final end = incomeNextMonth(start);
    final rows = await _client
        .from(_ledger)
        .select('id')
        .eq('recurring_income_id', templateId)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return (list.first as Map)['id'] as int;
  }

  Future<int?> _incomeIdBySimilarTitle(String title, DateTime month) async {
    final normalized = _normalizeTitle(title);
    if (normalized.isEmpty) return null;

    final start = incomeMonthStart(month);
    final end = incomeNextMonth(start);
    final rows = await _client
        .from(_ledger)
        .select('id, title')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final name = _normalizeTitle(map['title'] as String?);
      if (_titlesMatch(normalized, name)) {
        return (map['id'] as num).toInt();
      }
    }
    return null;
  }

  Future<Set<String>> _recordedTitlesThisMonth() async {
    final start = incomeMonthStart(DateTime.now());
    final end = incomeNextMonth(start);
    final rows = await _client
        .from(_ledger)
        .select('title')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());
    return (rows as List)
        .map((row) => _normalizeTitle((row as Map)['title'] as String?))
        .where((title) => title.isNotEmpty)
        .toSet();
  }

  bool _titleRecordedThisMonth(String title, Set<String> recordedTitles) {
    final normalized = _normalizeTitle(title);
    for (final recorded in recordedTitles) {
      if (_titlesMatch(normalized, recorded)) return true;
    }
    return false;
  }

  static String _normalizeTitle(String? value) =>
      (value ?? '').trim().toLowerCase();

  static bool _titlesMatch(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.startsWith(b) || b.startsWith(a);
  }
}
