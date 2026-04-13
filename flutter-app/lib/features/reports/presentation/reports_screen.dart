import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedMonthKey;
  String? _highlightedCategoryLabel;

  Future<void> _refresh() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _AnalyticsColors.background,
      body: Stack(
        children: [
          const _AnalyticsBackdrop(),
          SafeArea(
            bottom: false,
            child: expensesAsync.when(
              data: (expenses) {
                final entries = expenses.map(_ExpenseEntry.fromMap).toList()
                  ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

                final monthKeys =
                    entries.map((entry) => entry.monthKey).toSet().toList()
                      ..sort((a, b) => b.compareTo(a));

                if (monthKeys.isEmpty) {
                  monthKeys.add(_monthKey(DateTime.now()));
                }

                final selectedMonthKey = monthKeys.contains(_selectedMonthKey)
                    ? _selectedMonthKey!
                    : monthKeys.first;
                final monthLabel = _formatMonthLabel(selectedMonthKey);
                final selectedEntries = entries
                    .where((entry) => entry.monthKey == selectedMonthKey)
                    .toList();

                final buckets = _analyticsCategories.map((spec) {
                  final transactions = selectedEntries
                      .where((entry) => entry.analyticsCategory == spec.label)
                      .toList();
                  final total = transactions.fold<double>(
                    0,
                    (sum, entry) => sum + entry.amount,
                  );

                  return _AnalyticsBucket(
                    spec: spec,
                    total: total,
                    transactions: transactions,
                  );
                }).toList();

                final totalAmount = buckets.fold<double>(
                  0,
                  (sum, bucket) => sum + bucket.total,
                );
                final nonZeroBuckets = buckets
                    .where((bucket) => bucket.total > 0)
                    .toList();
                final activeLabel = nonZeroBuckets.isNotEmpty
                    ? nonZeroBuckets.any(
                            (bucket) =>
                                bucket.spec.label == _highlightedCategoryLabel,
                          )
                          ? _highlightedCategoryLabel
                          : nonZeroBuckets.first.spec.label
                    : null;
                final groupedBuckets =
                    buckets
                        .where((bucket) => bucket.transactions.isNotEmpty)
                        .toList()
                      ..sort((a, b) {
                        final aActive = a.spec.label == activeLabel;
                        final bActive = b.spec.label == activeLabel;
                        if (aActive != bActive) return aActive ? -1 : 1;
                        return b.total.compareTo(a.total);
                      });

                return RefreshIndicator(
                  color: const Color(0xFF49D6FF),
                  backgroundColor: const Color(0xFF121722),
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      MfSpace.xl,
                      MfSpace.md,
                      MfSpace.xl,
                      132,
                    ),
                    children: [
                      _AnalyticsHeader(
                        canPop: canPop,
                        monthKeys: monthKeys,
                        selectedMonthKey: selectedMonthKey,
                        onBack: () => Navigator.of(context).maybePop(),
                        onMonthChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMonthKey = value;
                          });
                        },
                      ),
                      const SizedBox(height: MfSpace.xl),
                      _AnalyticsChartCard(
                        monthLabel: monthLabel,
                        buckets: buckets,
                        totalAmount: totalAmount,
                        activeLabel: activeLabel,
                        onCategoryTap: (label) {
                          setState(() {
                            _highlightedCategoryLabel = label;
                          });
                        },
                      ),
                      const SizedBox(height: MfSpace.xl),
                      if (groupedBuckets.isEmpty)
                        _EmptyAnalyticsCard(
                          monthLabel: monthLabel,
                          onAddExpense: () {
                            Navigator.of(context).push(
                              LedgerPageRoutes.fadeSlide<void>(
                                const AddExpenseScreen(),
                              ),
                            );
                          },
                        )
                      else ...[
                        Text(
                          'Recent by category',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: MfSpace.md),
                        ...groupedBuckets.map(
                          (bucket) => Padding(
                            padding: const EdgeInsets.only(bottom: MfSpace.md),
                            child: _CategoryGroupCard(
                              bucket: bucket,
                              active: bucket.spec.label == activeLabel,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => _AnalyticsScaffoldState(
                canPop: canPop,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    MfSpace.xl,
                    MfSpace.md,
                    MfSpace.xl,
                    132,
                  ),
                  children: const [
                    _LoadingHeader(),
                    SizedBox(height: MfSpace.xl),
                    _LoadingChartCard(),
                    SizedBox(height: MfSpace.xl),
                    _LoadingTransactions(),
                  ],
                ),
              ),
              error: (error, _) => RefreshIndicator(
                color: const Color(0xFF49D6FF),
                backgroundColor: const Color(0xFF121722),
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    MfSpace.xl,
                    MfSpace.md,
                    MfSpace.xl,
                    132,
                  ),
                  children: [
                    _AnalyticsHeader(
                      canPop: canPop,
                      monthKeys: const [],
                      selectedMonthKey: null,
                      onBack: () => Navigator.of(context).maybePop(),
                      onMonthChanged: (_) {},
                    ),
                    const SizedBox(height: MfSpace.xl),
                    _ErrorAnalyticsCard(message: error.toString()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEntry {
  const _ExpenseEntry({
    required this.amount,
    required this.title,
    required this.description,
    required this.rawCategory,
    required this.analyticsCategory,
    required this.date,
  });

  final double amount;
  final String title;
  final String description;
  final String rawCategory;
  final String analyticsCategory;
  final DateTime? date;

  DateTime get sortDate => date ?? DateTime.fromMillisecondsSinceEpoch(0);
  String get monthKey => _monthKey(date ?? DateTime.now());

  factory _ExpenseEntry.fromMap(Map<String, dynamic> raw) {
    final amount = _expenseAmount(raw['amount']);
    final note = raw['note']?.toString().trim() ?? '';
    final rawCategory = _rawCategory(raw);
    final date = _expenseDate(raw['date']);
    final analyticsCategory = _mapAnalyticsCategory(rawCategory, note: note);
    final title = note.isNotEmpty
        ? note
        : rawCategory.isNotEmpty
        ? rawCategory
        : 'Expense';
    final details = <String>[
      if (note.isNotEmpty && rawCategory.isNotEmpty) rawCategory,
      if (date != null) DateFormat('d MMM').format(date.toLocal()),
    ];

    return _ExpenseEntry(
      amount: amount,
      title: title,
      description: details.isEmpty ? 'Ledger entry' : details.join(' • '),
      rawCategory: rawCategory,
      analyticsCategory: analyticsCategory,
      date: date,
    );
  }
}

class _AnalyticsBucket {
  const _AnalyticsBucket({
    required this.spec,
    required this.total,
    required this.transactions,
  });

  final _AnalyticsCategorySpec spec;
  final double total;
  final List<_ExpenseEntry> transactions;
}

class _AnalyticsCategorySpec {
  const _AnalyticsCategorySpec({
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;

  Color get accent => colors.first;
}

const _analyticsCategories = <_AnalyticsCategorySpec>[
  _AnalyticsCategorySpec(
    label: 'Food',
    icon: Icons.restaurant_rounded,
    colors: [Color(0xFFFFB26B), Color(0xFFFF5E7E)],
  ),
  _AnalyticsCategorySpec(
    label: 'Transport',
    icon: Icons.directions_car_rounded,
    colors: [Color(0xFF67E7FF), Color(0xFF2F7BFF)],
  ),
  _AnalyticsCategorySpec(
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    colors: [Color(0xFFFF8FD8), Color(0xFFFF5C90)],
  ),
  _AnalyticsCategorySpec(
    label: 'Health',
    icon: Icons.favorite_rounded,
    colors: [Color(0xFF63FFCB), Color(0xFF13B773)],
  ),
  _AnalyticsCategorySpec(
    label: 'Education',
    icon: Icons.menu_book_rounded,
    colors: [Color(0xFFFFE36D), Color(0xFFFF9D40)],
  ),
  _AnalyticsCategorySpec(
    label: 'Other',
    icon: Icons.category_rounded,
    colors: [Color(0xFFADB7FF), Color(0xFF6476FF)],
  ),
];

abstract final class _AnalyticsColors {
  static const background = Color(0xFF060910);
  static const backgroundDeep = Color(0xFF0B1020);
  static const panel = Color(0xD9151A24);
  static const panelAlt = Color(0xCC111722);
  static const text = Color(0xFFF4F7FF);
  static const muted = Color(0xFF93A0B8);
  static const border = Color(0x1FFFFFFF);
}

double _expenseAmount(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

DateTime? _expenseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _rawCategory(Map<String, dynamic> expense) {
  final category = expense['category'];
  if (category is Map) {
    final name = category['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
  }

  final categoryName = expense['categoryName']?.toString().trim() ?? '';
  if (categoryName.isNotEmpty) return categoryName;

  return expense['category']?.toString().trim() ?? '';
}

String _mapAnalyticsCategory(String rawCategory, {String? note}) {
  final text = '$rawCategory ${note ?? ''}'.toLowerCase();

  if (_matchesAny(text, const [
    'food',
    'dining',
    'restaurant',
    'cafe',
    'coffee',
    'meal',
    'snack',
    'grocery',
    'groceries',
    'swiggy',
    'zomato',
  ])) {
    return 'Food';
  }

  if (_matchesAny(text, const [
    'transport',
    'travel',
    'fuel',
    'petrol',
    'diesel',
    'uber',
    'ola',
    'metro',
    'bus',
    'train',
    'cab',
    'parking',
    'flight',
    'vehicle',
  ])) {
    return 'Transport';
  }

  if (_matchesAny(text, const [
    'shopping',
    'shop',
    'retail',
    'mall',
    'clothing',
    'fashion',
    'amazon',
    'flipkart',
    'purchase',
    'electronics',
    'gift',
  ])) {
    return 'Shopping';
  }

  if (_matchesAny(text, const [
    'health',
    'medical',
    'doctor',
    'hospital',
    'medicine',
    'pharmacy',
    'clinic',
    'fitness',
    'gym',
    'wellness',
  ])) {
    return 'Health';
  }

  if (_matchesAny(text, const [
    'education',
    'school',
    'college',
    'course',
    'class',
    'tuition',
    'fees',
    'book',
    'learning',
    'exam',
    'study',
  ])) {
    return 'Education';
  }

  return 'Other';
}

bool _matchesAny(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (text.contains(keyword)) return true;
  }
  return false;
}

String _monthKey(DateTime date) => DateFormat('yyyy-MM').format(date.toLocal());

String _formatMonthLabel(String key) {
  final parsed = DateTime.tryParse('$key-01');
  if (parsed == null) return key;
  return DateFormat('MMMM yyyy').format(parsed);
}

String _formatCurrency(num value) {
  final digits = value == value.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: MfCurrency.symbol,
    decimalDigits: digits,
  ).format(value);
}

String _formatExpenseCurrency(num value) => '-${_formatCurrency(value)}';

class _AnalyticsBackdrop extends StatelessWidget {
  const _AnalyticsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _AnalyticsColors.background,
                _AnalyticsColors.backgroundDeep,
                Color(0xFF04060B),
              ],
            ),
          ),
        ),
        _GlowOrb(
          top: -80,
          right: -30,
          size: 230,
          colors: [
            const Color(0xFF49D6FF).withValues(alpha: 0.24),
            const Color(0xFF49D6FF).withValues(alpha: 0),
          ],
        ),
        _GlowOrb(
          top: 120,
          left: -90,
          size: 240,
          colors: [
            const Color(0xFFFF5E7E).withValues(alpha: 0.18),
            const Color(0xFFFF5E7E).withValues(alpha: 0),
          ],
        ),
        _GlowOrb(
          bottom: 90,
          right: -80,
          size: 250,
          colors: [
            const Color(0xFFFFD65C).withValues(alpha: 0.18),
            const Color(0xFFFFD65C).withValues(alpha: 0),
          ],
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.colors,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.canPop,
    required this.monthKeys,
    required this.selectedMonthKey,
    required this.onBack,
    required this.onMonthChanged,
  });

  final bool canPop;
  final List<String> monthKeys;
  final String? selectedMonthKey;
  final VoidCallback onBack;
  final ValueChanged<String?> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canPop) ...[
          _HeaderIconButton(onTap: onBack),
          const SizedBox(width: MfSpace.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense analytics',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                  color: _AnalyticsColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A clean read on this month\'s category mix.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _AnalyticsColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (monthKeys.isNotEmpty && selectedMonthKey != null)
          _MonthSelector(
            monthKeys: monthKeys,
            value: selectedMonthKey!,
            onChanged: onMonthChanged,
          ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _AnalyticsColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _AnalyticsColors.text,
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.monthKeys,
    required this.value,
    required this.onChanged,
  });

  final List<String> monthKeys;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AnalyticsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF121722),
          borderRadius: BorderRadius.circular(18),
          iconEnabledColor: _AnalyticsColors.text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _AnalyticsColors.text,
          ),
          items: monthKeys
              .map(
                (monthKey) => DropdownMenuItem(
                  value: monthKey,
                  child: Text(
                    _formatMonthLabel(monthKey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _AnalyticsColors.border),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_AnalyticsColors.panel, _AnalyticsColors.panelAlt],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(MfSpace.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsScaffoldState extends StatelessWidget {
  const _AnalyticsScaffoldState({required this.canPop, required this.child});

  final bool canPop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MfSpace.xl,
            MfSpace.md,
            MfSpace.xl,
            0,
          ),
          child: _AnalyticsHeader(
            canPop: canPop,
            monthKeys: const [],
            selectedMonthKey: null,
            onBack: () => Navigator.of(context).maybePop(),
            onMonthChanged: (_) {},
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _AnalyticsChartCard extends StatelessWidget {
  const _AnalyticsChartCard({
    required this.monthLabel,
    required this.buckets,
    required this.totalAmount,
    required this.activeLabel,
    required this.onCategoryTap,
  });

  final String monthLabel;
  final List<_AnalyticsBucket> buckets;
  final double totalAmount;
  final String? activeLabel;
  final ValueChanged<String?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final chartBuckets = buckets.where((bucket) => bucket.total > 0).toList();
    _AnalyticsBucket? highlightedBucket;
    if (activeLabel != null) {
      for (final bucket in buckets) {
        if (bucket.spec.label == activeLabel) {
          highlightedBucket = bucket;
          break;
        }
      }
    }

    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category split',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _AnalyticsColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _AnalyticsColors.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (chartBuckets.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _AnalyticsColors.border),
                  ),
                  child: Text(
                    '${chartBuckets.length} categories',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _AnalyticsColors.text,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MfSpace.lg),
          SizedBox(
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (highlightedBucket != null)
                  IgnorePointer(
                    child: Container(
                      width: 236,
                      height: 236,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            highlightedBucket.spec.accent.withValues(
                              alpha: 0.22,
                            ),
                            highlightedBucket.spec.accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                PieChart(
                  duration: MfMotion.medium,
                  curve: MfMotion.curve,
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 4,
                    centerSpaceRadius: 82,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        final touched = response?.touchedSection;
                        if (!event.isInterestedForInteractions ||
                            touched == null ||
                            touched.touchedSectionIndex < 0 ||
                            touched.touchedSectionIndex >=
                                chartBuckets.length) {
                          onCategoryTap(null);
                          return;
                        }
                        onCategoryTap(
                          chartBuckets[touched.touchedSectionIndex].spec.label,
                        );
                      },
                    ),
                    sections: chartBuckets.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                              radius: 72,
                              showTitle: false,
                              borderSide: BorderSide(
                                color: Colors.black.withValues(alpha: 0.08),
                                width: 2,
                              ),
                            ),
                          ]
                        : List.generate(chartBuckets.length, (index) {
                            final bucket = chartBuckets[index];
                            final selected = bucket.spec.label == activeLabel;
                            final share = totalAmount <= 0
                                ? 0.0
                                : (bucket.total / totalAmount) * 100;
                            return PieChartSectionData(
                              value: bucket.total,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: bucket.spec.colors,
                              ),
                              radius: selected ? 88 : 76,
                              title: share >= 9 ? '${share.round()}%' : '',
                              titlePositionPercentageOffset: 0.62,
                              titleStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A0D13),
                                width: 2,
                              ),
                            );
                          }),
                  ),
                ),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total expenses',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(totalAmount),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -1.1,
                          color: _AnalyticsColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chartBuckets.isEmpty
                            ? 'No spend recorded'
                            : activeLabel ?? monthLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 560 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: buckets.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: MfSpace.md,
                  mainAxisSpacing: MfSpace.md,
                  childAspectRatio: 1.85,
                ),
                itemBuilder: (context, index) {
                  final bucket = buckets[index];
                  final share = totalAmount <= 0
                      ? 0.0
                      : (bucket.total / totalAmount) * 100;
                  return _LegendCard(
                    bucket: bucket,
                    share: share,
                    active: bucket.spec.label == activeLabel,
                    onTap: () => onCategoryTap(bucket.spec.label),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard({
    required this.bucket,
    required this.share,
    required this.active,
    required this.onTap,
  });

  final _AnalyticsBucket bucket;
  final double share;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MfMotion.medium,
      curve: MfMotion.curve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bucket.spec.accent.withValues(alpha: active ? 0.28 : 0.14),
            const Color(0xFF131925).withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: active
              ? bucket.spec.accent.withValues(alpha: 0.42)
              : _AnalyticsColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(MfSpace.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: bucket.spec.colors),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(bucket.spec.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: MfSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bucket.spec.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _AnalyticsColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(bucket.total),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MfSpace.sm),
                Text(
                  bucket.total <= 0 ? '--' : '${share.round()}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: bucket.spec.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGroupCard extends StatelessWidget {
  const _CategoryGroupCard({required this.bucket, required this.active});

  final _AnalyticsBucket bucket;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = bucket.transactions.length > 3
        ? bucket.transactions.sublist(0, 3)
        : bucket.transactions;

    return AnimatedContainer(
      duration: MfMotion.medium,
      curve: MfMotion.curve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bucket.spec.accent.withValues(alpha: active ? 0.22 : 0.12),
            const Color(0xFF121722).withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: active
              ? bucket.spec.accent.withValues(alpha: 0.38)
              : _AnalyticsColors.border,
        ),
        boxShadow: [
          if (active)
            BoxShadow(
              color: bucket.spec.accent.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MfSpace.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: bucket.spec.colors),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(bucket.spec.icon, color: Colors.white),
                ),
                const SizedBox(width: MfSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bucket.spec.label,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _AnalyticsColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bucket.transactions.length} recent transaction${bucket.transactions.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _AnalyticsColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MfSpace.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bucket.spec.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatCurrency(bucket.total),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: bucket.spec.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MfSpace.md),
            ...List.generate(
              visibleTransactions.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == visibleTransactions.length - 1
                      ? 0
                      : MfSpace.md,
                ),
                child: _TransactionRow(
                  entry: visibleTransactions[index],
                  spec: bucket.spec,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.entry, required this.spec});

  final _ExpenseEntry entry;
  final _AnalyticsCategorySpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MfSpace.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: spec.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(spec.icon, color: spec.accent, size: 20),
          ),
          const SizedBox(width: MfSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _AnalyticsColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _AnalyticsColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MfSpace.md),
          Text(
            _formatExpenseCurrency(entry.amount),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: spec.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.monthLabel,
    required this.onAddExpense,
  });

  final String monthLabel;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF49D6FF).withValues(alpha: 0.24),
                  const Color(0xFFFF8FD8).withValues(alpha: 0.24),
                ],
              ),
            ),
            child: const Icon(
              Icons.pie_chart_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'No expenses in $monthLabel',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'Add a few transactions to light up the chart.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          FilledButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add expense'),
          ),
        ],
      ),
    );
  }
}

class _ErrorAnalyticsCard extends StatelessWidget {
  const _ErrorAnalyticsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E7E).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF8DA2),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'Analytics unavailable',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 220,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 170,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 132,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}

class _LoadingChartCard extends StatelessWidget {
  const _LoadingChartCard();

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsPanel(
      child: SizedBox(
        height: 520,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF49D6FF)),
        ),
      ),
    );
  }
}

class _LoadingTransactions extends StatelessWidget {
  const _LoadingTransactions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : MfSpace.md),
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _AnalyticsColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
