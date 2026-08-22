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
    return (rows as List)
        .map((row) =>
            RecurringExpenseModel.fromJson(Map<String, dynamic>.from(row as Map)))
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

        final exists = await _chargeExists(template.id, cursor);
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

  Future<bool> _chargeExists(String templateId, DateTime month) async {
    final start = recurringMonthStart(month);
    final end = recurringNextMonth(start);
    final rows = await _client
        .from(_charges)
        .select('id')
        .eq('recurring_expense_id', templateId)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> _insertCharge({
    required RecurringExpenseModel template,
    required DateTime month,
  }) async {
    final day = template.dayOfMonth.clamp(1, 28);
    final chargeDate = DateTime(month.year, month.month, day);
    final expense = ExpenseModel(
      id: 0,
      createdAt: chargeDate,
      itemName: template.title,
      amount: template.amount,
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
