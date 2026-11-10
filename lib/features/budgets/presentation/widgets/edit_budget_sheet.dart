import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/result.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';

class EditBudgetSheet extends ConsumerStatefulWidget {
  /// Null to add a new budget; a value to edit an existing one.
  final Budget? existing;

  const EditBudgetSheet({super.key, this.existing});

  static Future<bool?> show(BuildContext context, {Budget? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (_) => EditBudgetSheet(existing: existing),
    );
  }

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late final TextEditingController _amountCtrl;
  int? _categoryId; // null = overall
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final amt = widget.existing?.amount;
    _amountCtrl = TextEditingController(
      text: amt != null ? NumberFormat.decimalPattern().format(amt) : '',
    );
    _categoryId = widget.existing?.categoryId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _editing => widget.existing != null;

  int get _amount {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return raw.isEmpty ? 0 : int.parse(raw);
  }

  Future<void> _save() async {
    if (_amount <= 0) return _snack('Enter an amount');
    setState(() => _saving = true);
    final result = await ref
        .read(budgetsProvider.notifier)
        .upsert(
          Budget(
            id: widget.existing?.id,
            categoryId: _categoryId,
            amount: _amount,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is Success) {
      Navigator.of(context).pop(true);
    } else {
      _snack(result.messageOrNull ?? 'Save failed');
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    setState(() => _saving = true);
    final result = await ref.read(budgetsProvider.notifier).delete(id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      _snack(result.messageOrNull ?? 'Delete failed');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: AppColors.bgRaised,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider).value ?? const [];
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
            Text(
              _editing ? 'Edit budget' : 'New budget',
              style: text.headlineMedium,
            ),
            const SizedBox(height: 20),

            Text('Applies to', style: text.labelSmall),
            const SizedBox(height: 8),
            if (_editing)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  _categoryId == null
                      ? 'Overall'
                      : (categories
                            .firstWhere(
                              (c) => c.id == _categoryId,
                              orElse: () => categories.first,
                            )
                            .name),
                  style: text.bodyLarge,
                ),
              )
            else
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Pill(
                      label: 'Overall',
                      selected: _categoryId == null,
                      accent: AppColors.primary,
                      onTap: () => setState(() => _categoryId = null),
                    ),
                    for (final c in categories) ...[
                      const SizedBox(width: 8),
                      _Pill(
                        label: c.name,
                        selected: _categoryId == c.id,
                        accent: c.color,
                        onTap: () => setState(() => _categoryId = c.id),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Text('Monthly amount (Ks)', style: text.labelSmall),
            const SizedBox(height: 8),
            TextField(
              key: const Key('budget_amount_field'),
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              style: text.displayLarge?.copyWith(fontSize: 30),
              decoration: const InputDecoration(hintText: '0'),
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
            if (_editing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('delete_budget_button'),
                  onPressed: _saving ? null : _delete,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Delete budget',
                    style: text.labelLarge?.copyWith(color: AppColors.coral),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(38) : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? accent : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: text.labelLarge?.copyWith(
            fontSize: 13,
            color: selected ? accent : AppColors.textPrimary,
          ),
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
