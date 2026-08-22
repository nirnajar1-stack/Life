import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/income_model.dart';

class IncomeRepository {
  IncomeRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'incomes';

  Future<List<IncomeModel>> fetchAll({int limit = 500}) async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) =>
            IncomeModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<IncomeModel> insert(IncomeModel income) async {
    final row = await _client
        .from(_table)
        .insert(income.toJsonForInsert())
        .select()
        .single();
    return IncomeModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> update(IncomeModel income) async {
    await _client.from(_table).update({
      'title': income.title,
      'amount': income.amount,
      'category': income.category,
      'sub_category': income.subCategory,
      'created_at': income.createdAt.toIso8601String(),
      'notes': income.notes,
    }).eq('id', income.id);
  }

  Future<void> delete(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
