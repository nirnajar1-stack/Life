import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/monthly_budget_model.dart';

class MonthlyBudgetRepository {
  MonthlyBudgetRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'monthly_budgets';

  Future<List<MonthlyBudgetModel>> getBudgetsForMonth({
    required int year,
    required int month,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(_table)
          .select()
          .eq('year', year)
          .eq('month', month)
          .order('category');

      return rows.map(MonthlyBudgetModel.fromJson).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch monthly budgets',
        name: 'MonthlyBudgetRepository.getBudgetsForMonth',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<MonthlyBudgetModel> upsertBudget({
    required int year,
    required int month,
    required String category,
    required double budgetAmount,
  }) async {
    try {
      final row = await _client
          .from(_table)
          .upsert(
            {
              'year': year,
              'month': month,
              'category': category.trim(),
              'budget_amount': budgetAmount,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'year,month,category',
          )
          .select()
          .single();
      return MonthlyBudgetModel.fromJson(row);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to upsert monthly budget',
        name: 'MonthlyBudgetRepository.upsertBudget',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to delete monthly budget',
        name: 'MonthlyBudgetRepository.deleteBudget',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Copies budgets from [source] into [target].
  ///
  /// Existing target categories are skipped unless [overwriteExisting] is true.
  Future<({int copied, int skipped})> copyBudgets({
    required int sourceYear,
    required int sourceMonth,
    required int targetYear,
    required int targetMonth,
    bool overwriteExisting = false,
  }) async {
    final source = await getBudgetsForMonth(
      year: sourceYear,
      month: sourceMonth,
    );
    final target = await getBudgetsForMonth(
      year: targetYear,
      month: targetMonth,
    );
    final existing = {for (final b in target) b.category};

    var copied = 0;
    var skipped = 0;

    for (final row in source) {
      if (existing.contains(row.category) && !overwriteExisting) {
        skipped++;
        continue;
      }
      await upsertBudget(
        year: targetYear,
        month: targetMonth,
        category: row.category,
        budgetAmount: row.budgetAmount,
      );
      copied++;
    }

    return (copied: copied, skipped: skipped);
  }
}
