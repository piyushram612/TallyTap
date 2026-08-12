import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/app_state_provider.dart';
import '../providers/budget_alerts_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/transaction_service.dart';
import 'widgets/dashed_border_container.dart';
import 'sheets/manage_budgets_sheet.dart';
import '../services/tutorial_service.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> with SingleTickerProviderStateMixin {
  String? _activeDragCategory;
  Offset _dragStartPos = Offset.zero;
  double _dragStartValue = 0.0;
  final Map<String, double> _localLimits = {};

  late AnimationController _controller;
  late Animation<double> _animation;

  String _selectedIntent = CategoryIntent.essential;

  static const Map<String, Color> _intentColors = {
    CategoryIntent.essential: Color(0xFF4EDEA3),
    CategoryIntent.joyful: Color(0xFF9FB6DF),
    CategoryIntent.avoidable: Color(0xFFFFB5B5),
    CategoryIntent.investments: Color(0xFF8B5CF6),
  };

  static const Map<String, IconData> _intentIcons = {
    CategoryIntent.essential: Icons.shield_outlined,
    CategoryIntent.joyful: Icons.favorite_outline_rounded,
    CategoryIntent.avoidable: Icons.do_not_disturb_alt_outlined,
    CategoryIntent.investments: Icons.trending_up_outlined,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getWeekRangeString() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');
    return '${formatter.format(startOfWeek)} - ${formatter.format(endOfWeek)}';
  }

  String _getMonthString() {
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }

  void _showManageBudgetsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriplTheme.obsidianBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ManageBudgetsSheet(),
    );
  }

  IconData _getIconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('din') || lower.contains('food')) return Icons.local_dining_rounded;
    if (lower.contains('commute') || lower.contains('trans')) return Icons.directions_transit_rounded;
    if (lower.contains('sub')) return Icons.subscriptions_rounded;
    if (lower.contains('util')) return Icons.bolt_rounded;
    if (lower.contains('groc')) return Icons.shopping_basket_rounded;
    if (lower.contains('shop')) return Icons.shopping_bag_rounded;
    if (lower.contains('health')) return Icons.favorite_rounded;
    if (lower.contains('house') || lower.contains('home')) return Icons.home_rounded;
    if (lower.contains('travel')) return Icons.flight_rounded;
    return Icons.category_rounded;
  }

  Color _getColorForCategory(String category, int index) {
    final lower = category.toLowerCase();
    if (lower.contains('din')) return TriplTheme.primaryMint;
    if (lower.contains('commute')) return Colors.orangeAccent;
    if (lower.contains('sub')) return Colors.pinkAccent;
    if (lower.contains('util')) return Colors.lightBlueAccent;
    final palette = [
      TriplTheme.primaryViolet,
      Colors.purpleAccent,
      Colors.yellowAccent,
      Colors.tealAccent,
      Colors.deepOrangeAccent,
    ];
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double bottomPadding = 72.0 + MediaQuery.of(context).padding.bottom + (MediaQuery.of(context).padding.bottom > 0 ? 10.0 : 20.0) + 24.0;

    // Replay entrance animation when switching to the Budgets tab
    ref.listen<int>(activeTabProvider, (previous, next) {
      if (next == 1) {
        _controller.forward(from: 0.0);
      }
    });

    final globalBudget = ref.watch(globalBudgetProvider);
    final budgetLimits = ref.watch(budgetLimitsProvider);
    final currency = ref.watch(currencyProvider);
    final excludedCategories = ref.watch(excludedCategoriesProvider);
    final transactions = ref.watch(transactionListProvider);
    final dashboard = ref.watch(dashboardProvider);
    final spentPerCategory = dashboard.spentPerCategory;
    final intents = ref.watch(categoryIntentsProvider);
    final budgetAlerts = ref.watch(budgetAlertsProvider);
    // Build a lookup map: category → alert severity
    final alertMap = {for (final a in budgetAlerts) a.category: a};

    // Reset/clear local limits when not dragging to keep in sync with provider updates
    if (_activeDragCategory == null) {
      _localLimits.clear();
    }

    final now = DateTime.now();
    
    // Helpers to check period bounds
    bool isDateInCurrentWeek(DateTime date) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return date.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
    }

    bool isDateInCurrentMonth(DateTime date) {
      return date.year == now.year && date.month == now.month;
    }

    // Dynamic calculations for BOTH periods independently
    double weeklySpent = 0.0;
    double monthlySpent = 0.0;

    for (var tx in transactions) {
      if (tx.category.toLowerCase() == 'transfer') continue;
      if (excludedCategories.contains(tx.category)) continue;
      if (!tx.isIncome) {
        if (isDateInCurrentWeek(tx.date)) {
          weeklySpent += tx.amount;
        }
        if (isDateInCurrentMonth(tx.date)) {
          monthlySpent += tx.amount;
        }
      }
    }

    // Overallocation calculation using local limits when dragging, otherwise database limits
    final double totalCategoryBudgets = budgetLimits.entries.fold(0.0, (sum, entry) {
      final cat = entry.key;
      final limit = _localLimits[cat] ?? entry.value;
      return sum + limit;
    });
    final double currentGlobalLimit = globalBudget.amount;
    final bool isOverallocated = totalCategoryBudgets > currentGlobalLimit;
    final double overallocationDelta = totalCategoryBudgets - currentGlobalLimit;

    // Categories list
    final List<String> activeCategories = budgetLimits.keys.toList();

    // Calculate active category counts per intent tab
    final Map<String, int> intentCounts = {
      for (var intent in CategoryIntent.all) intent: 0,
    };
    for (final cat in activeCategories) {
      final intent = intents[cat] ?? CategoryIntent.essential;
      if (intentCounts.containsKey(intent)) {
        intentCounts[intent] = intentCounts[intent]! + 1;
      }
    }

    final List<String> filteredCategories = activeCategories.where((cat) {
      final intent = intents[cat] ?? CategoryIntent.essential;
      return intent == _selectedIntent;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Budgets Hub',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: TriplTheme.primaryMint,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Overview your parameters and adjust allocations directly.',
              style: TextStyle(
                fontSize: 14,
                color: TriplTheme.textGray,
              ),
            ),
            const SizedBox(height: 24),
            
            // 1. Double Global Budgets stack at the top
            Text(
              'GLOBAL LIMITS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: TriplTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Horizontally scrollable Global Budgets list
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return SingleChildScrollView(
                        key: TutorialService.budgetsRingKey,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildGlobalBudgetCard(
                              context: context,
                              title: 'Weekly Budget',
                              spent: weeklySpent,
                              limit: globalBudget.weeklyAmount,
                              period: 'weekly',
                              dateString: _getWeekRangeString(),
                              currency: currency,
                              isActive: globalBudget.period == 'weekly',
                              animationValue: _animation.value,
                              onTap: () {
                                ref.read(globalBudgetProvider.notifier).setPeriod('weekly');
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildGlobalBudgetCard(
                              context: context,
                              title: 'Monthly Budget',
                              spent: monthlySpent,
                              limit: globalBudget.monthlyAmount,
                              period: 'monthly',
                              dateString: _getMonthString(),
                              currency: currency,
                              isActive: globalBudget.period == 'monthly',
                              animationValue: _animation.value,
                              onTap: () {
                                ref.read(globalBudgetProvider.notifier).setPeriod('monthly');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Shifted Adjust budget limits card above
                  DashedBorderContainer(
                    key: TutorialService.budgetsManageKey,
                    child: InkWell(
                      onTap: () => _showManageBudgetsSheet(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: 65,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune_rounded, color: TriplTheme.primaryMint, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'ADJUST BUDGET LIMITS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: TriplTheme.primaryMint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Overallocation Warning Banner
                  if (isOverallocated) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEF4444), width: 1.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category Budgets Overallocated',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: TriplTheme.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'The sum of your category budgets ($currency${totalCategoryBudgets.toStringAsFixed(0)}) exceeds your global limit ($currency${currentGlobalLimit.toStringAsFixed(0)}) by $currency${overallocationDelta.toStringAsFixed(0)}.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: TriplTheme.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Overspending Alerts Banner
                  if (budgetAlerts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  '${budgetAlerts.length} ${budgetAlerts.length == 1 ? 'category is' : 'categories are'} over threshold',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: TriplTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...budgetAlerts.map((alert) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: alert.severity.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        alert.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: TriplTheme.textLight,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: alert.severity.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: alert.severity.color.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        alert.severity == BudgetAlertSeverity.exceeded
                                            ? '+$currency${alert.overspendAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} — ${alert.severity.label}'
                                            : '$currency${alert.remainingAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} left — ${alert.severity.label}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: alert.severity.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // 2. Category Wise Budgets section displayed directly on screen
                  Text(
                    'CATEGORIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: TriplTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (activeCategories.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No categories defined. Configure them in Settings!',
                          style: TextStyle(color: TriplTheme.textGray, fontSize: 13),
                        ),
                      ),
                    )
                  else ...[
                    // Intent tabs row
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: CategoryIntent.all.length,
                        itemBuilder: (context, index) {
                          final intent = CategoryIntent.all[index];
                          final isSelected = _selectedIntent == intent;
                          final count = intentCounts[intent] ?? 0;
                          final color = _intentColors[intent] ?? TriplTheme.primaryMint;
                          final icon = _intentIcons[intent] ?? Icons.shield_outlined;
                          
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedIntent = intent;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withOpacity(0.15) : TriplTheme.obsidianCard,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isSelected ? color.withOpacity(0.5) : TriplTheme.borderGreen,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    color: isSelected ? color : TriplTheme.textGray,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$intent ($count)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                      color: isSelected ? color : TriplTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      key: TutorialService.budgetsEnvelopesListKey,
                      child: filteredCategories.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0),
                              child: Text(
                                'No categories assigned to $_selectedIntent.',
                                style: TextStyle(color: TriplTheme.textGray, fontSize: 13),
                              ),
                            ),
                          )
                        : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: (1.75 / textScale).clamp(1.0, 1.75),
                        ),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final spent = spentPerCategory[cat] ?? 0.0;
                          final limit = _localLimits[cat] ?? budgetLimits[cat] ?? 500.0;
                          final icon = _getIconForCategory(cat);
                          final color = _getColorForCategory(cat, index);
                          final proportion = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                          final isDragging = _activeDragCategory == cat;
                          final alert = alertMap[cat];

                          return GestureDetector(
                            onLongPressStart: (details) {
                              HapticFeedback.heavyImpact();
                              setState(() {
                                _activeDragCategory = cat;
                                _dragStartPos = details.globalPosition;
                                _dragStartValue = limit;
                                _localLimits[cat] = limit;
                              });
                            },
                            onLongPressMoveUpdate: (details) {
                              final double deltaX = details.globalPosition.dx - _dragStartPos.dx;
                              double val = _dragStartValue + (deltaX * 5.0);
                              val = val.clamp(0.0, double.infinity);
                              
                              final roundedVal = (val / 10).round() * 10.0;
                              final oldVal = _localLimits[cat] ?? _dragStartValue;
                              if (oldVal != roundedVal) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _localLimits[cat] = roundedVal;
                                });
                              }
                            },
                            onLongPressEnd: (details) {
                              HapticFeedback.mediumImpact();
                              final finalVal = _localLimits[cat] ?? _dragStartValue;
                              ref.read(budgetLimitsProvider.notifier).setLimit(cat, finalVal);
                              setState(() {
                                _activeDragCategory = null;
                              });
                            },
                            child: _buildCategoryBudgetCard(
                              title: cat,
                              spent: spent,
                              limit: limit,
                              icon: icon,
                              proportion: proportion,
                              progressColor: color,
                              currency: currency,
                              isDragging: isDragging,
                              alertSeverity: alert?.severity,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                    
                  SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetCard({
    required String title,
    required double spent,
    required double limit,
    required IconData icon,
    required double proportion,
    required Color progressColor,
    required String currency,
    required bool isDragging,
    BudgetAlertSeverity? alertSeverity,
  }) {
    final percent = (proportion * 100).toStringAsFixed(0);
    final isExceeded = spent > limit;
    final activeColor = isExceeded ? const Color(0xFFEF4444) : progressColor;

    return Transform.scale(
      scale: isDragging ? 1.04 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDragging ? const Color(0xFF132A22) : TriplTheme.obsidianCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDragging ? TriplTheme.primaryMint : TriplTheme.borderGreen,
            width: isDragging ? 1.5 : 1.0,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: TriplTheme.primaryMint.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isExceeded ? const Color(0xFFEF4444).withOpacity(0.15) : TriplTheme.obsidianBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isExceeded ? const Color(0xFFEF4444).withOpacity(0.5) : TriplTheme.borderGreen, width: 0.5),
                        ),
                        child: Icon(
                          icon,
                          color: isExceeded ? const Color(0xFFEF4444) : TriplTheme.primaryMint,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isExceeded ? const Color(0xFFEF4444) : TriplTheme.textLight,
                              ),
                            ),
                            if (isDragging) ...[
                              const SizedBox(height: 1),
                              Text(
                                'Adjusting...',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: TriplTheme.primaryMint,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Alert severity badge chip
                      if (alertSeverity != null && !isDragging)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: alertSeverity.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: alertSeverity.color.withValues(alpha: 0.5), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(alertSeverity.icon, size: 9, color: alertSeverity.color),
                              const SizedBox(width: 3),
                              Text(
                                alertSeverity.label,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: alertSeverity.color,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isExceeded ? const Color(0xFFEF4444) : TriplTheme.textLight.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      '$currency${spent.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TriplTheme.textLight),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ $currency${limit.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                    style: TextStyle(fontSize: 9, color: TriplTheme.textGray, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                height: 3.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: TriplTheme.borderGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: proportion,
                  child: Container(
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalBudgetCard({
    required BuildContext context,
    required String title,
    required double spent,
    required double limit,
    required String period,
    required String dateString,
    required String currency,
    required bool isActive,
    required double animationValue,
    required VoidCallback onTap,
  }) {
    final double animatedSpent = spent * animationValue;
    final proportion = limit > 0 ? (animatedSpent / limit).clamp(0.0, 1.0) : 0.0;
    final percent = (proportion * 100).toStringAsFixed(0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.82,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TriplTheme.obsidianCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? TriplTheme.primaryMint : TriplTheme.borderGreen,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: TriplTheme.primaryMint.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Circular progress on the left
            SizedBox(
              width: 80,
              height: 80,
              child: Builder(
                builder: (context) {
                  Color ringColor = TriplTheme.textLight;
                  if (proportion >= 0.75) {
                    ringColor = const Color(0xFFEF4444);
                  } else if (proportion >= 0.50) {
                    ringColor = const Color(0xFFF59E0B);
                  }
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(70, 70),
                        painter: _MiniBudgetRingPainter(proportion: proportion),
                      ),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: ringColor,
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
            const SizedBox(width: 16),
            // Details on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: TriplTheme.textGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2B20),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFF144D37)),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: TriplTheme.primaryMint,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateString,
                    style: TextStyle(
                      fontSize: 11,
                      color: TriplTheme.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$currency${animatedSpent.toStringAsFixed(0)} ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: TriplTheme.textLight,
                          ),
                        ),
                        TextSpan(
                          text: '/ $currency${limit.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TriplTheme.textGray,
                          ),
                        ),
                      ],
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
}

class _MiniBudgetRingPainter extends CustomPainter {
  final double proportion;

  _MiniBudgetRingPainter({required this.proportion});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const double strokeWidth = 8.0;

    final Paint trackPaint = Paint()
      ..color = const Color(0xFF14241F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, trackPaint);

    Color progressColor = TriplTheme.primaryMint;
    if (proportion >= 0.75) {
      progressColor = const Color(0xFFEF4444);
    } else if (proportion >= 0.50) {
      progressColor = const Color(0xFFF59E0B);
    }

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double startAngle = -pi / 2;
    final double sweepAngle = proportion * 2 * pi;

    if (sweepAngle > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
