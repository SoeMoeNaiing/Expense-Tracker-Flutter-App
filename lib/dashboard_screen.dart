import 'package:flutter/material.dart';

import 'add_transaction_screen.dart';
import 'database_service.dart';
import 'theme.dart';
import 'transaction.dart';
import 'transaction_history_screen.dart';
import 'utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalBalance = 0;
  double totalIncome = 0;
  double totalExpense = 0;
  List<Transaction> recent = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final income = await DatabaseService.instance.getTotalIncome();
    final expense = await DatabaseService.instance.getTotalExpense();
    final transactions = await DatabaseService.instance.getTransactions();
    if (!mounted) return;
    setState(() {
      totalIncome = income;
      totalExpense = expense;
      totalBalance = income - expense;
      recent = transactions.take(5).toList();
      isLoading = false;
    });
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: _openHistory,
          ),
        ],
      ),
      floatingActionButton: _fab(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _balanceCard(),
                  const SizedBox(height: 16),
                  Row(children: [
                    _miniStat('Income', totalIncome,
                        Icons.south_west_rounded, AppColors.incomeGradient),
                    const SizedBox(width: 12),
                    _miniStat('Expense', totalExpense,
                        Icons.north_east_rounded, AppColors.expenseGradient),
                  ]),
                  const SizedBox(height: 24),
                  _sectionHeader('Recent Transactions', 'See all', _openHistory),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    _emptyRecent()
                  else
                    ...recent.map(_tile),
                ],
              ),
            ),
    );
  }

  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.colored(AppColors.primary),
      ),
      child: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.balanceGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.colored(AppColors.primary),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40, top: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 30, bottom: -50,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15), shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Total Balance',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalBalance),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  formatMoney(v),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Your current financial status',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value, IconData icon, Gradient g) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: g, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(value),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        TextButton(
          onPressed: onTap,
          child: Text(action,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _emptyRecent() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No transactions yet', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Tap + to add your first one',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tile(Transaction item) {
    final isIncome = item.type == 'Income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    final gradient = isIncome ? AppColors.incomeGradient : AppColors.expenseGradient;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                gradient: gradient, borderRadius: BorderRadius.circular(14)),
            child: Icon(categoryIcon(item.category),
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(item.category,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${formatMoney(item.amount)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
