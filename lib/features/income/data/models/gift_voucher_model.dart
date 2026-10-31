/// A gift voucher / store credit tracked under Income.
class GiftVoucherModel {
  const GiftVoucherModel({
    required this.id,
    required this.title,
    this.storeName,
    required this.originalAmount,
    required this.remainingAmount,
    this.voucherLink,
    this.barcodeImageUrl,
    this.notes,
    required this.receivedAt,
    this.expiresAt,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? storeName;
  final double originalAmount;
  final double remainingAmount;
  final String? voucherLink;
  final String? barcodeImageUrl;
  final String? notes;
  final DateTime receivedAt;
  final DateTime? expiresAt;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDepleted => remainingAmount <= 0;

  bool get hasLink =>
      voucherLink != null && voucherLink!.trim().isNotEmpty;

  bool get hasBarcodeImage =>
      barcodeImageUrl != null && barcodeImageUrl!.trim().isNotEmpty;

  double get usedAmount =>
      (originalAmount - remainingAmount).clamp(0, originalAmount);

  double get remainingShare =>
      originalAmount <= 0 ? 0 : (remainingAmount / originalAmount).clamp(0.0, 1.0);

  factory GiftVoucherModel.fromJson(Map<String, dynamic> json) {
    return GiftVoucherModel(
      id: json['id'] as String,
      title: (json['title'] as String?)?.trim() ?? '',
      storeName: (json['store_name'] as String?)?.trim(),
      originalAmount: _parseAmount(json['original_amount']),
      remainingAmount: _parseAmount(json['remaining_amount']),
      voucherLink: (json['voucher_link'] as String?)?.trim(),
      barcodeImageUrl: (json['barcode_image_url'] as String?)?.trim(),
      notes: (json['notes'] as String?)?.trim(),
      receivedAt: _parseDate(json['received_at']) ?? DateTime.now(),
      expiresAt: _parseDate(json['expires_at']),
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'title': title,
      'store_name': _emptyToNull(storeName),
      'original_amount': originalAmount,
      'remaining_amount': remainingAmount,
      'voucher_link': _emptyToNull(voucherLink),
      'barcode_image_url': _emptyToNull(barcodeImageUrl),
      'notes': _emptyToNull(notes),
      'received_at': _dateOnly(receivedAt),
      'expires_at': expiresAt == null ? null : _dateOnly(expiresAt!),
      'is_archived': isArchived,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      ...toJsonForInsert(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  GiftVoucherModel copyWith({
    String? title,
    String? storeName,
    double? originalAmount,
    double? remainingAmount,
    String? voucherLink,
    String? barcodeImageUrl,
    String? notes,
    DateTime? receivedAt,
    DateTime? expiresAt,
    bool? isArchived,
    bool clearStoreName = false,
    bool clearVoucherLink = false,
    bool clearBarcodeImageUrl = false,
    bool clearNotes = false,
    bool clearExpiresAt = false,
  }) {
    return GiftVoucherModel(
      id: id,
      title: title ?? this.title,
      storeName: clearStoreName ? null : (storeName ?? this.storeName),
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      voucherLink:
          clearVoucherLink ? null : (voucherLink ?? this.voucherLink),
      barcodeImageUrl: clearBarcodeImageUrl
          ? null
          : (barcodeImageUrl ?? this.barcodeImageUrl),
      notes: clearNotes ? null : (notes ?? this.notes),
      receivedAt: receivedAt ?? this.receivedAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
