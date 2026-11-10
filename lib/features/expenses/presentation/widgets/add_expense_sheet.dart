import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/result.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/payment_method.dart';
import '../providers/expense_providers.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (_) => const AddExpenseSheet(),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  int? _categoryId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _amountValue {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return raw.isEmpty ? 0 : int.parse(raw);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.bgRaised,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _save() async {
    final catId = _categoryId;
    if (catId == null) return _snack('Pick a category');
    if (_amountValue <= 0) return _snack('Enter an amount');

    setState(() => _saving = true);
    final draft = Expense.draft(
      amount: _amountValue,
      categoryId: catId,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      occurredAt: _occurredAt,
      paymentMethod: _paymentMethod,
    );
    final result = await ref.read(expensesProvider.notifier).add(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Failure(:final message):
        _snack(message);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.bgRaised,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider);
    _categoryId ??= categories.value?.isNotEmpty == true
        ? categories.value!.first.id
        : null;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            Text('Add expense', style: text.headlineMedium),
            const SizedBox(height: 20),

            Text('Amount (MMK)', style: text.labelSmall),
            const SizedBox(height: 8),
            TextField(
              key: const Key('amount_field'),
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              style: text.displayLarge?.copyWith(fontSize: 36),
              decoration: const InputDecoration(
                hintText: '0',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    'Ks',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0),
              ),
            ),
            const SizedBox(height: 20),

            Text('Category', style: text.labelSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: categories.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text('Error: $e', style: text.bodyMedium),
                data: (list) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return _CategoryPill(
                      category: c,
                      selected: c.id == _categoryId,
                      onTap: () => setState(() => _categoryId = c.id),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Payment method', style: text.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final m in PaymentMethod.values) ...[
                  Expanded(
                    child: _PmChoice(
                      method: m,
                      selected: m == _paymentMethod,
                      onTap: () => setState(() => _paymentMethod = m),
                    ),
                  ),
                  if (m != PaymentMethod.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 20),

            Text('Note', style: text.labelSmall),
            const SizedBox(height: 8),
            TextField(
              key: const Key('note_field'),
              controller: _noteCtrl,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Optional',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat.yMMMMd().format(_occurredAt),
                      style: text.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppGradients.fab,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(85),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: text.labelLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PmChoice extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PmChoice({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(38)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              method.icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              method.label,
              style: text.labelSmall?.copyWith(
                fontSize: 10,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryPill({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? category.color.withAlpha(38) : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? category.color : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: selected ? category.color : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: text.labelLarge?.copyWith(
                fontSize: 13,
                color: selected ? category.color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = NumberFormat.decimalPattern().format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
