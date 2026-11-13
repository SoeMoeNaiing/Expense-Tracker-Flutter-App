import 'package:flutter/material.dart';

import 'database_service.dart';
import 'theme.dart';
import 'transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  String type = 'Income';
  String category = 'Salary';

  
  

  List<String> get categories =>
      type == 'Income' ? kIncomeCategories : kExpenseCategories;

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid details')),
      );
      return;
    }
    final t = Transaction(
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: DateTime.now().toIso8601String(),
    );
    await DatabaseService.instance.insertTransaction(t);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'Income';
    final accent = isIncome ? AppColors.income : AppColors.expense;
    final gradient = isIncome ? AppColors.incomeGradient : AppColors.expenseGradient;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _typeToggle(),
            const SizedBox(height: 24),
            _label('Amount'),
            const SizedBox(height: 8),
            _amountField(accent),
            const SizedBox(height: 20),
            _label('Title'),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: _inputDecoration('What is this for?', Icons.edit_rounded),
            ),
            const SizedBox(height: 20),
            _label('Category'),
            const SizedBox(height: 8),
            _categoryGrid(gradient),
            const SizedBox(height: 32),
            _saveButton(gradient),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 14));

  Widget _typeToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: ['Income', 'Expense'].map((t) {
          final selected = type == t;
          final sg = t == 'Income'
              ? AppColors.incomeGradient
              : AppColors.expenseGradient;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                type = t;
                category = categories.first;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: selected ? sg : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t == 'Income'
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 18,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _amountField(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
        border: Border.all(color: accent.withAlpha(60), width: 1.5),
      ),
      child: Row(
        children: [
          Text('Ks',
              style: TextStyle(
                  color: accent, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                hintStyle: TextStyle(
                    fontSize: 24,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Widget _categoryGrid(Gradient g) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((c) {
        final selected = c == category;
        return GestureDetector(
          onTap: () => setState(() => category = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: selected ? g : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(categoryIcon(c),
                    size: 18,
                    color: selected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  c,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _saveButton(Gradient g) {
    return Container(
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.colored(AppColors.primary),
      ),
      child: ElevatedButton.icon(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        icon: const Icon(Icons.check_rounded, color: Colors.white),
        label: const Text('Save Transaction',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
      ),
    );
  }
}
