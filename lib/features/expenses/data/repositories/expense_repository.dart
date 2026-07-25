import 'dart:developer' as developer;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/expense_summary.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  ExpenseRepository(this._client);

  final SupabaseClient _client;

  static const String _tableName = 'expenses_new';
  static const String _summaryRpc = 'life_app_get_expenses_summary';

  /// Latest expenses, newest first.
  Future<List<ExpenseModel>> getRecentExpenses({int limit = 30}) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return rows.map(ExpenseModel.fromJson).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch recent expenses',
        name: 'ExpenseRepository.getRecentExpenses',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Full ledger dataset for the monthly view (newest first).
  ///
  /// Raises PostgREST's default 1000-row cap so the monthly grouping
  /// covers the whole personal history (~1.3k rows today).
  Future<List<ExpenseModel>> getExpensesForLedger({int limit = 3000}) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return rows.map(ExpenseModel.fromJson).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch expenses ledger',
        name: 'ExpenseRepository.getExpensesForLedger',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Inserts a new expense. DB-generated columns are omitted.
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _client.from(_tableName).insert(expense.toJsonForInsert());
    } catch (error, stackTrace) {
      developer.log(
        'Failed to add expense',
        name: 'ExpenseRepository.addExpense',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates the editable fields of an existing expense (matched by id).
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _client
          .from(_tableName)
          .update(expense.toJsonForUpdate())
          .eq('id', expense.id);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to update expense',
        name: 'ExpenseRepository.updateExpense',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sets `Shared_exp` for every line item under the same [messageId].
  ///
  /// Supermarket receipts share one message_id — shared/personal is a
  /// property of the purchase, not of a single product line.
  Future<void> updateSharedFlagForMessage({
    required String messageId,
    required int sharedExp,
  }) async {
    final mid = messageId.trim();
    if (mid.isEmpty) {
      throw ArgumentError('messageId must not be empty');
    }

    try {
      await _client
          .from(_tableName)
          .update({'Shared_exp': sharedExp}).eq('message_id', mid);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to update shared flag for message',
        name: 'ExpenseRepository.updateSharedFlagForMessage',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes an expense by its id.
  Future<void> deleteExpense(int id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to delete expense',
        name: 'ExpenseRepository.deleteExpense',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Creates N charge rows for an installment purchase (cash-basis).
  ///
  /// Each row falls on [firstChargeDate] + (i-1) months. Amounts are split
  /// evenly; leftover cents go to the last charge.
  Future<void> createInstallmentPlan({
    required String itemName,
    required double totalAmount,
    required int installmentsCount,
    required DateTime firstChargeDate,
    required String category,
    required String subCategory,
    required bool isShared,
    String source = 'life_app',
  }) async {
    if (installmentsCount < 2) {
      throw ArgumentError('installmentsCount must be >= 2');
    }
    if (totalAmount <= 0) {
      throw ArgumentError('totalAmount must be > 0');
    }

    try {
      final groupId = _newUuidV4();
      final purchaseDate = DateTime(
        firstChargeDate.year,
        firstChargeDate.month,
        firstChargeDate.day,
      );

      final baseCents = (totalAmount * 100).round();
      final perCents = baseCents ~/ installmentsCount;
      var remainder = baseCents - (perCents * installmentsCount);

      final rows = <Map<String, dynamic>>[];
      for (var i = 1; i <= installmentsCount; i++) {
        final cents = perCents + (i == installmentsCount ? remainder : 0);
        final chargeDate = DateTime(
          firstChargeDate.year,
          firstChargeDate.month + (i - 1),
          firstChargeDate.day,
        );
        rows.add({
          'created_at': chargeDate.toIso8601String(),
          'item_name': itemName,
          'amount': cents / 100.0,
          'category': category,
          'sub_category': subCategory,
          'is_fixed': 0,
          'source': source,
          'Shared_exp': isShared ? 1 : 0,
          'installment_group_id': groupId,
          'installment_number': i,
          'installments_total': installmentsCount,
          'purchase_date':
              '${purchaseDate.year.toString().padLeft(4, '0')}-'
              '${purchaseDate.month.toString().padLeft(2, '0')}-'
              '${purchaseDate.day.toString().padLeft(2, '0')}',
        });
      }

      await _client.from(_tableName).insert(rows);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to create installment plan',
        name: 'ExpenseRepository.createInstallmentPlan',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static String _newUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
        '${hex(4)}${hex(5)}-'
        '${hex(6)}${hex(7)}-'
        '${hex(8)}${hex(9)}-'
        '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
  }

  /// Aggregated overview (grand total + per-category breakdown) computed
  /// server-side via an RPC so it is not capped by row limits.
  Future<ExpenseSummary> getSummary() async {
    try {
      final dynamic result = await _client.rpc(_summaryRpc);
      final Map<String, dynamic> json = Map<String, dynamic>.from(result as Map);

      final List<dynamic> rawCategories =
          (json['categories'] as List<dynamic>?) ?? const [];

      final categories = rawCategories
          .map((item) => _categoryFromJson(item as Map<String, dynamic>))
          .toList();

      return ExpenseSummary(
        grandTotal: _toDouble(json['grand_total']),
        totalCount: _toInt(json['total_count']),
        categories: categories,
        firstDate: _toDate(json['first_date']),
        lastDate: _toDate(json['last_date']),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch expenses summary',
        name: 'ExpenseRepository.getSummary',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  CategoryTotal _categoryFromJson(Map<String, dynamic> json) {
    return CategoryTotal(
      category: (json['category'] as String?)?.trim() ?? 'ללא קטגוריה',
      total: _toDouble(json['total']),
      count: _toInt(json['count']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
