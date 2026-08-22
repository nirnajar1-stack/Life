import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../data/models/expense_model.dart';
import '../../domain/models/expense_category_taxonomy.dart';
import '../../domain/models/expense_nature.dart';
import '../../domain/providers/expense_providers.dart';
import '../widgets/shared_split_controls.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Form for creating / editing an expense.
///
/// When [ExpenseNature.installment] is selected on create, the form builds
/// a full installment plan (N charge rows, one per month).
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({
    super.key,
    this.expense,
    this.messageGroupSize = 1,
  });

  final ExpenseModel? expense;
  final int messageGroupSize;

  bool get isEditing => expense != null;

  bool get isMessageGroup =>
      messageGroupSize > 1 &&
      (expense?.messageId?.trim().isNotEmpty ?? false);

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _subCategoryController;
  late final TextEditingController _installmentsController;

  late DateTime _date;
  late ExpenseNature _nature;
  late bool _isShared;
  late int _sharedSplit;
  late String _parentCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _itemNameController = TextEditingController(text: e?.itemName ?? '');
    _amountController =
        TextEditingController(text: e == null ? '' : _trimAmount(e.amount));
    _subCategoryController =
        TextEditingController(text: e?.subCategory.trim() ?? '');
    _installmentsController = TextEditingController(
      text: e?.installmentsTotal?.toString() ?? '3',
    );
    _date = e?.createdAt ?? DateTime.now();
    _nature = ExpenseNatureX.resolve(
      isFixed: e?.isFixed,
      installmentGroupId: e?.installmentGroupId,
    );
    _isShared = SharedExpenseFlag.isShared(e?.sharedExp);
    _sharedSplit = SharedExpenseFlag.splitCount(e?.sharedExp) ??
        SharedExpenseFlag.defaultSplit;
    _parentCategory = e == null
        ? ExpenseCategoryTaxonomy.food
        : ExpenseCategoryTaxonomy.resolveParent(e.category);
  }

  String _trimAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  String? _installmentSplitPreview() {
    if (widget.isEditing || _nature != ExpenseNature.installment) return null;
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    final count = int.tryParse(_installmentsController.text.trim());
    if (amount == null || amount <= 0 || count == null || count < 2) {
      return null;
    }
    final per = (amount / count);
    return 'ייווצרו $count תשלומים · כ־${per.toStringAsFixed(2)} ₪ לחודש';
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    _subCategoryController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
            0;
    final repo = ref.read(expenseRepositoryProvider);
    final sharedValue = SharedExpenseFlag.toDb(
      shared: _isShared,
      split: _sharedSplit,
    );
    final subCategory = _subCategoryController.text.trim().isEmpty
        ? 'כללי'
        : _subCategoryController.text.trim();

    try {
      if (widget.isEditing) {
        final existing = widget.expense!;
        // Editing a single charge row — keep installment metadata as-is.
        final updated = existing.copyWith(
          itemName: _itemNameController.text.trim(),
          amount: amount,
          category: _parentCategory,
          subCategory: subCategory,
          createdAt: _date,
          isFixed: _nature == ExpenseNature.fixed ? 1 : 0,
          sharedExp: sharedValue,
        );
        await repo.updateExpense(updated);

        final mid = existing.messageId?.trim();
        if (mid != null && mid.isNotEmpty) {
          await repo.updateSharedFlagForMessage(
            messageId: mid,
            sharedExp: sharedValue,
          );
        }
      } else if (_nature == ExpenseNature.installment) {
        final count = int.parse(_installmentsController.text.trim());
        await repo.createInstallmentPlan(
          itemName: _itemNameController.text.trim(),
          totalAmount: amount,
          installmentsCount: count,
          firstChargeDate: _date,
          category: _parentCategory,
          subCategory: subCategory,
          sharedSplit: sharedValue,
        );
      } else {
        final created = ExpenseModel(
          id: 0,
          createdAt: _date,
          itemName: _itemNameController.text.trim(),
          amount: amount,
          category: _parentCategory,
          subCategory: subCategory,
          isFixed: _nature.isFixedDbValue,
          source: 'life_app',
          uuid: '',
          insertedAt: DateTime.now(),
          sharedExp: sharedValue,
        );
        await repo.addExpense(created);
      }

      ref.invalidate(expensesRawProvider);
      ref.invalidate(expensesSummaryProvider);
      ref.invalidate(recentExpensesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_successMessage())),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('השמירה נכשלה: $error')),
      );
    }
  }

  String _successMessage() {
    if (widget.isEditing) {
      final sharedNote = widget.isMessageGroup
          ? ' (כולל ${widget.messageGroupSize} פריטים בקנייה)'
          : '';
      return 'ההוצאה עודכנה$sharedNote';
    }
    if (_nature == ExpenseNature.installment) {
      return 'נוצרה תוכנית של ${_installmentsController.text} תשלומים';
    }
    return 'ההוצאה נוספה';
  }

  @override
  Widget build(BuildContext context) {
    final inDialog = isFormDialog(context);
    final editingInstallment = widget.isEditing && widget.expense!.isInstallment;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: inDialog ? Colors.white : AppColors.surface,
        appBar: AppBar(
          backgroundColor: inDialog ? Colors.white : null,
          title: Text(widget.isEditing ? 'עריכת הוצאה' : 'הוצאה חדשה'),
          leading: IconButton(
            tooltip: 'סגור',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (editingInstallment) ...[
                        Card(
                          color: Colors.deepOrange.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.calendar_view_month),
                            title: Text(widget.expense!.installmentLabel ??
                                'תשלום בתוכנית'),
                            subtitle: Text(
                              'תאריך רכישה: '
                              '${widget.expense!.purchaseDate != null ? _dateFormat.format(widget.expense!.purchaseDate!) : '—'}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _itemNameController,
                        autofocus: !widget.isEditing,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'שם הפריט',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'נא להזין שם פריט'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: (!widget.isEditing &&
                                  _nature == ExpenseNature.installment)
                              ? 'סכום כולל של הרכישה'
                              : 'סכום',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: '₪',
                        ),
                        validator: (v) {
                          final parsed = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.'));
                          if (parsed == null || parsed <= 0) {
                            return 'נא להזין סכום תקין';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'קטגוריה',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final parent
                              in ExpenseCategoryTaxonomy.allParents)
                              ChoiceChip(
                                showCheckmark: false,
                                label: Text(parent),
                              selected: _parentCategory == parent,
                              onSelected: (_) {
                                setState(() => _parentCategory = parent);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'פירוט (אופציונלי)',
                          hintText: 'למשל סופר / בנזין / נטפליקס',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: (!widget.isEditing &&
                                    _nature == ExpenseNature.installment)
                                ? 'תאריך התשלום הראשון'
                                : 'תאריך',
                            border: const OutlineInputBorder(),
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_dateFormat.format(_date)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'סוג הוצאה',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ExpenseNature>(
                        segments: [
                          for (final nature in ExpenseNature.values)
                            ButtonSegment(
                              value: nature,
                              label: Text(nature.label),
                              enabled: !widget.isEditing ||
                                  nature != ExpenseNature.installment ||
                                  editingInstallment,
                            ),
                        ],
                        selected: {_nature},
                        onSelectionChanged: widget.isEditing && editingInstallment
                            ? null
                            : (value) {
                                setState(() => _nature = value.first);
                              },
                      ),
                      if (!widget.isEditing &&
                          _nature == ExpenseNature.installment) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _installmentsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'מספר תשלומים',
                            hintText: 'למשל 4',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.repeat),
                          ),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n < 2 || n > 60) {
                              return 'נא להזין מספר בין 2 ל-60';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _installmentSplitPreview() ??
                              'ייווצרו N שורות — אחת לכל חודש, מהתאריך שבחרת.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('הוצאה משותפת'),
                        subtitle: Text(
                          widget.isMessageGroup
                              ? 'יחול על כל ${widget.messageGroupSize} הפריטים בקנייה'
                              : (!widget.isEditing &&
                                      _nature == ExpenseNature.installment)
                                  ? 'יחול על כל התשלומים בתוכנית'
                                  : 'רק החלק שלך ייספר בסיכומים החודשיים',
                        ),
                        value: _isShared,
                        onChanged: (v) => setState(() {
                          _isShared = v;
                          if (v && _sharedSplit < 2) {
                            _sharedSplit = SharedExpenseFlag.defaultSplit;
                          }
                        }),
                      ),
                      if (_isShared) ...[
                        const SizedBox(height: 8),
                        SharedSplitSelector(
                          split: _sharedSplit,
                          onChanged: (value) =>
                              setState(() => _sharedSplit = value),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            !widget.isEditing &&
                                    _nature == ExpenseNature.installment
                                ? 'צור תוכנית תשלומים'
                                : (widget.isEditing
                                    ? 'שמור שינויים'
                                    : 'הוסף הוצאה'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}
