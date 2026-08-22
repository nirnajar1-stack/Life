import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../data/models/recurring_income_model.dart';
import '../../domain/models/income_type.dart';
import '../../domain/providers/income_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

class RecurringIncomeFormScreen extends ConsumerStatefulWidget {
  const RecurringIncomeFormScreen({super.key, this.template});

  final RecurringIncomeModel? template;

  bool get isEditing => template != null;

  @override
  ConsumerState<RecurringIncomeFormScreen> createState() =>
      _RecurringIncomeFormScreenState();
}

class _RecurringIncomeFormScreenState
    extends ConsumerState<RecurringIncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _subCategory;
  late final TextEditingController _dayOfMonth;
  late DateTime _startDate;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _title = TextEditingController(text: t?.title ?? 'משכורת');
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
    _category = t?.category ?? IncomeCategoryTaxonomy.salary;
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
    final day = int.parse(_dayOfMonth.text.trim());
    final repo = ref.read(recurringIncomeRepositoryProvider);

    final draft = (widget.template ??
            RecurringIncomeModel(
              id: '',
              title: _title.text.trim(),
              category: _category,
              subCategory: 'כללי',
              dayOfMonth: day,
              startDate: _startDate,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      title: _title.text.trim(),
      amount: parsedAmount,
      clearAmount: parsedAmount == null || parsedAmount <= 0,
      amountVariable: true,
      category: _category,
      subCategory: _subCategory.text.trim().isEmpty
          ? 'כללי'
          : _subCategory.text.trim(),
      dayOfMonth: day,
      startDate: _startDate,
    );

    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.insert(draft);
      }
      await refreshIncomes(ref);
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
          title: Text(widget.isEditing ? 'עריכת הכנסה קבועה' : 'הכנסה קבועה'),
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
                    decoration: const InputDecoration(
                      labelText: 'שם',
                      hintText: 'משכורת, קצבה…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'נא להזין שם' : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'כל חודש תזין את הסכום הנטו שקיבלת בפועל.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'נטו משוער (אופציונלי)',
                      suffixText: '₪',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                      ChoiceChip(
                        label: const Text(IncomeCategoryTaxonomy.salary),
                        selected: _category == IncomeCategoryTaxonomy.salary,
                        onSelected: (_) => setState(
                            () => _category = IncomeCategoryTaxonomy.salary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subCategory,
                    decoration: const InputDecoration(
                      labelText: 'פירוט (אופציונלי)',
                      hintText: 'מעסיק, מקור…',
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
