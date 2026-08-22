import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../data/models/installment_plan_model.dart';
import '../../domain/models/expense_category_taxonomy.dart';
import '../../domain/models/expense_nature.dart';
import '../../domain/providers/installment_plan_providers.dart';
import '../widgets/shared_split_controls.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');
final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);

enum _DurationUnit { months, years }

class InstallmentPlanFormScreen extends ConsumerStatefulWidget {
  const InstallmentPlanFormScreen({super.key});

  @override
  ConsumerState<InstallmentPlanFormScreen> createState() =>
      _InstallmentPlanFormScreenState();
}

class _InstallmentPlanFormScreenState
    extends ConsumerState<InstallmentPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController(text: '4');
  final _subCategoryController = TextEditingController();

  DateTime _firstChargeDate = DateTime.now();
  InstallmentPlanType _planType = InstallmentPlanType.purchase;
  _DurationUnit _durationUnit = _DurationUnit.months;
  String _parentCategory = ExpenseCategoryTaxonomy.tech;
  bool _isShared = false;
  int _sharedSplit = SharedExpenseFlag.defaultSplit;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  int? _installmentsCount() {
    final raw = int.tryParse(_durationController.text.trim());
    if (raw == null || raw <= 0) return null;
    if (_durationUnit == _DurationUnit.years) return raw * 12;
    return raw;
  }

  String? _previewText() {
    final total =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    final count = _installmentsCount();
    if (total == null || total <= 0 || count == null || count < 2) return null;

    final amounts = splitInstallmentAmounts(
      totalAmount: total,
      installmentsCount: count,
    );
    final monthly = amounts.first;
    final personal = SharedExpenseFlag.actualAmount(monthly, _isShared ? _sharedSplit : 0);
    final unitLabel = _durationUnit == _DurationUnit.years ? 'שנים' : 'חודשים';
    return 'ייווצרו $count תשלומים (${_durationController.text} $unitLabel) · '
        '${_currency.format(monthly)} לחודש'
        '${_isShared ? ' · ${_currency.format(personal)} החלק שלך' : ''}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstChargeDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _firstChargeDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final count = _installmentsCount();
    if (count == null) return;

    setState(() => _saving = true);

    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
            0;
    final sharedValue = SharedExpenseFlag.toDb(
      shared: _isShared,
      split: _sharedSplit,
    );

    try {
      await ref.read(installmentPlanRepositoryProvider).createPlan(
            title: _titleController.text.trim(),
            totalAmount: amount,
            installmentsCount: count,
            firstChargeDate: _firstChargeDate,
            category: _parentCategory,
            subCategory: _subCategoryController.text.trim().isEmpty
                ? 'כללי'
                : _subCategoryController.text.trim(),
            planType: _planType,
            sharedExp: sharedValue,
          );
      await refreshInstallmentPlansAndExpenses(ref);
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
    final maxDuration = _durationUnit == _DurationUnit.years ? 30 : 360;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: inDialog ? Colors.white : AppColors.surface,
        appBar: AppBar(
          backgroundColor: inDialog ? Colors.white : null,
          title: const Text('תוכנית תשלומים / הלוואה'),
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
                  SegmentedButton<InstallmentPlanType>(
                    segments: [
                      for (final type in InstallmentPlanType.values)
                        ButtonSegment(
                          value: type,
                          label: Text(type.label),
                        ),
                    ],
                    selected: {_planType},
                    onSelectionChanged: (value) {
                      setState(() {
                        _planType = value.first;
                        if (_planType == InstallmentPlanType.loan) {
                          _parentCategory = ExpenseCategoryTaxonomy.transport;
                          if (_durationUnit == _DurationUnit.months &&
                              (int.tryParse(_durationController.text) ?? 0) <=
                                  12) {
                            _durationController.text = '5';
                            _durationUnit = _DurationUnit.years;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: _planType == InstallmentPlanType.loan
                          ? 'שם ההלוואה'
                          : 'שם הרכישה',
                      hintText: _planType == InstallmentPlanType.loan
                          ? 'הלוואת רכב, משכנתא…'
                          : 'מקלדת + עכבר, מחשב…',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'נא להזין שם' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: _planType == InstallmentPlanType.loan
                          ? 'סכום ההלוואה'
                          : 'סכום כולל של הרכישה',
                      suffixText: '₪',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final parsed =
                          double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return 'נא להזין סכום תקין';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: _durationUnit == _DurationUnit.years
                                ? 'מספר שנים'
                                : 'מספר תשלומים',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n < 1) {
                              return 'נא להזין מספר תקין';
                            }
                            final months = _durationUnit == _DurationUnit.years
                                ? n * 12
                                : n;
                            if (months < 2 || months > 360) {
                              return 'בין 2 ל-360 חודשים';
                            }
                            if (_durationUnit == _DurationUnit.years &&
                                n > maxDuration) {
                              return 'עד $maxDuration שנים';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'יחידה',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<_DurationUnit>(
                              value: _durationUnit,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: _DurationUnit.months,
                                  child: Text('חודשים'),
                                ),
                                DropdownMenuItem(
                                  value: _DurationUnit.years,
                                  child: Text('שנים'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _durationUnit = value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _previewText() ??
                        'התשלום הראשון יופיע בחודש הנוכחי אם התאריך הוא היום.',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
                    controller: _subCategoryController,
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
                        labelText: 'תאריך התשלום הראשון',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_dateFormat.format(_firstChargeDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('הוצאה משותפת'),
                    subtitle: const Text('יחול על כל התשלומים בתוכנית'),
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
                    label: const Text('צור תוכנית'),
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
