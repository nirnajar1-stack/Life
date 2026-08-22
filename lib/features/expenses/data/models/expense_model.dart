import '../../domain/models/expense_nature.dart';

/// Represents a single row from the flat `expenses_new` table in Supabase.
///
/// Note: PostgREST returns `numeric` columns as strings, so `amount` is
/// parsed defensively via [_parseAmount].
class ExpenseModel {
  final int id;
  final DateTime createdAt;
  final String itemName;
  final double amount;
  final String category;
  final String subCategory;
  final int? isFixed;
  final String? source;
  final String uuid;
  final String? messageId;
  final DateTime insertedAt;
  final int? sharedExp;
  final String? installmentGroupId;
  final int? installmentNumber;
  final int? installmentsTotal;
  final DateTime? purchaseDate;

  const ExpenseModel({
    required this.id,
    required this.createdAt,
    required this.itemName,
    required this.amount,
    required this.category,
    required this.subCategory,
    this.isFixed,
    this.source,
    required this.uuid,
    this.messageId,
    required this.insertedAt,
    this.sharedExp,
    this.installmentGroupId,
    this.installmentNumber,
    this.installmentsTotal,
    this.purchaseDate,
  });

  /// Category with surrounding whitespace removed (raw data is inconsistent).
  String get normalizedCategory => category.trim();

  bool get isInstallment =>
      installmentGroupId != null && installmentGroupId!.trim().isNotEmpty;

  String? get installmentLabel {
    if (!isInstallment ||
        installmentNumber == null ||
        installmentsTotal == null) {
      return null;
    }
    return 'תשלום $installmentNumber/$installmentsTotal';
  }

  /// Amount that counts toward monthly/category totals after shared split.
  double get actualAmount =>
      SharedExpenseFlag.actualAmount(amount, sharedExp);

  bool get isSharedExpense => SharedExpenseFlag.isShared(sharedExp);

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      itemName: (json['item_name'] as String?)?.trim() ?? '',
      amount: _parseAmount(json['amount']),
      category: (json['category'] as String?) ?? '',
      subCategory: (json['sub_category'] as String?) ?? '',
      isFixed: _parseInt(json['is_fixed']),
      source: json['source'] as String?,
      uuid: json['uuid'] as String,
      messageId: json['message_id'] as String?,
      insertedAt: DateTime.parse(json['inserted_at'] as String),
      sharedExp: _parseInt(json['Shared_exp']),
      installmentGroupId: json['installment_group_id'] as String?,
      installmentNumber: _parseInt(json['installment_number']),
      installmentsTotal: _parseInt(json['installments_total']),
      purchaseDate: _parseDate(json['purchase_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'item_name': itemName,
      'amount': amount,
      'category': category,
      'sub_category': subCategory,
      'is_fixed': isFixed,
      'source': source,
      'uuid': uuid,
      'message_id': messageId,
      'inserted_at': insertedAt.toIso8601String(),
      'Shared_exp': sharedExp,
      'installment_group_id': installmentGroupId,
      'installment_number': installmentNumber,
      'installments_total': installmentsTotal,
      'purchase_date': _dateOnly(purchaseDate),
    };
  }

  /// Payload for inserting a new row. Omits DB-generated columns
  /// (`id`, `uuid`, `inserted_at`) so Postgres defaults take effect.
  Map<String, dynamic> toJsonForInsert() {
    return {
      'created_at': createdAt.toIso8601String(),
      'item_name': itemName,
      'amount': amount,
      'category': category,
      'sub_category': subCategory,
      'is_fixed': isFixed ?? 0,
      'source': source ?? 'life_app',
      'message_id': messageId,
      'Shared_exp': sharedExp,
      'installment_group_id': installmentGroupId,
      'installment_number': installmentNumber,
      'installments_total': installmentsTotal,
      'purchase_date': _dateOnly(purchaseDate),
    };
  }

  /// Payload for updating an existing row. Only user-editable columns.
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'created_at': createdAt.toIso8601String(),
      'item_name': itemName,
      'amount': amount,
      'category': category,
      'sub_category': subCategory,
      'is_fixed': isFixed,
      'source': source,
      'message_id': messageId,
      'Shared_exp': sharedExp,
      'installment_group_id': installmentGroupId,
      'installment_number': installmentNumber,
      'installments_total': installmentsTotal,
      'purchase_date': _dateOnly(purchaseDate),
    };
  }

  ExpenseModel copyWith({
    int? id,
    DateTime? createdAt,
    String? itemName,
    double? amount,
    String? category,
    String? subCategory,
    int? isFixed,
    String? source,
    String? uuid,
    String? messageId,
    DateTime? insertedAt,
    int? sharedExp,
    String? installmentGroupId,
    int? installmentNumber,
    int? installmentsTotal,
    DateTime? purchaseDate,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      itemName: itemName ?? this.itemName,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      isFixed: isFixed ?? this.isFixed,
      source: source ?? this.source,
      uuid: uuid ?? this.uuid,
      messageId: messageId ?? this.messageId,
      insertedAt: insertedAt ?? this.insertedAt,
      sharedExp: sharedExp ?? this.sharedExp,
      installmentGroupId: installmentGroupId ?? this.installmentGroupId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      installmentsTotal: installmentsTotal ?? this.installmentsTotal,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
