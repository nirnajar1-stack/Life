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

  /// Returns the ledger row for [template] in [month], if any.
  Future<IncomeModel?> fetchIncomeForMonth({
    required RecurringIncomeModel template,
    required DateTime month,
  }) async {
    final start = incomeMonthStart(month);
    final end = incomeNextMonth(start);

    final byId = await _client
        .from(_ledger)
        .select()
        .eq('recurring_income_id', template.id)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .order('created_at')
        .limit(1);
    final idRows = byId as List;
    if (idRows.isNotEmpty) {
      return IncomeModel.fromJson(Map<String, dynamic>.from(idRows.first as Map));
    }

    // Fallback for older rows without recurring_income_id.
    final byTitle = await _client
        .from(_ledger)
        .select()
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .order('created_at');
    final normalized = _normalizeTitle(template.title);
    for (final row in byTitle as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final name = _normalizeTitle(map['title'] as String?);
      if (_titlesMatch(normalized, name)) {
        return IncomeModel.fromJson(map);
      }
    }
    return null;
  }

  /// Creates or updates the net amount for [template] on [incomeDate].
  /// The period is the calendar month of [incomeDate].
  Future<IncomeModel> upsertMonthlyIncome({
    required RecurringIncomeModel template,
    required double netAmount,
    required DateTime incomeDate,
  }) async {
    if (netAmount <= 0) {
      throw ArgumentError('netAmount must be > 0');
    }

    final targetMonth = incomeMonthStart(incomeDate);
    final day = incomeDate.day.clamp(1, _daysInMonth(targetMonth));
    final resolvedDate = DateTime(targetMonth.year, targetMonth.month, day);

    final existing = await fetchIncomeForMonth(
      template: template,
      month: targetMonth,
    );

    late final IncomeModel saved;
    if (existing != null) {
      final row = await _client
          .from(_ledger)
          .update({
            'amount': netAmount,
            'created_at': resolvedDate.toIso8601String(),
            'title': template.title,
            'category': template.category,
            'sub_category': template.subCategory,
            'recurring_income_id': template.id,
          })
          .eq('id', existing.id)
          .select()
          .single();
      saved = IncomeModel.fromJson(Map<String, dynamic>.from(row));
    } else {
      final income = IncomeModel(
        id: 0,
        createdAt: resolvedDate,
        title: template.title,
        amount: netAmount,
        category: template.category,
        subCategory: template.subCategory,
        incomeType: IncomeType.salary,
        source: 'life_app_recurring',
        recurringIncomeId: template.id,
        insertedAt: DateTime.now(),
      );
      final row =
          await _client.from(_ledger).insert(income.toJsonForInsert()).select().single();
      saved = IncomeModel.fromJson(Map<String, dynamic>.from(row));
    }

    await _updateTemplateAfterRecord(
      template: template,
      netAmount: netAmount,
      targetMonth: targetMonth,
    );
    return saved;
  }

  /// Backward-compatible alias used by older call sites.
  Future<void> recordMonthlyIncome({
    required RecurringIncomeModel template,
    required double netAmount,
    DateTime? month,
    DateTime? incomeDate,
  }) async {
    final date = incomeDate ??
        () {
          final m = incomeMonthStart(month ?? DateTime.now());
          final day = template.dayOfMonth.clamp(1, _daysInMonth(m));
          return DateTime(m.year, m.month, day);
        }();
    await upsertMonthlyIncome(
      template: template,
      netAmount: netAmount,
      incomeDate: date,
    );
  }

  Future<void> _updateTemplateAfterRecord({
    required RecurringIncomeModel template,
    required double netAmount,
    required DateTime targetMonth,
  }) async {
    final last = template.lastRecordedMonth;
    final shouldBumpLast = last == null ||
        !targetMonth.isBefore(incomeMonthStart(last));

    await _client.from(_templates).update({
      // Prefill "last amount" only when recording the latest period.
      if (shouldBumpLast) 'amount': netAmount,
      if (shouldBumpLast)
        'last_recorded_month':
            '${targetMonth.year.toString().padLeft(4, '0')}-'
            '${targetMonth.month.toString().padLeft(2, '0')}-01',
    }).eq('id', template.id);
  }

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

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
