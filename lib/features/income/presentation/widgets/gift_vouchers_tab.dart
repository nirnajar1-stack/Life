import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/gift_voucher_model.dart';
import '../../domain/providers/income_providers.dart';
import '../screens/gift_voucher_form_screen.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);
final _dateFormat = DateFormat('dd/MM/yyyy', 'he');

class GiftVouchersTab extends ConsumerWidget {
  const GiftVouchersTab({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    GiftVoucherModel? voucher,
  }) async {
    await showAdaptiveForm(
      context: context,
      form: GiftVoucherFormScreen(voucher: voucher),
    );
    ref.invalidate(giftVouchersProvider);
  }

  Future<void> _editRemaining(
    BuildContext context,
    WidgetRef ref,
    GiftVoucherModel voucher,
  ) async {
    final controller = TextEditingController(
      text: voucher.remainingAmount == voucher.remainingAmount.roundToDouble()
          ? voucher.remainingAmount.toInt().toString()
          : voucher.remainingAmount.toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('עדכון יתרה'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                voucher.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'מקורי: ${_currency.format(voucher.originalAmount)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'יתרה נוכחית',
                  suffixText: '₪',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );
                if (parsed == null ||
                    parsed < 0 ||
                    parsed > voucher.originalAmount) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'הזן יתרה בין 0 ל-${_currency.format(voucher.originalAmount)}',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, parsed);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.income),
              child: const Text('עדכן'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null) return;

    try {
      await ref.read(giftVoucherRepositoryProvider).updateRemainingAmount(
            id: voucher.id,
            remainingAmount: result,
          );
      ref.invalidate(giftVouchersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result <= 0
                ? 'השובר סומן כמנוצל'
                : 'יתרה עודכנה ל-${_currency.format(result)}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('עדכון נכשל: $error')),
      );
    }
  }

  Future<void> _openLink(BuildContext context, String link) async {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('קישור לא תקין')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('לא ניתן לפתוח את הקישור')),
      );
    }
  }

  Future<void> _showBarcode(
    BuildContext context,
    GiftVoucherModel voucher,
  ) async {
    final url = voucher.barcodeImageUrl?.trim();
    if (url == null || url.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(voucher.title),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('לא ניתן להציג את תמונת הברקוד'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    GiftVoucherModel voucher,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת שובר'),
          content: Text('למחוק את "${voucher.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(giftVoucherRepositoryProvider).delete(voucher.id);
      ref.invalidate(giftVouchersProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  Future<void> _toggleArchive(
    BuildContext context,
    WidgetRef ref,
    GiftVoucherModel voucher,
  ) async {
    try {
      await ref.read(giftVoucherRepositoryProvider).update(
            voucher.copyWith(isArchived: !voucher.isArchived),
          );
      ref.invalidate(giftVouchersProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('עדכון נכשל: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(giftVouchersProvider);
    final balance = ref.watch(activeGiftVoucherBalanceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(giftVouchersProvider);
        await onRefresh?.call();
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            AppErrorState(
              title: 'שגיאה בטעינת השוברים',
              error: e,
              onRetry: () => ref.invalidate(giftVouchersProvider),
            ),
          ],
        ),
        data: (vouchers) {
          final active = vouchers.where((v) => !v.isArchived).toList();
          final archived = vouchers.where((v) => v.isArchived).toList();

          return ListView(
            padding: AppLayout.listPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Card(
                color: AppColors.income.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'יתרת שוברים פעילים',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currency.format(balance.valueOrNull ?? 0),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.income,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${active.length} פעילים'
                        '${archived.isEmpty ? '' : ' · ${archived.length} בארכיון'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (vouchers.isEmpty)
                AppEmptyState(
                  icon: Icons.card_giftcard_outlined,
                  title: 'אין שוברים עדיין',
                  message:
                      'שמור כאן שובר מתנה שקיבלת — יתרה, לינק, ותמונת ברקוד.',
                  actionLabel: 'שובר חדש',
                  onAction: () => _openForm(context, ref),
                )
              else ...[
                for (final voucher in active)
                  _VoucherCard(
                    voucher: voucher,
                    onTap: () => _openForm(context, ref, voucher: voucher),
                    onEditRemaining: () =>
                        _editRemaining(context, ref, voucher),
                    onOpenLink: voucher.hasLink
                        ? () => _openLink(context, voucher.voucherLink!)
                        : null,
                    onShowBarcode: voucher.hasBarcodeImage
                        ? () => _showBarcode(context, voucher)
                        : null,
                    onArchive: () => _toggleArchive(context, ref, voucher),
                    onDelete: () => _delete(context, ref, voucher),
                  ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                    child: Text(
                      'ארכיון',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  for (final voucher in archived)
                    _VoucherCard(
                      voucher: voucher,
                      faded: true,
                      onTap: () => _openForm(context, ref, voucher: voucher),
                      onEditRemaining: () =>
                          _editRemaining(context, ref, voucher),
                      onOpenLink: voucher.hasLink
                          ? () => _openLink(context, voucher.voucherLink!)
                          : null,
                      onShowBarcode: voucher.hasBarcodeImage
                          ? () => _showBarcode(context, voucher)
                          : null,
                      onArchive: () => _toggleArchive(context, ref, voucher),
                      onDelete: () => _delete(context, ref, voucher),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.onTap,
    required this.onEditRemaining,
    required this.onArchive,
    required this.onDelete,
    this.onOpenLink,
    this.onShowBarcode,
    this.faded = false,
  });

  final GiftVoucherModel voucher;
  final VoidCallback onTap;
  final VoidCallback onEditRemaining;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback? onOpenLink;
  final VoidCallback? onShowBarcode;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final store = voucher.storeName?.trim();
    final subtitleParts = <String>[
      if (store != null && store.isNotEmpty) store,
      'מקורי ${_currency.format(voucher.originalAmount)}',
      'התקבל ${_dateFormat.format(voucher.receivedAt)}',
      if (voucher.expiresAt != null)
        'תוקף ${_dateFormat.format(voucher.expiresAt!)}',
    ];

    return Opacity(
      opacity: faded ? 0.65 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.income.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: AppColors.income,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitleParts.join(' · '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currency.format(voucher.remainingAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.income,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'יתרה',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onTap();
                          case 'remaining':
                            onEditRemaining();
                          case 'link':
                            onOpenLink?.call();
                          case 'barcode':
                            onShowBarcode?.call();
                          case 'archive':
                            onArchive();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('עריכה'),
                        ),
                        const PopupMenuItem(
                          value: 'remaining',
                          child: Text('עדכון יתרה'),
                        ),
                        if (onOpenLink != null)
                          const PopupMenuItem(
                            value: 'link',
                            child: Text('פתח לינק'),
                          ),
                        if (onShowBarcode != null)
                          const PopupMenuItem(
                            value: 'barcode',
                            child: Text('הצג ברקוד'),
                          ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text(
                            voucher.isArchived ? 'החזר לפעילים' : 'העבר לארכיון',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('מחק'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: voucher.remainingShare,
                    minHeight: 6,
                    color: AppColors.income,
                    backgroundColor: AppColors.income.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('עדכון יתרה'),
                      onPressed: onEditRemaining,
                    ),
                    if (onOpenLink != null)
                      ActionChip(
                        avatar: const Icon(Icons.link, size: 16),
                        label: const Text('לינק'),
                        onPressed: onOpenLink,
                      ),
                    if (onShowBarcode != null)
                      ActionChip(
                        avatar: const Icon(Icons.qr_code_2, size: 16),
                        label: const Text('ברקוד'),
                        onPressed: onShowBarcode,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
