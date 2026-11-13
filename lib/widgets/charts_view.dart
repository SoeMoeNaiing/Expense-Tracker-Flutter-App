import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../transaction.dart';
import '../utils/formatters.dart';

class ChartsView extends StatelessWidget {
  final List<Transaction> transactions;
  final bool showCategories;

  const ChartsView({
    super.key,
    required this.transactions,
    this.showCategories = true,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No data to display',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final income = transactions
        .where((t) => t.type == 'Income')
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.type == 'Expense')
        .fold<double>(0, (s, t) => s + t.amount);

    return Column(
      children: [
        _donutCard(),
        const SizedBox(height: 16),
        _categoryBarCard(),
        const SizedBox(height: 16),
        _incomeVsExpenseCard(income, expense),
        if (showCategories) ...[
          const SizedBox(height: 16),
          _categoryList(),
        ],
      ],
    );
  }

  // ---------- helper ----------
  bool _isIncomeCategory(String cat) => transactions
      .any((t) => t.category == cat && t.type == 'Income');

  // ---------- donut ----------
  Widget _donutCard() {
    final totals = <String, double>{};
    for (final t in transactions) {
      totals.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grand = entries.fold<double>(0, (s, e) => s + e.value);

    return _chartCard(
      title: 'Spending by Category',
      subtitle: '${entries.length} categories',
      child: SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 65,
                startDegreeOffset: -90,
                sections: List.generate(entries.length, (i) {
                  return PieChartSectionData(
                    value: entries[i].value,
                    color: AppColors.chartColor(i),
                    radius: 42,
                    showTitle: false,
                  );
                }),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(formatMoney(grand),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- NEW: category comparison bar chart ----------
  Widget _categoryBarCard() {
    final totals = <String, double>{};
    for (final t in transactions) {
      totals.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    if (totals.isEmpty) return const SizedBox.shrink();

    final allEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = allEntries.take(6).toList();
    final maxY =
        top.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.15;

    return _chartCard(
      title: 'Category Comparison',
      subtitle: top.length < allEntries.length
          ? 'Top ${top.length} of ${allEntries.length} categories'
          : '${allEntries.length} categories',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (v, _) => Text(
                    shortNumber(v),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= top.length) {
                      return const SizedBox.shrink();
                    }
                    final cat = top[i].key;
                    final c = _isIncomeCategory(cat)
                        ? AppColors.income
                        : AppColors.expense;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        cat.length > 6 ? '${cat.substring(0, 5)}…' : cat,
                        style: TextStyle(
                          color: c,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(top.length, (i) {
              final cat = top[i].key;
              final c = _isIncomeCategory(cat)
                  ? AppColors.income
                  : AppColors.expense;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].value,
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [c, c.withAlpha(120)],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---------- income vs expense ----------
  Widget _incomeVsExpenseCard(double income, double expense) {
    final maxY = (income > expense ? income : expense) * 1.2;
    return _chartCard(
      title: 'Income vs Expense',
      subtitle: 'Comparison',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY == 0 ? 100 : maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY == 0 ? 25 : maxY / 4,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      v.toInt() == 0 ? 'Income' : 'Expense',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
            barGroups: [
              _bar(0, income, AppColors.income),
              _bar(1, expense, AppColors.expense),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 48,
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withAlpha(120)],
          ),
        ),
      ],
    );
  }

  // ---------- detailed breakdown list ----------
  Widget _categoryList() {
    final totals = <String, double>{};
    for (final t in transactions) {
      totals.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grand = entries.fold<double>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Breakdown',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            final pct = grand == 0 ? 0.0 : e.value / grand;
            final color = AppColors.chartColor(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(categoryIcon(e.key), size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                      ),
                      Text(formatMoney(e.value),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: color.withAlpha(25),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
