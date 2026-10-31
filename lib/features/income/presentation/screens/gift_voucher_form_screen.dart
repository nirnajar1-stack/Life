import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../data/models/gift_voucher_model.dart';
import '../../domain/providers/income_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

class GiftVoucherFormScreen extends ConsumerStatefulWidget {
  const GiftVoucherFormScreen({super.key, this.voucher});

  final GiftVoucherModel? voucher;

  bool get isEditing => voucher != null;

  @override
  ConsumerState<GiftVoucherFormScreen> createState() =>
      _GiftVoucherFormScreenState();
}

class _GiftVoucherFormScreenState extends ConsumerState<GiftVoucherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _storeName;
  late final TextEditingController _originalAmount;
  late final TextEditingController _remainingAmount;
  late final TextEditingController _voucherLink;
  late final TextEditingController _barcodeImageUrl;
  late final TextEditingController _notes;
  late DateTime _receivedAt;
  DateTime? _expiresAt;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    _title = TextEditingController(text: v?.title ?? '');
    _storeName = TextEditingController(text: v?.storeName ?? '');
    _originalAmount = TextEditingController(
      text: v == null ? '' : _amountText(v.originalAmount),
    );
    _remainingAmount = TextEditingController(
      text: v == null ? '' : _amountText(v.remainingAmount),
    );
    _voucherLink = TextEditingController(text: v?.voucherLink ?? '');
    _barcodeImageUrl = TextEditingController(text: v?.barcodeImageUrl ?? '');
    _notes = TextEditingController(text: v?.notes ?? '');
    _receivedAt = v?.receivedAt ?? DateTime.now();
    _expiresAt = v?.expiresAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _storeName.dispose();
    _originalAmount.dispose();
    _remainingAmount.dispose();
    _voucherLink.dispose();
    _barcodeImageUrl.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _amountText(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  Future<void> _pickReceivedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'תאריך קבלה',
    );
    if (picked != null) setState(() => _receivedAt = picked);
  }

  Future<void> _pickExpiresAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'תוקף (אופציונלי)',
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _pickBarcodeImage() async {
    setState(() => _uploadingImage = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) {
        if (mounted) setState(() => _uploadingImage = false);
        return;
      }

      final bytes = await file.readAsBytes();
      final name = file.name.isEmpty ? 'barcode.jpg' : file.name;
      final mime = file.mimeType ??
          (name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');

      final url = await ref.read(giftVoucherRepositoryProvider).uploadBarcodeImage(
            bytes: bytes,
            fileName: name,
            contentType: mime,
          );
      if (!mounted) return;
      setState(() {
        _barcodeImageUrl.text = url;
        _uploadingImage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('העלאת תמונה נכשלה: $error')),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final original = double.parse(_originalAmount.text.trim().replaceAll(',', '.'));
    final remaining =
        double.parse(_remainingAmount.text.trim().replaceAll(',', '.'));
    final repo = ref.read(giftVoucherRepositoryProvider);

    try {
      if (widget.isEditing) {
        await repo.update(
          widget.voucher!.copyWith(
            title: _title.text.trim(),
            storeName: _storeName.text.trim(),
            clearStoreName: _storeName.text.trim().isEmpty,
            originalAmount: original,
            remainingAmount: remaining,
            voucherLink: _voucherLink.text.trim(),
            clearVoucherLink: _voucherLink.text.trim().isEmpty,
            barcodeImageUrl: _barcodeImageUrl.text.trim(),
            clearBarcodeImageUrl: _barcodeImageUrl.text.trim().isEmpty,
            notes: _notes.text.trim(),
            clearNotes: _notes.text.trim().isEmpty,
            receivedAt: _receivedAt,
            expiresAt: _expiresAt,
            clearExpiresAt: _expiresAt == null,
            isArchived: remaining <= 0 ? true : widget.voucher!.isArchived,
          ),
        );
      } else {
        await repo.insert(
          GiftVoucherModel(
            id: '',
            title: _title.text.trim(),
            storeName: _storeName.text.trim().isEmpty
                ? null
                : _storeName.text.trim(),
            originalAmount: original,
            remainingAmount: remaining,
            voucherLink: _voucherLink.text.trim().isEmpty
                ? null
                : _voucherLink.text.trim(),
            barcodeImageUrl: _barcodeImageUrl.text.trim().isEmpty
                ? null
                : _barcodeImageUrl.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            receivedAt: _receivedAt,
            expiresAt: _expiresAt,
            isArchived: remaining <= 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      ref.invalidate(giftVouchersProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שמירה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inDialog = isFormDialog(context);
    final previewUrl = _barcodeImageUrl.text.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: inDialog ? Colors.white : AppColors.surface,
        appBar: AppBar(
          backgroundColor: inDialog ? Colors.white : null,
          title: Text(widget.isEditing ? 'עריכת שובר' : 'שובר חדש'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    autofocus: !widget.isEditing,
                    decoration: const InputDecoration(
                      labelText: 'שם / תיאור',
                      hintText: 'מתנה לחג, שובר סופר־פארם…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'נא להזין שם' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _storeName,
                    decoration: const InputDecoration(
                      labelText: 'חנות / מנפיק (אופציונלי)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _originalAmount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'סכום מקורי',
                            suffixText: '₪',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            if (widget.isEditing) return;
                            if (_remainingAmount.text.trim().isEmpty ||
                                _remainingAmount.text ==
                                    _originalAmount.text) {
                              _remainingAmount.text = value;
                            }
                          },
                          validator: (v) {
                            final parsed =
                                double.tryParse((v ?? '').replaceAll(',', '.'));
                            if (parsed == null || parsed <= 0) {
                              return 'סכום לא תקין';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _remainingAmount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'יתרה',
                            suffixText: '₪',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final remaining = double.tryParse(
                              (v ?? '').replaceAll(',', '.'),
                            );
                            final original = double.tryParse(
                              _originalAmount.text.replaceAll(',', '.'),
                            );
                            if (remaining == null || remaining < 0) {
                              return 'יתרה לא תקינה';
                            }
                            if (original != null && remaining > original) {
                              return 'גבוה מהמקורי';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickReceivedAt,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'תאריך קבלה',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_dateFormat.format(_receivedAt)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickExpiresAt,
                    onLongPress: () => setState(() => _expiresAt = null),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'תוקף (אופציונלי)',
                        border: const OutlineInputBorder(),
                        suffixIcon: _expiresAt == null
                            ? null
                            : IconButton(
                                tooltip: 'נקה תוקף',
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _expiresAt = null),
                              ),
                      ),
                      child: Text(
                        _expiresAt == null
                            ? 'ללא תוקף'
                            : _dateFormat.format(_expiresAt!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _voucherLink,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'לינק לשובר (אופציונלי)',
                      hintText: 'https://…',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _barcodeImageUrl,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'קישור לתמונת ברקוד (אופציונלי)',
                      hintText: 'העלה תמונה או הדבק קישור',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _uploadingImage ? null : _pickBarcodeImage,
                    icon: _uploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _uploadingImage ? 'מעלה…' : 'העלה תמונת ברקוד מהגלריה',
                    ),
                  ),
                  if (previewUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          previewUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Text('לא ניתן להציג את התמונה'),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'הערות (אופציונלי)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.income,
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(widget.isEditing ? 'שמור' : 'הוסף שובר'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
