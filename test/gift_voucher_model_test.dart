import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/income/data/models/gift_voucher_model.dart';

void main() {
  test('parses amounts and computes remaining share', () {
    final voucher = GiftVoucherModel.fromJson({
      'id': 'abc',
      'title': 'מתנה לחג',
      'store_name': 'סופר־פארם',
      'original_amount': '500',
      'remaining_amount': '350',
      'voucher_link': 'https://example.com/voucher',
      'barcode_image_url': null,
      'notes': null,
      'received_at': '2026-10-01',
      'expires_at': null,
      'is_archived': false,
      'created_at': '2026-10-01T10:00:00Z',
      'updated_at': '2026-10-01T10:00:00Z',
    });

    expect(voucher.title, 'מתנה לחג');
    expect(voucher.originalAmount, 500);
    expect(voucher.remainingAmount, 350);
    expect(voucher.usedAmount, 150);
    expect(voucher.remainingShare, closeTo(0.7, 0.0001));
    expect(voucher.hasLink, isTrue);
    expect(voucher.hasBarcodeImage, isFalse);
  });

  test('insert payload uses snake_case and date-only fields', () {
    final voucher = GiftVoucherModel(
      id: '',
      title: 'שובר',
      originalAmount: 200,
      remainingAmount: 200,
      receivedAt: DateTime(2026, 10, 31),
      expiresAt: DateTime(2027, 1, 15),
      isArchived: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final json = voucher.toJsonForInsert();
    expect(json['original_amount'], 200);
    expect(json['remaining_amount'], 200);
    expect(json['received_at'], '2026-10-31');
    expect(json['expires_at'], '2027-01-15');
  });
}
