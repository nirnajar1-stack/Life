import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/income_model.dart';
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

  Future<void> _recordOrUpdatePeriod(
    BuildContext context,
    WidgetRef ref,
    RecurringIncomeModel template,
  ) async {
    final result = await showDialog<_PeriodAmountResult>(
      context: context,
      builder: (ctx) => _PeriodAmountDialog(template: template),
    );
    if (result == null) return;

    try {
      await ref.read(recurringIncomeRepositoryProvider).upsertMonthlyIncome(
            template: template,
            netAmount: result.amount,
            incomeDate: result.date,
          );
      await onRefresh?.call();
      ref.invalidate(recurringIncomesProvider);
      if (!context.mounted) return;
      final verb = result.wasUpdate ? 'עודכן' : 'נרשם';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${template.title}: $verb ${_currency.format(result.amount)} '
            '· ${_dateLabel(result.date)}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שמירה נכשלה: $error')),
      );
    }
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
                        'בחר תאריך בכל חודש והזן/עדכן את הסכום הנטו לאותה תקופה.',
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
                  onRecord: () =>
                      _recordOrUpdatePeriod(context, ref, template),
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

class _PeriodAmountResult {
  const _PeriodAmountResult({
    required this.amount,
    required this.date,
    required this.wasUpdate,
  });

  final double amount;
  final DateTime date;
  final bool wasUpdate;
}

class _PeriodAmountDialog extends ConsumerStatefulWidget {
  const _PeriodAmountDialog({required this.template});

  final RecurringIncomeModel template;

  @override
  ConsumerState<_PeriodAmountDialog> createState() =>
      _PeriodAmountDialogState();
}

class _PeriodAmountDialogState extends ConsumerState<_PeriodAmountDialog> {
  late DateTime _month;
  late DateTime _selectedDate;
  late final TextEditingController _amount;
  IncomeModel? _existing;
  bool _loadingExisting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = incomeMonthStart(now);
    final preferredDay = widget.template.dayOfMonth.clamp(1, _daysInMonth(_month));
    _selectedDate = DateTime(_month.year, _month.month, preferredDay);
    _amount = TextEditingController(
      text: widget.template.amount != null && widget.template.amount! > 0
          ? _formatAmount(widget.template.amount!)
          : '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  String _formatAmount(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

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

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    try {
      final existing =
          await ref.read(recurringIncomeRepositoryProvider).fetchIncomeForMonth(
                template: widget.template,
                month: _month,
              );
      if (!mounted) return;
      setState(() {
        _existing = existing;
        _loadingExisting = false;
        if (existing != null) {
          _amount.text = _formatAmount(existing.amount);
          _selectedDate = existing.createdAt;
          // Keep selected date within the chosen month.
          if (incomeMonthStart(_selectedDate) != _month) {
            final day = existing.createdAt.day.clamp(1, _daysInMonth(_month));
            _selectedDate = DateTime(_month.year, _month.month, day);
          }
        } else {
          final day =
              widget.template.dayOfMonth.clamp(1, _daysInMonth(_month));
          _selectedDate = DateTime(_month.year, _month.month, day);
          if (widget.template.amount != null && widget.template.amount! > 0) {
            _amount.text = _formatAmount(widget.template.amount!);
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _existing = null;
        _loadingExisting = false;
      });
    }
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final day = _selectedDate.day.clamp(1, _daysInMonth(next));
    setState(() {
      _month = next;
      _selectedDate = DateTime(next.year, next.month, day);
    });
    _loadExisting();
  }

  Future<void> _pickDate() async {
    final lastDay = _daysInMonth(_month);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(_month.year, _month.month, 1),
      lastDate: DateTime(_month.year, _month.month, lastDay),
      helpText: 'בחר תאריך בחודש',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final parsed =
        double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return;
    Navigator.pop(
      context,
      _PeriodAmountResult(
        amount: parsed,
        date: _selectedDate,
        wasUpdate: _existing != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'he');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.template.title),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'חודש קודם',
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Expanded(
                    child: Text(
                      _monthLabel(_month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'חודש הבא',
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'תאריך ההכנסה',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingExisting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (_existing != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'כבר קיימת רשומה לחודש זה — השמירה תעדכן אותה.',
                    style: TextStyle(
                      color: AppColors.income.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'נטו שקיבלת',
                  suffixText: '₪',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(backgroundColor: AppColors.income),
            child: Text(_existing != null ? 'עדכן' : 'שמור'),
          ),
        ],
      ),
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
                  child: Text(
                    template.recordedThisMonth ? 'עדכן נטו' : 'הזן נטו',
                  ),
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
