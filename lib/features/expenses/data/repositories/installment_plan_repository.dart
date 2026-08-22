import 'dart:developer' as developer;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/installment_plan_model.dart';

class InstallmentPlanRepository {
  InstallmentPlanRepository(this._client);

  final SupabaseClient _client;

  static const _plans = 'installment_plans';
  static const _charges = 'expenses_new';

  Future<List<InstallmentPlanModel>> fetchAll({DateTime? asOf}) async {
    final rows = await _client
        .from(_plans)
        .select()
        .order('created_at', ascending: false);

    final plans = (rows as List)
        .map((row) =>
            InstallmentPlanModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .map((plan) => _withProgress(plan, asOf: asOf))
        .toList();

    final legacy = await _fetchLegacyPlansWithoutHeader(asOf: asOf);
    final knownIds = plans.map((plan) => plan.id).toSet();
    legacy.removeWhere((plan) => knownIds.contains(plan.id));

    return [...plans, ...legacy];
  }

  Future<InstallmentPlanModel> createPlan({
    required String title,
    required double totalAmount,
    required int installmentsCount,
    required DateTime firstChargeDate,
    required String category,
    required String subCategory,
    InstallmentPlanType planType = InstallmentPlanType.purchase,
    int sharedExp = 0,
  }) async {
    if (installmentsCount < 2) {
      throw ArgumentError('installmentsCount must be >= 2');
    }
    if (installmentsCount > 360) {
      throw ArgumentError('installmentsCount must be <= 360');
    }
    if (totalAmount <= 0) {
      throw ArgumentError('totalAmount must be > 0');
    }

    final groupId = _newUuidV4();
    final purchaseDate = DateTime(
      firstChargeDate.year,
      firstChargeDate.month,
      firstChargeDate.day,
    );
    final header = InstallmentPlanModel(
      id: groupId,
      title: title,
      totalAmount: totalAmount,
      installmentsTotal: installmentsCount,
      planType: planType,
      category: category,
      subCategory: subCategory,
      sharedExp: sharedExp,
      firstChargeDate: purchaseDate,
      purchaseDate: purchaseDate,
      createdAt: DateTime.now(),
    );

    try {
      await _client.from(_plans).insert(header.toJsonForInsert());
      await _insertCharges(
        groupId: groupId,
        title: title,
        totalAmount: totalAmount,
        installmentsCount: installmentsCount,
        firstChargeDate: firstChargeDate,
        category: category,
        subCategory: subCategory,
        sharedExp: sharedExp,
        source: planType == InstallmentPlanType.loan
            ? 'life_app_loan'
            : 'life_app_installment',
      );
      return _withProgress(header);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to create installment plan',
        name: 'InstallmentPlanRepository.createPlan',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateActive(String id, {required bool isActive}) async {
    await _client.from(_plans).update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deletePlan(String id) async {
    await _client.from(_charges).delete().eq('installment_group_id', id);
    await _client.from(_plans).delete().eq('id', id);
  }

  InstallmentPlanModel _withProgress(
    InstallmentPlanModel plan, {
    DateTime? asOf,
  }) {
    final paid = countPaidInstallments(
      installmentsTotal: plan.installmentsTotal,
      firstChargeDate: plan.firstChargeDate,
      asOf: asOf,
    );
    final amounts = splitInstallmentAmounts(
      totalAmount: plan.totalAmount,
      installmentsCount: plan.installmentsTotal,
    );
    final monthlyAmount = amounts.isEmpty ? 0.0 : amounts.first;
    final remainingAmount = paid >= amounts.length
        ? 0.0
        : amounts.sublist(paid).fold<double>(0, (sum, value) => sum + value);
    final nextChargeDate = paid >= plan.installmentsTotal
        ? null
        : installmentChargeDate(plan.firstChargeDate, paid + 1);

    return plan.withProgress(
      paidInstallments: paid,
      monthlyAmount: monthlyAmount,
      remainingAmount: remainingAmount,
      nextChargeDate: nextChargeDate,
    );
  }

  Future<List<InstallmentPlanModel>> _fetchLegacyPlansWithoutHeader({
    DateTime? asOf,
  }) async {
    final rows = await _client
        .from(_charges)
        .select(
          'installment_group_id, item_name, amount, category, sub_category, '
          'installments_total, installment_number, created_at, purchase_date, '
          'Shared_exp',
        )
        .not('installment_group_id', 'is', null)
        .order('installment_number');

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final groupId = map['installment_group_id'] as String?;
      if (groupId == null || groupId.isEmpty) continue;
      grouped.putIfAbsent(groupId, () => []).add(map);
    }

    if (grouped.isEmpty) return [];

    final existing = await _client.from(_plans).select('id');
    final existingIds = (existing as List)
        .map((row) => (row as Map)['id'] as String)
        .toSet();

    final legacyPlans = <InstallmentPlanModel>[];
    for (final entry in grouped.entries) {
      if (existingIds.contains(entry.key)) continue;
      final charges = entry.value;
      charges.sort(
        (a, b) => ((a['installment_number'] as num?)?.toInt() ?? 0)
            .compareTo((b['installment_number'] as num?)?.toInt() ?? 0),
      );
      final first = charges.first;
      final totalAmount = charges.fold<double>(
        0,
        (sum, row) => sum + _parseAmount(row['amount']),
      );
      final installmentsTotal =
          (first['installments_total'] as num?)?.toInt() ?? charges.length;
      final firstChargeDate =
          DateTime.parse(first['created_at'] as String).toLocal();
      final purchaseRaw = first['purchase_date'];
      final purchaseDate = purchaseRaw == null
          ? DateTime(
              firstChargeDate.year,
              firstChargeDate.month,
              firstChargeDate.day,
            )
          : DateTime.parse(purchaseRaw as String);

      final plan = InstallmentPlanModel(
        id: entry.key,
        title: first['item_name'] as String? ?? 'תוכנית תשלומים',
        totalAmount: totalAmount,
        installmentsTotal: installmentsTotal,
        planType: InstallmentPlanType.purchase,
        category: first['category'] as String? ?? 'אחר',
        subCategory: (first['sub_category'] as String?)?.trim() ?? 'כללי',
        sharedExp: (first['Shared_exp'] as num?)?.toInt() ?? 0,
        firstChargeDate: DateTime(
          firstChargeDate.year,
          firstChargeDate.month,
          firstChargeDate.day,
        ),
        purchaseDate: purchaseDate,
        createdAt: firstChargeDate,
      );
      legacyPlans.add(_withProgress(plan, asOf: asOf));
    }

    legacyPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return legacyPlans;
  }

  Future<void> _insertCharges({
    required String groupId,
    required String title,
    required double totalAmount,
    required int installmentsCount,
    required DateTime firstChargeDate,
    required String category,
    required String subCategory,
    required int sharedExp,
    required String source,
  }) async {
    final purchaseDate = DateTime(
      firstChargeDate.year,
      firstChargeDate.month,
      firstChargeDate.day,
    );
    final amounts = splitInstallmentAmounts(
      totalAmount: totalAmount,
      installmentsCount: installmentsCount,
    );

    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i <= installmentsCount; i++) {
      final chargeDate = installmentChargeDate(firstChargeDate, i);
      rows.add({
        'created_at': chargeDate.toIso8601String(),
        'item_name': title,
        'amount': amounts[i - 1],
        'category': category,
        'sub_category': subCategory,
        'is_fixed': 0,
        'source': source,
        'Shared_exp': sharedExp,
        'installment_group_id': groupId,
        'installment_number': i,
        'installments_total': installmentsCount,
        'purchase_date':
            '${purchaseDate.year.toString().padLeft(4, '0')}-'
            '${purchaseDate.month.toString().padLeft(2, '0')}-'
            '${purchaseDate.day.toString().padLeft(2, '0')}',
      });
    }

    await _client.from(_charges).insert(rows);
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
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
}
