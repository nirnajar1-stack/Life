import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/expense_nature.dart';

/// Pick how many people share an expense (2–10).
Future<int?> showSharedSplitDialog(
  BuildContext context, {
  int initial = SharedExpenseFlag.defaultSplit,
  String title = 'חלוקה משותפת',
  String? message,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => _SharedSplitDialog(
      initial: initial,
      title: title,
      message: message,
    ),
  );
}

class _SharedSplitDialog extends StatefulWidget {
  const _SharedSplitDialog({
    required this.initial,
    required this.title,
    this.message,
  });

  final int initial;
  final String title;
  final String? message;

  @override
  State<_SharedSplitDialog> createState() => _SharedSplitDialogState();
}

class _SharedSplitDialogState extends State<_SharedSplitDialog> {
  late int _split;
  late final TextEditingController _custom;

  @override
  void initState() {
    super.initState();
    _split = widget.initial < 2 ? SharedExpenseFlag.defaultSplit : widget.initial;
    _custom = TextEditingController(
      text: _split > 6 ? '$_split' : '',
    );
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _select(int value) {
    setState(() {
      _split = value;
      _custom.clear();
    });
  }

  int? _resolvedSplit() {
    final custom = int.tryParse(_custom.text.trim());
    if (custom != null && custom >= 2 && custom <= 99) return custom;
    return _split >= 2 ? _split : null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              const SizedBox(height: 12),
            ],
            const Text('בין כמה אנשים מתחלקת ההוצאה?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in const [2, 3, 4, 5, 6])
                  ChoiceChip(
                    label: Text('$value'),
                    selected: _split == value && _custom.text.trim().isEmpty,
                    onSelected: (_) => _select(value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _custom,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'מספר אחר (2–99)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () {
              final split = _resolvedSplit();
              if (split == null) return;
              Navigator.pop(context, split);
            },
            child: const Text('שמירה'),
          ),
        ],
      ),
    );
  }
}

class SharedSplitSelector extends StatelessWidget {
  const SharedSplitSelector({
    super.key,
    required this.split,
    required this.onChanged,
  });

  final int split;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'חלוקה בין',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in const [2, 3, 4, 5, 6])
              ChoiceChip(
                label: Text('$value אנשים'),
                selected: split == value,
                onSelected: (_) => onChanged(value),
              ),
            ActionChip(
              label: Text(split > 6 ? '$split אנשים' : 'מספר אחר…'),
              onPressed: () async {
                final picked = await showSharedSplitDialog(
                  context,
                  initial: split,
                  title: 'חלוקה משותפת',
                );
                if (picked != null) onChanged(picked);
              },
            ),
          ],
        ),
      ],
    );
  }
}

String sharedSplitLabel(int? sharedExp) {
  final split = SharedExpenseFlag.splitCount(sharedExp);
  if (split == null) return '';
  return 'משותף $split';
}

String formatSharedAmount({
  required double gross,
  required double actual,
  required int? sharedExp,
  required String Function(double) formatMoney,
}) {
  if (!SharedExpenseFlag.isShared(sharedExp) || sharedExp == null || sharedExp <= 1) {
    return formatMoney(gross);
  }
  if ((gross - actual).abs() < 0.005) {
    return formatMoney(gross);
  }
  return '${formatMoney(actual)} · ${formatMoney(gross)} ÷ $sharedExp';
}
