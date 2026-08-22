import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/recurring_income_model.dart';
import '../../domain/providers/income_providers.dart';
import '../screens/recurring_income_form_screen.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);

class RecurringIncomesTab extends ConsumerWidget {
  const RecurringIncomesTab({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    RecurringIncomeModel? template,
  }) async {
    await showAdaptiveForm(
      context: context,
      form: RecurringIncomeFormScreen(template: template),
    );
    ref.invalidate(recurringIncomesProvider);
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    RecurringIncomeModel template,
  ) async {
    try {
      await ref.read(recurringIncomeRepositoryProvider).update(
            template.copyWith(isActive: !template.isActive),
          );
      ref.invalidate(recurringIncomesProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('עדכון נכשל: $error')),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecurringIncomeModel template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת הכנסה קבועה'),
          content: Text(
            'למחוק את "${template.title}"? הרשומות שכבר נרשמו בפנקס יישארו.',
          ),
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
      await ref.read(recurringIncomeRepositoryProvider).delete(template.id);
      ref.invalidate(recurringIncomesProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  Future<void> _recordMonthlyNet(
    BuildContext context,
    WidgetRef ref,
    RecurringIncomeModel template,
  ) async {
    final controller = TextEditingController(
      text: template.amount != null && template.amount! > 0
          ? (template.amount == template.amount!.roundToDouble()
              ? template.amount!.toInt().toString()
              : template.amount.toString())
          : '',
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('${template.title} — ${_monthLabel(DateTime.now())}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'נטו שקיבלת',
              suffixText: '₪',
              border: OutlineInputBorder(),
            ),
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
                if (parsed == null || parsed <= 0) return;
                Navigator.pop(ctx, parsed);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.income),
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (amount == null) return;

    try {
      await ref.read(recurringIncomeRepositoryProvider).recordMonthlyIncome(
            template: template,
            netAmount: amount,
          );
      await onRefresh?.call();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${template.title}: ${_currency.format(amount)}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שמירה נכשלה: $error')),
      );
    }
  }

  String _monthLabel(DateTime date) {
    const months = [
      '',
      'ינואר',
      'פברואר',
      'מרץ',
      'אפריל',
      'מאי',
      'יוני',
      'יולי',
      'אוגוסט',
      'ספטמבר',
      'אוקטובר',
      'נובמבר',
      'דצמבר',
    ];
    return '${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recurringIncomesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(
        title: 'שגיאה בטעינת הכנסות קבועות',
        error: error,
        onRetry: () => ref.invalidate(recurringIncomesProvider),
      ),
      data: (items) {
        final active = items.where((item) => item.isActive).toList();
        final paused = items.where((item) => !item.isActive).toList();
        final pending = active.where((item) => !item.recordedThisMonth).length;

        if (items.isEmpty) {
          return _wrapRefresh(
            onRefresh: onRefresh,
            child: AppEmptyState(
              icon: Icons.payments_outlined,
              title: 'אין הכנסות קבועות',
              message:
                  'הוסף משכורת או קצבה — בכל חודש תזין כמה נטו קיבלת בפועל.',
              actionLabel: 'הכנסה קבועה',
              onAction: () => _openForm(context, ref),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh ?? () async {},
          child: ListView(
            padding: AppLayout.listPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'הכנסות קבועות פעילות',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'כל חודש הזן את הסכום הנטו שקיבלת — משכורת משתנה, בונוסים וכו׳.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      if (pending > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$pending ממתינות לרישום החודש',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final template in active) ...[
                _TemplateCard(
                  template: template,
                  onEdit: () => _openForm(context, ref, template: template),
                  onToggle: () => _toggleActive(context, ref, template),
                  onDelete: () => _delete(context, ref, template),
                  onRecord: !template.recordedThisMonth
                      ? () => _recordMonthlyNet(context, ref, template)
                      : null,
                ),
                const SizedBox(height: 8),
              ],
              if (paused.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'מושהות',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                for (final template in paused) ...[
                  _TemplateCard(
                    template: template,
                    onEdit: () => _openForm(context, ref, template: template),
                    onToggle: () => _toggleActive(context, ref, template),
                    onDelete: () => _delete(context, ref, template),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

Widget _wrapRefresh({
  required Future<void> Function()? onRefresh,
  required Widget child,
}) {
  if (onRefresh == null) return child;
  return LayoutBuilder(
    builder: (context, constraints) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      );
    },
  );
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    this.onRecord,
  });

  final RecurringIncomeModel template;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        template.category,
                        template.scheduleLabel,
                        template.amountLabel,
                        if (template.recordedThisMonth) 'נרשם החודש',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRecord != null)
                FilledButton.tonal(
                  onPressed: onRecord,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.income.withValues(alpha: 0.12),
                    foregroundColor: AppColors.income,
                  ),
                  child: const Text('הזן נטו'),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'toggle':
                      onToggle();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(template.isActive ? 'השהה' : 'הפעל'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('מחק'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
