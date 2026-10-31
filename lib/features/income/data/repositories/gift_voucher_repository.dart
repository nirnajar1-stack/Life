import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gift_voucher_model.dart';

class GiftVoucherRepository {
  GiftVoucherRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'gift_vouchers';
  static const _bucket = 'gift-vouchers';

  Future<List<GiftVoucherModel>> fetchAll({bool includeArchived = true}) async {
    final dynamic rows;
    if (includeArchived) {
      rows = await _client
          .from(_table)
          .select()
          .order('is_archived')
          .order('remaining_amount', ascending: false)
          .order('received_at', ascending: false);
    } else {
      rows = await _client
          .from(_table)
          .select()
          .eq('is_archived', false)
          .order('remaining_amount', ascending: false)
          .order('received_at', ascending: false);
    }
    return (rows as List)
        .map((row) =>
            GiftVoucherModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<GiftVoucherModel> insert(GiftVoucherModel voucher) async {
    final row = await _client
        .from(_table)
        .insert(voucher.toJsonForInsert())
        .select()
        .single();
    return GiftVoucherModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<GiftVoucherModel> update(GiftVoucherModel voucher) async {
    final row = await _client
        .from(_table)
        .update(voucher.toJsonForUpdate())
        .eq('id', voucher.id)
        .select()
        .single();
    return GiftVoucherModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<GiftVoucherModel> updateRemainingAmount({
    required String id,
    required double remainingAmount,
  }) async {
    final archived = remainingAmount <= 0;
    final row = await _client
        .from(_table)
        .update({
          'remaining_amount': remainingAmount,
          'is_archived': archived,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return GiftVoucherModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Uploads barcode / voucher image bytes and returns a public URL.
  Future<String> uploadBarcodeImage({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
