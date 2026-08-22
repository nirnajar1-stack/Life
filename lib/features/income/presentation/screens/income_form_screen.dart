import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../data/models/income_model.dart';
import '../../domain/models/income_type.dart';
import '../../domain/providers/income_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

class IncomeFormScreen extends ConsumerStatefulWidget {
  const IncomeFormScreen({super.key, this.income});

  final IncomeModel? income;

  bool get isEditing => income != null;

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _subCategory;
  late final TextEditingController _notes;
  late DateTime _date;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.income;
    _title = TextEditingController(text: i?.title ?? '');
    _amount = TextEditingController(
      text: i == null
          ? ''
          : (i.amount == i.amount.roundToDouble()
              ? i.amount.toInt().toString()
              : i.amount.toString()),
    );
    _subCategory = TextEditingController(text: i?.subCategory ?? '');
    _notes = TextEditingController(text: i?.notes ?? '');
    _date = i?.createdAt ?? DateTime.now();
    _category = i?.category ?? IncomeCategoryTaxonomy.freelance;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _subCategory.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final amount =
        double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0;
    final repo = ref.read(incomeRepositoryProvider);

    try {
      if (widget.isEditing) {
        await repo.update(
          widget.income!.copyWith(
            title: _title.text.trim(),
            amount: amount,
            category: _category,
            subCategory: _subCategory.text.trim().isEmpty
                ? 'כללי'
                : _subCategory.text.trim(),
            createdAt: _date,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            clearNotes: _notes.text.trim().isEmpty,
          ),
        );
      } else {
        await repo.insert(
          IncomeModel(
            id: 0,
            createdAt: _date,
            title: _title.text.trim(),
            amount: amount,
            category: _category,
            subCategory: _subCategory.text.trim().isEmpty
                ? 'כללי'
                : _subCategory.text.trim(),
            incomeType: IncomeType.variable,
            source: 'life_app',
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            insertedAt: DateTime.now(),
          ),
        );
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
          title: Text(widget.isEditing ? 'עריכת הכנסה' : 'הכנסה חד-פעמית'),
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
                      labelText: 'תיאור',
                      hintText: 'מכירה במד״ו, פרילנס, מתנה…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'נא להזין תיאור' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'סכום נטו',
                      suffixText: '₪',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final parsed =
                          double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return 'נא להזין סכום תקין';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in IncomeCategoryTaxonomy.all)
                        if (cat != IncomeCategoryTaxonomy.salary)
                          ChoiceChip(
                            label: Text(cat),
                            selected: _category == cat,
                            onSelected: (_) => setState(() => _category = cat),
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
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'תאריך',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_dateFormat.format(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
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
