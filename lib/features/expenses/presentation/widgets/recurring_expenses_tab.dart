import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/recurring_expense_model.dart';
import '../../domain/providers/recurring_expense_providers.dart';
import '../widgets/shared_split_controls.dart';
import '../screens/recurring_expense_form_screen.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);

class RecurringExpensesTab extends ConsumerWidget {
  const RecurringExpensesTab({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    RecurringExpenseModel? template,
  }) async {
    await showAdaptiveForm(
      context: context,
      form: RecurringExpenseFormScreen(template: template),
    );
    ref.invalidate(recurringExpensesProvider);
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseModel template,
  ) async {
    try {
      await ref.read(recurringExpenseRepositoryProvider).update(
            template.copyWith(isActive: !template.isActive),
          );
      ref.invalidate(recurringExpensesProvider);
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
    RecurringExpenseModel template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת הוצאה קבועה'),
          content: Text('למחוק את "${template.title}"? החיובים שכבר נוצרו יישארו בפנקס.'),
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
      await ref.read(recurringExpenseRepositoryProvider).delete(template.id);
      ref.invalidate(recurringExpensesProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  Future<void> _recordVariableCharge(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseModel template,
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
            decoration: const InputDecoration(
              labelText: 'סכום החודש',
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
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (amount == null) return;

    try {
      await ref.read(recurringExpenseRepositoryProvider).recordVariableCharge(
            template: template,
            amount: amount,
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
    final async = ref.watch(recurringExpensesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(
        title: 'שגיאה בטעינת הוצאות קבועות',
        error: error,
        onRetry: () => ref.invalidate(recurringExpensesProvider),
      ),
      data: (items) {
        final active = items.where((item) => item.isActive).toList();
        final paused = items.where((item) => !item.isActive).toList();
        final monthlyTotal = active.fold<double>(
          0,
          (sum, item) =>
              item.amountVariable ? sum : sum + item.actualAmount,
        );
        final pendingVariable = active
            .where((item) => item.amountVariable && !item.chargedThisMonth)
            .length;

        if (items.isEmpty) {
          return _wrapRefresh(
            onRefresh: onRefresh,
            child: AppEmptyState(
              icon: Icons.event_repeat,
              title: 'אין הוצאות קבועות',
              message:
                  'הוסף שכ״ד, ארנונה או מנוי — המערכת תיצור אותם אוטומטית בפנקש בכל חודש.',
              actionLabel: 'הוצאה קבועה',
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
                      'סה״כ קבועות פעילות (החלק שלך)',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(monthlyTotal),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'בכל פתיחה נוצרים חיובים קבועים; סכומים משתנים (חשמל, מים…) מוזנים ידנית בסוף החודש.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    if (pendingVariable > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$pendingVariable חשבונות ממתינים לסכום החודש',
                        style: TextStyle(
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
                onRecordVariable: template.amountVariable &&
                        !template.chargedThisMonth
                    ? () => _recordVariableCharge(context, ref, template)
                    : null,
              ),
              const SizedBox(height: 8),
            ],
            if (paused.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'מושהות',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted),
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
    this.onRecordVariable,
  });

  final RecurringExpenseModel template;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onRecordVariable;

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
                        if (template.isShared)
                          sharedSplitLabel(template.sharedExp),
                        if (template.amountVariable) 'סכום משתנה',
                        if (template.amountVariable &&
                            template.chargedThisMonth)
                          'נרשם החודש',
                        if (template.lastGeneratedMonth != null)
                          'נוצר עד ${_formatMonth(template.lastGeneratedMonth!)}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (onRecordVariable != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: onRecordVariable,
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('הזן סכום החודש'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    template.amountVariable
                        ? template.amountLabel
                        : formatSharedAmount(
                            gross: template.amount ?? 0,
                            actual: template.actualAmount,
                            sharedExp: template.sharedExp,
                            formatMoney: _currency.format,
                          ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'pause') onToggle();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('עריכה')),
                      PopupMenuItem(
                        value: 'pause',
                        child: Text(template.isActive ? 'השהה' : 'הפעל'),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('מחק')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMonth(DateTime month) {
    return DateFormat('MM/yyyy').format(month);
  }
}
