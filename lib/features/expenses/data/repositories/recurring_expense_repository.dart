import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense_model.dart';
import '../models/recurring_expense_model.dart';

class RecurringExpenseRepository {
  RecurringExpenseRepository(this._client);

  final SupabaseClient _client;

  static const _templates = 'recurring_expenses';
  static const _charges = 'expenses_new';

  Future<List<RecurringExpenseModel>> fetchAll() async {
    final rows = await _client
        .from(_templates)
        .select()
        .order('created_at', ascending: false);
    final templates = (rows as List)
        .map((row) =>
            RecurringExpenseModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();

    final chargedThisMonth = await _chargedTitlesThisMonth();
    return templates
        .map(
          (template) => template.copyWith(
            chargedThisMonth: _titleChargedThisMonth(
              template.title,
              chargedThisMonth,
            ),
          ),
        )
        .toList();
  }

  Future<RecurringExpenseModel> insert(RecurringExpenseModel template) async {
    final row = await _client
        .from(_templates)
        .insert(template.toJsonForInsert())
        .select()
        .single();
    return RecurringExpenseModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> update(RecurringExpenseModel template) async {
    await _client
        .from(_templates)
        .update(template.toJsonForUpdate())
        .eq('id', template.id);
  }

  Future<void> delete(String id) async {
    await _client.from(_templates).delete().eq('id', id);
  }

  /// Creates missing monthly charges in [expenses_new] through [through].
  Future<int> generateDueCharges({DateTime? through}) async {
    final horizon = recurringMonthStart(through ?? DateTime.now());
    final templates =
        (await fetchAll()).where((template) => template.isActive).toList();
    var created = 0;

    for (final template in templates) {
      if (template.amountVariable) continue;

      var cursor = template.lastGeneratedMonth == null
          ? recurringMonthStart(template.startDate)
          : recurringNextMonth(recurringMonthStart(template.lastGeneratedMonth!));

      if (cursor.isBefore(recurringMonthStart(template.startDate))) {
        cursor = recurringMonthStart(template.startDate);
      }

      while (!cursor.isAfter(horizon)) {
        if (template.endDate != null &&
            cursor.isAfter(recurringMonthStart(template.endDate!))) {
          break;
        }

        final exists = await _chargeExistsForTemplate(template, cursor);
        if (!exists) {
          await _insertCharge(template: template, month: cursor);
          created += 1;
        }

        await _client.from(_templates).update({
          'last_generated_month':
              '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-01',
        }).eq('id', template.id);

        cursor = recurringNextMonth(cursor);
      }
    }

    if (created > 0) {
      developer.log(
        'Generated $created recurring expense charge(s)',
        name: 'RecurringExpenseRepository.generateDueCharges',
      );
    }
    return created;
  }

  /// Calendar months (month-start) that already have a charge for [template].
  Future<List<DateTime>> fetchChargedMonths(RecurringExpenseModel template) async {
    final months = <DateTime>{};

    final byId = await _client
        .from(_charges)
        .select('created_at')
        .eq('recurring_expense_id', template.id);
    for (final row in byId as List) {
      final raw = (row as Map)['created_at'];
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed == null) continue;
      final utc = parsed.toUtc();
      months.add(DateTime(utc.year, utc.month));
    }

    // Legacy rows may lack recurring_expense_id — match by similar title.
    final byTitle = await _client
        .from(_charges)
        .select('item_name, created_at')
        .eq('source', 'life_app_recurring');
    final normalized = _normalizeTitle(template.title);
    for (final row in byTitle as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final name = _normalizeTitle(map['item_name'] as String?);
      if (!_titlesMatch(normalized, name)) continue;
      final parsed = DateTime.tryParse('${map['created_at']}');
      if (parsed == null) continue;
      final utc = parsed.toUtc();
      months.add(DateTime(utc.year, utc.month));
    }

    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  /// Records a one-off monthly charge for variable-amount templates.
  ///
  /// [month] may be any past/current calendar month (e.g. September while
  /// today is October) as long as no charge exists for that month yet.
  Future<void> recordVariableCharge({
    required RecurringExpenseModel template,
    required double amount,
    DateTime? month,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('amount must be > 0');
    }

    final targetMonth = recurringMonthStart(month ?? DateTime.now());
    final currentMonth = recurringMonthStart(DateTime.now());
    if (targetMonth.isAfter(currentMonth)) {
      throw StateError('לא ניתן לרשום חיוב לחודש עתידי');
    }
    final startBound = recurringMonthStart(template.startDate);
    if (targetMonth.isBefore(startBound)) {
      throw StateError('החודש לפני תחילת ההוצאה הקבועה');
    }
    if (template.endDate != null &&
        targetMonth.isAfter(recurringMonthStart(template.endDate!))) {
      throw StateError('החודש אחרי סיום ההוצאה הקבועה');
    }
    if (await _chargeExistsForTemplate(template, targetMonth)) {
      throw StateError('כבר נרשם חיוב לחודש זה');
    }

    final day = template.dayOfMonth.clamp(1, 28);
    // Noon UTC keeps the calendar day stable across all timezones.
    final chargeDate = DateTime.utc(
      targetMonth.year,
      targetMonth.month,
      day,
      12,
    );
    final expense = ExpenseModel(
      id: 0,
      createdAt: chargeDate,
      itemName: template.title,
      amount: amount,
      category: template.category,
      subCategory: template.subCategory,
      isFixed: 1,
      source: 'life_app_recurring',
      uuid: '',
      insertedAt: DateTime.now(),
      sharedExp: template.sharedExp,
    );

    await _client.from(_charges).insert({
      ...expense.toJsonForInsert(),
      'recurring_expense_id': template.id,
    });

    final last = template.lastGeneratedMonth == null
        ? targetMonth
        : (targetMonth.isAfter(recurringMonthStart(template.lastGeneratedMonth!))
            ? targetMonth
            : recurringMonthStart(template.lastGeneratedMonth!));

    await _client.from(_templates).update({
      'amount': amount,
      'last_generated_month':
          '${last.year.toString().padLeft(4, '0')}-'
          '${last.month.toString().padLeft(2, '0')}-01',
    }).eq('id', template.id);
  }

  /// UTC month window so date-only charges at midnight UTC are included
  /// regardless of the device timezone.
  (DateTime, DateTime) _utcMonthWindow(DateTime month) {
    final start = recurringMonthStart(month);
    return (
      DateTime.utc(start.year, start.month, 1),
      DateTime.utc(start.year, start.month + 1, 1),
    );
  }

  Future<Set<String>> _chargedTitlesThisMonth() async {
    final (start, end) = _utcMonthWindow(DateTime.now());
    final rows = await _client
        .from(_charges)
        .select('item_name')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());
    return (rows as List)
        .map((row) => _normalizeTitle((row as Map)['item_name'] as String?))
        .where((title) => title.isNotEmpty)
        .toSet();
  }

  bool _titleChargedThisMonth(String title, Set<String> chargedTitles) {
    final normalized = _normalizeTitle(title);
    if (normalized.isEmpty) return false;
    for (final charged in chargedTitles) {
      if (_titlesMatch(normalized, charged)) return true;
    }
    return false;
  }

  Future<bool> _chargeExistsForTemplate(
    RecurringExpenseModel template,
    DateTime month,
  ) async {
    if (await _chargeExistsByRecurringId(template.id, month)) return true;
    return _chargeExistsBySimilarTitle(template.title, month);
  }

  Future<bool> _chargeExistsByRecurringId(String templateId, DateTime month) async {
    final (start, end) = _utcMonthWindow(month);
    final rows = await _client
        .from(_charges)
        .select('id')
        .eq('recurring_expense_id', templateId)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<bool> _chargeExistsBySimilarTitle(String title, DateTime month) async {
    final normalized = _normalizeTitle(title);
    if (normalized.isEmpty) return false;

    final (start, end) = _utcMonthWindow(month);
    final rows = await _client
        .from(_charges)
        .select('item_name')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    for (final row in rows as List) {
      final name = _normalizeTitle((row as Map)['item_name'] as String?);
      if (_titlesMatch(normalized, name)) return true;
    }
    return false;
  }

  static String _normalizeTitle(String? value) =>
      (value ?? '').trim().toLowerCase();

  static bool _titlesMatch(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.startsWith(b) || b.startsWith(a);
  }

  Future<void> _insertCharge({
    required RecurringExpenseModel template,
    required DateTime month,
  }) async {
    final day = template.dayOfMonth.clamp(1, 28);
    // Noon UTC keeps the calendar day stable across all timezones.
    final chargeDate = DateTime.utc(month.year, month.month, day, 12);
    final expense = ExpenseModel(
      id: 0,
      createdAt: chargeDate,
      itemName: template.title,
      amount: template.amount ?? 0,
      category: template.category,
      subCategory: template.subCategory,
      isFixed: 1,
      source: 'life_app_recurring',
      uuid: '',
      insertedAt: DateTime.now(),
      sharedExp: template.sharedExp,
    );

    final payload = {
      ...expense.toJsonForInsert(),
      'recurring_expense_id': template.id,
    };
    await _client.from(_charges).insert(payload);
  }
}
