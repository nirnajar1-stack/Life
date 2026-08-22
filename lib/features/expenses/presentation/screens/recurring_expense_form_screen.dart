import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../data/models/recurring_expense_model.dart';
import '../../domain/models/expense_category_taxonomy.dart';
import '../../domain/models/expense_nature.dart';
import '../../domain/providers/recurring_expense_providers.dart';
import '../widgets/shared_split_controls.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

class RecurringExpenseFormScreen extends ConsumerStatefulWidget {
  const RecurringExpenseFormScreen({super.key, this.template});

  final RecurringExpenseModel? template;

  bool get isEditing => template != null;

  @override
  ConsumerState<RecurringExpenseFormScreen> createState() =>
      _RecurringExpenseFormScreenState();
}

class _RecurringExpenseFormScreenState
    extends ConsumerState<RecurringExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _subCategory;
  late final TextEditingController _dayOfMonth;
  late DateTime _startDate;
  late String _parentCategory;
  late bool _isShared;
  late int _sharedSplit;
  late bool _amountVariable;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _title = TextEditingController(text: t?.title ?? '');
    _amount = TextEditingController(
      text: t?.amount == null
          ? ''
          : (t!.amount == t.amount!.roundToDouble()
              ? t.amount!.toInt().toString()
              : t.amount.toString()),
    );
    _subCategory = TextEditingController(text: t?.subCategory ?? '');
    _dayOfMonth = TextEditingController(text: '${t?.dayOfMonth ?? 1}');
    _startDate = t?.startDate ?? DateTime.now();
    _parentCategory = t?.category ?? ExpenseCategoryTaxonomy.housing;
    _isShared = t?.isShared ?? false;
    _amountVariable = t?.amountVariable ?? false;
    _sharedSplit =
        SharedExpenseFlag.splitCount(t?.sharedExp) ?? SharedExpenseFlag.defaultSplit;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _subCategory.dispose();
    _dayOfMonth.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final parsedAmount =
        double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final amount = _amountVariable ? null : parsedAmount;
    if (!_amountVariable && (amount == null || amount <= 0)) {
      setState(() => _saving = false);
      return;
    }
    final day = int.parse(_dayOfMonth.text.trim());
    final sharedValue = SharedExpenseFlag.toDb(
      shared: _isShared,
      split: _sharedSplit,
    );
    final repo = ref.read(recurringExpenseRepositoryProvider);
    final draft = (widget.template ??
            RecurringExpenseModel(
              id: '',
              title: _title.text.trim(),
              amount: amount,
              category: _parentCategory,
              subCategory: _subCategory.text.trim().isEmpty
                  ? 'כללי'
                  : _subCategory.text.trim(),
              dayOfMonth: day,
              sharedExp: sharedValue,
              startDate: _startDate,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      title: _title.text.trim(),
      amount: amount,
      clearAmount: _amountVariable && (parsedAmount == null || parsedAmount <= 0),
      category: _parentCategory,
      subCategory: _subCategory.text.trim().isEmpty
          ? 'כללי'
          : _subCategory.text.trim(),
      dayOfMonth: day,
      sharedExp: sharedValue,
      amountVariable: _amountVariable,
      startDate: _startDate,
    );

    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.insert(draft);
      }
      await refreshRecurringAndExpenses(ref);
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: inDialog ? Colors.white : AppColors.surface,
        appBar: AppBar(
          backgroundColor: inDialog ? Colors.white : null,
          title: Text(widget.isEditing ? 'עריכת הוצאה קבועה' : 'הוצאה קבועה חדשה'),
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
                      labelText: 'שם',
                      hintText: 'שכר דירה, ארנונה, Netflix…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'נא להזין שם' : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('סכום משתנה'),
                    subtitle: const Text(
                      'לחשמל, מים, ארנונה — מזינים את הסכום בסוף כל חודש',
                    ),
                    value: _amountVariable,
                    onChanged: (v) => setState(() => _amountVariable = v),
                  ),
                  if (!_amountVariable) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'סכום חודשי',
                        suffixText: '₪',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (_amountVariable) return null;
                        final parsed =
                            double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (parsed == null || parsed <= 0) {
                          return 'נא להזין סכום תקין';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      'לא ייווצר חיוב אוטומטי — תקבל תזכורת להזין סכום בטאב קבועות.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dayOfMonth,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'יום בחודש (1–28)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final day = int.tryParse((v ?? '').trim());
                      if (day == null || day < 1 || day > 28) {
                        return 'בחר יום בין 1 ל-28';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final parent in ExpenseCategoryTaxonomy.allParents)
                        ChoiceChip(
                          label: Text(parent),
                          selected: _parentCategory == parent,
                          onSelected: (_) =>
                              setState(() => _parentCategory = parent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subCategory,
                    decoration: const InputDecoration(
                      labelText: 'פירוט (אופציונלי)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'מתאריך',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_dateFormat.format(_startDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('הוצאה משותפת'),
                    subtitle: const Text('רק החלק שלך ייספר בסיכומים'),
                    value: _isShared,
                    onChanged: (v) => setState(() {
                      _isShared = v;
                      if (v && _sharedSplit < 2) {
                        _sharedSplit = SharedExpenseFlag.defaultSplit;
                      }
                    }),
                  ),
                  if (_isShared) ...[
                    SharedSplitSelector(
                      split: _sharedSplit,
                      onChanged: (value) =>
                          setState(() => _sharedSplit = value),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(widget.isEditing ? 'שמור' : 'הוסף'),
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
