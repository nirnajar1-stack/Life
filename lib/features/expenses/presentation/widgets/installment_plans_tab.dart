import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/installment_plan_model.dart';
import '../../domain/providers/installment_plan_providers.dart';
import '../screens/installment_plan_form_screen.dart';
import '../widgets/shared_split_controls.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);
final _dateFormat = DateFormat('dd/MM/yyyy');

class InstallmentPlansTab extends ConsumerWidget {
  const InstallmentPlansTab({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    await showAdaptiveForm(
      context: context,
      form: const InstallmentPlanFormScreen(),
    );
    ref.invalidate(installmentPlansProvider);
  }

  Future<void> _deletePlan(
    BuildContext context,
    WidgetRef ref,
    InstallmentPlanModel plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת תוכנית'),
          content: Text(
            'למחוק את "${plan.title}"?\n'
            'כל ${plan.installmentsTotal} התשלומים יימחקו מהפנקס.',
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
      await ref.read(installmentPlanRepositoryProvider).deletePlan(plan.id);
      await refreshInstallmentPlansAndExpenses(ref);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(installmentPlansProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(
        title: 'שגיאה בטעינת תוכניות תשלום',
        error: error,
        onRetry: () => ref.invalidate(installmentPlansProvider),
      ),
      data: (plans) {
        final active = plans.where((p) => !p.isComplete && p.isActive).toList();
        final completed = plans.where((p) => p.isComplete).toList();
        final monthlyBurden = active.fold<double>(
          0,
          (sum, plan) => sum + plan.actualMonthlyAmount,
        );

        if (plans.isEmpty) {
          return _wrapRefresh(
            onRefresh: onRefresh,
            child: AppEmptyState(
              icon: Icons.credit_score_outlined,
              title: 'אין תוכניות תשלום',
              message:
                  'הוסף קנייה בתשלומים (למשל ₪1,000 ב-4 חודשים) '
                  'או הלוואה (למשל רכב ב-5 שנים). '
                  'התשלומים יופיעו אוטומטית בפנקש.',
              actionLabel: 'תוכנית חדשה',
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
                        'עומס חודשי פעיל (החלק שלך)',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currency.format(monthlyBurden),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${active.length} תוכניות פעילות · ${completed.length} הושלמו',
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
              for (final plan in active) ...[
                _PlanCard(
                  plan: plan,
                  onDelete: () => _deletePlan(context, ref, plan),
                ),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'הושלמו',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                for (final plan in completed) ...[
                  _PlanCard(
                    plan: plan,
                    onDelete: () => _deletePlan(context, ref, plan),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onDelete,
  });

  final InstallmentPlanModel plan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeColor = plan.planType == InstallmentPlanType.loan
        ? Colors.indigo
        : Colors.deepOrange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              plan.planType.label,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          plan.category,
                          plan.progressLabel,
                          if (plan.isShared)
                            sharedSplitLabel(plan.sharedExp),
                          if (plan.nextChargeDate != null && !plan.isComplete)
                            'הבא: ${_dateFormat.format(plan.nextChargeDate!)}',
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatSharedAmount(
                        gross: plan.monthlyAmount,
                        actual: plan.actualMonthlyAmount,
                        sharedExp: plan.sharedExp,
                        formatMoney: _currency.format,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Text(
                      'לחודש',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('מחק')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: plan.progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.line,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plan.isComplete
                  ? 'הושלם · ${_currency.format(plan.actualTotalAmount)} סה״כ'
                  : 'נותרו ${plan.remainingInstallments} תשלומים · '
                      '${_currency.format(plan.actualRemainingAmount)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
