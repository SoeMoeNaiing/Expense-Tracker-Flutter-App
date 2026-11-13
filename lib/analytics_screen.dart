import 'package:flutter/material.dart';

import 'theme.dart';
import 'transaction.dart';
import 'utils/formatters.dart';
import 'widgets/charts_view.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final String filters;

  const AnalyticsScreen({
    super.key,
    required this.transactions,
    this.filters = '',
  });

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((t) => t.type == 'Income')
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.type == 'Expense')
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(income, expense),
          const SizedBox(height: 16),
          ChartsView(transactions: transactions),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hero(double income, double expense) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.balanceGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.colored(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              const Text('Overview',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              if (filters.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(filters,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('Income', income, Icons.south_west_rounded),
              const SizedBox(width: 40),
              _stat('Expense', expense, Icons.north_east_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(formatMoney(value),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
