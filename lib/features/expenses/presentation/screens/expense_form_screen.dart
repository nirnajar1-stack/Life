import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/expense_model.dart';
import '../../domain/models/expense_nature.dart';
import '../../domain/providers/expense_providers.dart';

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
  late final TextEditingController _categoryController;
  late final TextEditingController _subCategoryController;
  late final TextEditingController _installmentsController;

  late DateTime _date;
  late ExpenseNature _nature;
  late bool _isShared;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _itemNameController = TextEditingController(text: e?.itemName ?? '');
    _amountController =
        TextEditingController(text: e == null ? '' : _trimAmount(e.amount));
    _categoryController = TextEditingController(text: e?.category.trim() ?? '');
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
  }

  String _trimAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
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
    final sharedValue = SharedExpenseFlag.toDb(_isShared);

    try {
      if (widget.isEditing) {
        final existing = widget.expense!;
        // Editing a single charge row — keep installment metadata as-is.
        final updated = existing.copyWith(
          itemName: _itemNameController.text.trim(),
          amount: amount,
          category: _categoryController.text.trim(),
          subCategory: _subCategoryController.text.trim(),
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
          category: _categoryController.text.trim(),
          subCategory: _subCategoryController.text.trim(),
          isShared: _isShared,
        );
      } else {
        final created = ExpenseModel(
          id: 0,
          createdAt: _date,
          itemName: _itemNameController.text.trim(),
          amount: amount,
          category: _categoryController.text.trim(),
          subCategory: _subCategoryController.text.trim(),
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
    final isWide = MediaQuery.of(context).size.width > 600;
    final editingInstallment = widget.isEditing && widget.expense!.isInstallment;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'עריכת הוצאה' : 'הוצאה חדשה'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: isWide ? const EdgeInsets.all(28) : EdgeInsets.zero,
                decoration: isWide
                    ? BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'קטגוריה',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'נא להזין קטגוריה'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'תת-קטגוריה',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'נא להזין תת-קטגוריה'
                            : null,
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
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ייווצרו N שורות — אחת לכל חודש, מהתאריך שבחרת. '
                          'הסכום הכולל יחולק שווה בין התשלומים.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
                                  : 'מסומן ברמת הפריט',
                        ),
                        value: _isShared,
                        onChanged: (v) => setState(() => _isShared = v),
                      ),
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
      ),
    );
  }
}
