import 'package:flutter/material.dart';

import 'analytics_screen.dart';
import 'database_service.dart';
import 'theme.dart';
import 'transaction.dart';
import 'utils/formatters.dart';
import 'widgets/charts_view.dart';

// =============================================================
// DESIGN TOKENS
// =============================================================
const double _kBarHeight   = 60;
const double _kElemHeight  = 36;
const double _kSheetChipH  = 36;
const double _kCardHeight  = 64;
const double _kButtonW     = 104;

const Duration _kQuick  = Duration(milliseconds: 200);
const Duration _kSmooth = Duration(milliseconds: 260);
const Curve    _kOut    = Curves.easeOutCubic;
const Curve    _kIn     = Curves.easeInCubic;

enum TypeFilter { all, income, expense }
enum PeriodFilter { all, today, week, month, custom, customRange }

extension TypeFilterX on TypeFilter {
  String get label => switch (this) {
        TypeFilter.all => 'All',
        TypeFilter.income => 'Income',
        TypeFilter.expense => 'Expense',
      };
  String? get dbValue => switch (this) {
        TypeFilter.all => null,
        TypeFilter.income => 'Income',
        TypeFilter.expense => 'Expense',
      };
}

extension PeriodFilterX on PeriodFilter {
  String get label => switch (this) {
        PeriodFilter.all => 'All time',
        PeriodFilter.today => 'Today',
        PeriodFilter.week => 'Last 7 days',
        PeriodFilter.month => 'Last 30 days',
        PeriodFilter.custom => 'Pick a day',
        PeriodFilter.customRange => 'Date range',
      };

  /// Only presets have a lower bound; custom/customRange use their own fields.
  DateTime? get from {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      PeriodFilter.all => null,
      PeriodFilter.today => today,
      PeriodFilter.week => today.subtract(const Duration(days: 6)),
      PeriodFilter.month => today.subtract(const Duration(days: 29)),
      PeriodFilter.custom => null,
      PeriodFilter.customRange => null,
    };
  }
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TypeFilter _type = TypeFilter.all;
  PeriodFilter _period = PeriodFilter.all;
  DateTime? _customDay;
  DateTime? _customFrom;
  DateTime? _customTo;
  String? _category;
  bool _showCharts = false;

  List<Transaction> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.instance.getTransactions();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  // -------- accent follows the active type --------
  Color get _accent => switch (_type) {
        TypeFilter.income => AppColors.income,
        TypeFilter.expense => AppColors.expense,
        TypeFilter.all => AppColors.primary,
      };

  Gradient get _accentGradient => switch (_type) {
        TypeFilter.income => AppColors.incomeGradient,
        TypeFilter.expense => AppColors.expenseGradient,
        TypeFilter.all => AppColors.primaryGradient,
      };

  // -------- state helpers --------
  bool get _hasRange => _customFrom != null && _customTo != null;

  bool get _hasActiveFilter =>
      _type != TypeFilter.all ||
      _period != PeriodFilter.all ||
      _customDay != null ||
      _hasRange ||
      _category != null;

  int get _activeFilterCount {
    int n = 0;
    if (_type != TypeFilter.all) n++;
    if (_category != null) n++;
    if (_customDay != null || _hasRange || _period != PeriodFilter.all) n++;
    return n;
  }

  List<String> get _categoryChoices {
    switch (_type) {
      case TypeFilter.income:
        return kIncomeCategories;
      case TypeFilter.expense:
        return kExpenseCategories;
      case TypeFilter.all:
        final set = <String>{...kIncomeCategories, ...kExpenseCategories};
        return set.toList()..sort();
    }
  }

  void _setType(TypeFilter t) {
    setState(() {
      _type = t;
      if (_category != null) {
        final allowed = t == TypeFilter.income
            ? kIncomeCategories
            : t == TypeFilter.expense
                ? kExpenseCategories
                : <String>{...kIncomeCategories, ...kExpenseCategories};
        if (!allowed.contains(_category)) _category = null;
      }
    });
  }

  List<Transaction> get _filtered {
    final from = _period.from;
    final rangeStart = _hasRange
        ? DateTime(_customFrom!.year, _customFrom!.month, _customFrom!.day)
        : null;
    final rangeEnd = _hasRange
        ? DateTime(_customTo!.year, _customTo!.month, _customTo!.day,
            23, 59, 59, 999)
        : null;

    return _all.where((t) {
      if (_type.dbValue != null && t.type != _type.dbValue) return false;
      if (_category != null && t.category != _category) return false;

      final d = DateTime.tryParse(t.date);
      if (d == null) return !_hasActiveFilter;

      // Range takes precedence over single day / preset
      if (rangeStart != null && rangeEnd != null) {
        return !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);
      }

      if (_customDay != null) {
        return d.year == _customDay!.year &&
            d.month == _customDay!.month &&
            d.day == _customDay!.day;
      }

      if (from != null && d.isBefore(from)) return false;
      return true;
    }).toList();
  }

  String get _filterSummary {
    if (!_hasActiveFilter) return '';
    final parts = <String>[];
    if (_type != TypeFilter.all) parts.add(_type.label);
    if (_category != null) parts.add(_category!);
    if (_hasRange) {
      parts.add(formatDateRange(_customFrom!, _customTo!));
    } else if (_customDay != null) {
      parts.add(formatDay(_customDay!));
    } else if (_period != PeriodFilter.all) {
      parts.add(_period.label);
    }
    return parts.join(' · ');
  }

  // -------- pickers --------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDay ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a day to view history',
    );
    if (picked == null) return;
    setState(() {
      _customDay = picked;
      _customFrom = null;
      _customTo = null;
      _period = PeriodFilter.custom;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _hasRange
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a date range',
      saveText: 'Apply',
    );
    if (picked == null) return;
    setState(() {
      _customFrom = picked.start;
      _customTo = picked.end;
      _customDay = null;
      _period = PeriodFilter.customRange;
    });
  }

  void _clearFilters() {
    setState(() {
      _type = TypeFilter.all;
      _period = PeriodFilter.all;
      _customDay = null;
      _customFrom = null;
      _customTo = null;
      _category = null;
    });
  }

  Future<void> _delete(Transaction t) async {
    if (t.id == null) return;
    await DatabaseService.instance.deleteTransaction(t.id!);
    final data = await DatabaseService.instance.getTransactions();
    if (!mounted) return;
    setState(() => _all = data);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(
          transactions: _filtered,
          filters: _filterSummary,
        ),
      ),
    );
  }

  // ============================================================
  // build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final f = _filtered;
    final income = f
        .where((t) => t.type == 'Income')
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = f
        .where((t) => t.type == 'Expense')
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: _kQuick,
              child: Icon(
                _showCharts
                    ? Icons.bar_chart_rounded
                    : Icons.bar_chart_outlined,
                key: ValueKey(_showCharts),
              ),
            ),
            tooltip: _showCharts ? 'Hide charts' : 'Show charts',
            onPressed: () => setState(() => _showCharts = !_showCharts),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_full_rounded),
            tooltip: 'Fullscreen analytics',
            onPressed: _openAnalytics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  _filterBar(),
                  const SizedBox(height: 12),
                  _summaryRow(income, expense),
                  AnimatedSize(
                    duration: _kSmooth,
                    curve: _kOut,
                    alignment: Alignment.topCenter,
                    child: _showCharts && f.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ChartsView(transactions: f),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 20),
                  _listHeader(f.length),
                  const SizedBox(height: 8),
                  if (f.isEmpty) _emptyState() else ...f.map(_listItem),
                ],
              ),
            ),
    );
  }

  // ---------- compact filter bar ----------
  Widget _filterBar() {
    return GestureDetector(
      onTap: _openFilterSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _kBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: _kElemHeight,
              height: _kElemHeight,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.tune_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: _kQuick,
                  switchInCurve: _kOut,
                  switchOutCurve: _kIn,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _hasActiveFilter
                      ? SingleChildScrollView(
                          key: ValueKey(_filterSummary),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _miniChips(),
                          ),
                        )
                      : Text(
                          'All transactions',
                          key: const ValueKey('empty'),
                          style: TextStyle(
                            color: AppColors.textSecondary.withAlpha(160),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _filterButton(),
          ],
        ),
      ),
    );
  }

  Widget _filterButton() {
    final active = _hasActiveFilter;
    return AnimatedContainer(
      duration: _kQuick,
      curve: _kOut,
      width: _kButtonW,
      height: _kElemHeight,
      decoration: BoxDecoration(
        gradient: active ? _accentGradient : null,
        color: active ? null : _accent.withAlpha(20),
        borderRadius: BorderRadius.circular(_kElemHeight / 2),
        boxShadow: active ? AppShadows.colored(_accent) : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: _kQuick,
          switchInCurve: _kOut,
          switchOutCurve: _kIn,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: active
              ? Row(
                  key: const ValueKey('active'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(90),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Add filter',
                  key: ValueKey('inactive'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _miniChips() {
    final chips = <Widget>[];
    if (_type != TypeFilter.all) {
      chips.add(_miniChip(
        _type.label,
        _accent,
        () => setState(() => _type = TypeFilter.all),
      ));
    }
    if (_category != null) {
      chips.add(_miniChip(
        _category!,
        _accent,
        () => setState(() => _category = null),
      ));
    }
    if (_hasRange) {
      chips.add(_miniChip(
        formatDateRange(_customFrom!, _customTo!),
        _accent,
        () => setState(() {
          _customFrom = null;
          _customTo = null;
          _period = PeriodFilter.all;
        }),
      ));
    } else if (_customDay != null) {
      chips.add(_miniChip(
        formatDay(_customDay!),
        _accent,
        () => setState(() {
          _customDay = null;
          _period = PeriodFilter.all;
        }),
      ));
    } else if (_period != PeriodFilter.all) {
      chips.add(_miniChip(
        _period.label,
        _accent,
        () => setState(() => _period = PeriodFilter.all),
      ));
    }
    return chips;
  }

  Widget _miniChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      height: _kElemHeight,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(_kElemHeight / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(Icons.close_rounded, size: 14, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- filter sheet ----------
  Future<void> _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _filterSheet(setSheetState),
      ),
    );
  }

  Widget _filterSheet(StateSetter setSheetState) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                if (_hasActiveFilter)
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      setSheetState(() {});
                    },
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetSection('Type'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < TypeFilter.values.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _filterChip(
                            label: TypeFilter.values[i].label,
                            selected: _type == TypeFilter.values[i],
                            onTap: () {
                              _setType(TypeFilter.values[i]);
                              setSheetState(() {});
                            },
                            gradient: _type == TypeFilter.values[i]
                                ? _chipGradient(TypeFilter.values[i])
                                : null,
                            stretch: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sheetSection('Category'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(
                        label: 'All',
                        selected: _category == null,
                        onTap: () {
                          setState(() => _category = null);
                          setSheetState(() {});
                        },
                        gradient:
                            _category == null ? _accentGradient : null,
                      ),
                      ..._categoryChoices.map((c) {
                        final selected = _category == c;
                        return _filterChip(
                          label: c,
                          selected: selected,
                          onTap: () {
                            setState(() => _category = c);
                            setSheetState(() {});
                          },
                          gradient: selected ? _accentGradient : null,
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sheetSection('Period'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._regularPeriodChips(setSheetState),
                      _dayChip(setSheetState),
                      _rangeChip(setSheetState),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetSection(String text) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary.withAlpha(180),
          fontSize: 11,
          letterSpacing: 0.8,
          height: 1.2,
        ),
      );

  List<Widget> _regularPeriodChips(StateSetter setSheetState) {
    const regular = [
      PeriodFilter.all,
      PeriodFilter.today,
      PeriodFilter.week,
      PeriodFilter.month,
    ];
    return regular.map((p) {
      final selected = _period == p && _customDay == null && !_hasRange;
      return _filterChip(
        label: p.label,
        selected: selected,
        onTap: () {
          setState(() {
            _period = p;
            _customDay = null;
            _customFrom = null;
            _customTo = null;
          });
          setSheetState(() {});
        },
        gradient: selected ? AppColors.primaryGradient : null,
      );
    }).toList();
  }

  Widget _dayChip(StateSetter setSheetState) {
    final active = _customDay != null;
    final label = active ? formatDay(_customDay!) : 'Pick a day';
    return _filterChip(
      label: label,
      selected: active,
      onTap: () async {
        await _pickDate();
        setSheetState(() {});
      },
      gradient: active ? AppColors.primaryGradient : null,
      icon: Icons.calendar_today_rounded,
    );
  }

  Widget _rangeChip(StateSetter setSheetState) {
    final active = _hasRange;
    final label = active
        ? formatDateRange(_customFrom!, _customTo!)
        : 'Date range';
    return _filterChip(
      label: label,
      selected: active,
      onTap: () async {
        await _pickDateRange();
        setSheetState(() {});
      },
      gradient: active ? AppColors.primaryGradient : null,
      icon: Icons.date_range_rounded,
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Gradient? gradient,
    IconData? icon,
    bool stretch = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _kQuick,
        curve: _kOut,
        height: _kSheetChipH,
        padding: EdgeInsets.symmetric(horizontal: stretch ? 8 : 14),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          color: selected ? null : AppColors.bg,
          borderRadius: BorderRadius.circular(_kSheetChipH / 2),
        ),
        child: Row(
          mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: stretch
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Gradient _chipGradient(TypeFilter t) {
    return switch (t) {
      TypeFilter.all => AppColors.primaryGradient,
      TypeFilter.income => AppColors.incomeGradient,
      TypeFilter.expense => AppColors.expenseGradient,
    };
  }

  // ---------- summary ----------
  Widget _summaryRow(double income, double expense) {
    return Row(
      children: [
        _statCard('Income', income, AppColors.incomeGradient,
            Icons.trending_up_rounded, AppColors.income),
        const SizedBox(width: 12),
        _statCard('Expense', expense, AppColors.expenseGradient,
            Icons.trending_down_rounded, AppColors.expense),
      ],
    );
  }

  Widget _statCard(
      String label, double value, Gradient g, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: _kCardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: _kElemHeight,
              height: _kElemHeight,
              decoration: BoxDecoration(
                gradient: g,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMoney(value),
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- list ----------
  Widget _listHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('All Transactions',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        Text('$count items',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _emptyState() {
    final message = _hasRange
        ? 'No transactions in the selected range'
        : _customDay != null
            ? 'No transactions on ${formatDay(_customDay!)}'
            : _category != null
                ? 'No transactions in $_category'
                : 'No matching transactions';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
          if (_hasActiveFilter) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Adjust filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _listItem(Transaction t) {
    final isIncome = t.type == 'Income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    final gradient =
        isIncome ? AppColors.incomeGradient : AppColors.expenseGradient;

    return Dismissible(
      key: ValueKey(t.id ?? t.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Delete?'),
                content: Text('Remove "${t.title}"?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.expense),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _delete(t),
      child: Container(
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
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Icon(categoryIcon(t.category),
                    color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${t.category} • ${formatDate(t.date)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text('${isIncome ? '+' : '-'}${formatMoney(t.amount)}',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
