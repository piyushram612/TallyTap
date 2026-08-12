import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import 'dart:ui';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tutorial_service.dart';
import '../../providers/tutorial_provider.dart';

class ManageBudgetsSheet extends ConsumerStatefulWidget {
  const ManageBudgetsSheet({super.key});

  @override
  ConsumerState<ManageBudgetsSheet> createState() => _ManageBudgetsSheetState();
}

class _ManageBudgetsSheetState extends ConsumerState<ManageBudgetsSheet> {
  final TextEditingController _globalLimitController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};
  String _globalPeriod = 'monthly';

  String? _activeDragCategory;
  Offset _dragStartPos = Offset.zero;
  double _dragStartValue = 0.0;
  TutorialCoachMark? tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoriesListProvider);
      final limits = ref.read(budgetLimitsProvider);
      
      for (final cat in categories) {
        _categoryControllers[cat] = TextEditingController(
          text: (limits[cat] ?? 500.0).toStringAsFixed(0),
        );
      }
      
      final globalBudget = ref.read(globalBudgetProvider);
      setState(() {
        _globalPeriod = globalBudget.period;
        if (_globalPeriod == 'monthly') {
          _globalLimitController.text = globalBudget.monthlyAmount.toStringAsFixed(0);
        } else {
          _globalLimitController.text = globalBudget.weeklyAmount.toStringAsFixed(0);
        }
      });
      _checkTutorialStatus();
    });
  }

  @override
  void dispose() {
    _globalLimitController.dispose();
    for (final ctrl in _categoryControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
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

  void _onPeriodSelected(String period) {
    final globalBudget = ref.read(globalBudgetProvider);
    setState(() {
      _globalPeriod = period;
      if (period == 'monthly') {
        _globalLimitController.text = globalBudget.monthlyAmount.toStringAsFixed(0);
      } else {
        _globalLimitController.text = globalBudget.weeklyAmount.toStringAsFixed(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesListProvider);
    final currency = ref.watch(currencyProvider);
    final excludedCategories = ref.watch(excludedCategoriesProvider);
    final visibilities = ref.watch(categoryVisibilityProvider);
    final expenseCategories = categories.where((cat) => visibilities[cat] != CategoryVisibility.income).toList();

    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: topPadding > 0 ? topPadding + 32 : 36,
        bottom: keyboardPadding > 0
            ? keyboardPadding + 16
            : (bottomPadding > 0 ? bottomPadding + 12 : 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adjust Budgets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: TriplTheme.primaryMint,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: TriplTheme.textGray),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'BUDGET PERIOD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: TriplTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onPeriodSelected('monthly'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _globalPeriod == 'monthly' ? TriplTheme.primaryMint.withOpacity(0.15) : TriplTheme.obsidianCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _globalPeriod == 'monthly' ? TriplTheme.primaryMint.withOpacity(0.5) : TriplTheme.borderGreen,
                                width: _globalPeriod == 'monthly' ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_globalPeriod == 'monthly') ...[
                                  Icon(Icons.check_rounded, color: TriplTheme.primaryMint, size: 16),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  'Monthly',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _globalPeriod == 'monthly' ? TriplTheme.primaryMint : TriplTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onPeriodSelected('weekly'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _globalPeriod == 'weekly' ? TriplTheme.primaryMint.withOpacity(0.15) : TriplTheme.obsidianCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _globalPeriod == 'weekly' ? TriplTheme.primaryMint.withOpacity(0.5) : TriplTheme.borderGreen,
                                width: _globalPeriod == 'weekly' ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_globalPeriod == 'weekly') ...[
                                  Icon(Icons.check_rounded, color: TriplTheme.primaryMint, size: 16),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  'Weekly',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _globalPeriod == 'weekly' ? TriplTheme.primaryMint : TriplTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'BUDGET LIMIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: TriplTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    key: TutorialService.adjustBudgetGlobalKey,
                    child: TextField(
                      controller: _globalLimitController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter overall limit (e.g. 2000)',
                      hintStyle: TextStyle(color: TriplTheme.textGray),
                      prefixText: '$currency ',
                      prefixStyle: TextStyle(color: TriplTheme.primaryMint, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: TriplTheme.obsidianCard,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: TriplTheme.borderGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: TriplTheme.primaryMint, width: 1.5),
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'CATEGORY BUDGETS (OPTIONAL)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: TriplTheme.textGray,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: Icon(Icons.clear_all_rounded, size: 14, color: TriplTheme.primaryMint),
                        label: Text(
                          'SET ALL TO ZERO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: TriplTheme.primaryMint,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            for (final ctrl in _categoryControllers.values) {
                              ctrl.text = '0';
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Optionally assign budgets to individual categories below. Leave blank to skip.',
                    style: TextStyle(
                      fontSize: 12,
                      color: TriplTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Live Allocation Tracker inside Wizard
                  Consumer(
                    builder: (context, ref, child) {
                      final excludedCategories = ref.watch(excludedCategoriesProvider);
                      double totalAllocated = 0.0;
                      for (final cat in expenseCategories) {
                        final ctrl = _categoryControllers[cat];
                        if (ctrl != null && !excludedCategories.contains(cat)) {
                          totalAllocated += double.tryParse(ctrl.text) ?? 0.0;
                        }
                      }
                      final double globalLimit = double.tryParse(_globalLimitController.text) ?? 0.0;
                      final bool isOverallocated = totalAllocated > globalLimit;
                      final double delta = (totalAllocated - globalLimit).abs();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOverallocated ? const Color(0xFFEF4444).withOpacity(0.15) : TriplTheme.primaryMint.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOverallocated ? const Color(0xFFEF4444) : TriplTheme.primaryMint,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isOverallocated ? '⚠️ OVERALLOCATED' : 'ALLOCATION TRACKER',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: isOverallocated ? const Color(0xFFEF4444) : TriplTheme.primaryMint,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '$currency${totalAllocated.toStringAsFixed(0)} / $currency${globalLimit.toStringAsFixed(0)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isOverallocated ? const Color(0xFFEF4444) : TriplTheme.primaryMint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isOverallocated
                                  ? 'Your category budgets exceed your global limit by $currency${delta.toStringAsFixed(0)}. Consider reducing them.'
                                  : 'You have $currency${(globalLimit - totalAllocated).toStringAsFixed(0)} remaining to distribute across categories.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: TriplTheme.textLight,
                                ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (expenseCategories.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No categories defined. Add some in Settings!',
                        style: TextStyle(color: TriplTheme.textGray, fontSize: 13),
                      ),
                    )
                  else
                    ...expenseCategories.map((cat) {
                      final ctrl = _categoryControllers[cat] ??= TextEditingController();
                      final isDragging = _activeDragCategory == cat;
                      final isExcluded = excludedCategories.contains(cat);
                      
                      return GestureDetector(
                        key: expenseCategories.indexOf(cat) == 0 ? TutorialService.adjustBudgetCategoryKey : null,
                        onLongPressStart: isExcluded ? null : (details) {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _activeDragCategory = cat;
                            _dragStartPos = details.globalPosition;
                            _dragStartValue = double.tryParse(ctrl.text) ?? 0.0;
                          });
                        },
                        onLongPressMoveUpdate: isExcluded ? null : (details) {
                          final double deltaX = details.globalPosition.dx - _dragStartPos.dx;
                          double val = _dragStartValue + (deltaX * 5.0);
                          val = val.clamp(0.0, double.infinity);
                          
                          final oldValStr = ctrl.text;
                          final newValStr = val.toStringAsFixed(0);
                          if (oldValStr != newValStr) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              ctrl.text = newValStr;
                            });
                          }
                        },
                        onLongPressEnd: isExcluded ? null : (details) {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _activeDragCategory = null;
                          });
                        },
                        child: Transform.scale(
                          scale: isDragging ? 1.04 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            decoration: BoxDecoration(
                              color: isDragging ? const Color(0xFF132A22) : TriplTheme.obsidianCard,
                              borderRadius: BorderRadius.circular(16),
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
                            child: Row(
                              children: [
                                Checkbox(
                                  value: !isExcluded,
                                  activeColor: TriplTheme.primaryMint,
                                  checkColor: TriplTheme.obsidianBg,
                                  onChanged: (val) {
                                    HapticFeedback.selectionClick();
                                    ref.read(excludedCategoriesProvider.notifier).toggleExclusion(cat);
                                    ref.read(budgetLimitsProvider.notifier).loadLimits();
                                  },
                                ),
                                const SizedBox(width: 4),
                                Opacity(
                                  opacity: isExcluded ? 0.4 : 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: TriplTheme.obsidianBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: TriplTheme.borderGreen, width: 0.5),
                                    ),
                                    child: Icon(
                                      _getIconForCategory(cat),
                                      color: TriplTheme.primaryMint,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Opacity(
                                    opacity: isExcluded ? 0.4 : 1.0,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: TriplTheme.textLight,
                                          ),
                                        ),
                                        if (isDragging && !isExcluded) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '← Drag left/right to adjust →',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: TriplTheme.primaryMint,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 100,
                                  height: 42,
                                  child: Opacity(
                                    opacity: isExcluded ? 0.4 : 1.0,
                                    child: TextField(
                                      controller: ctrl,
                                      enabled: !isExcluded,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: TriplTheme.textLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 500',
                                        hintStyle: TextStyle(color: TriplTheme.textGray, fontSize: 12),
                                        prefixText: currency,
                                        prefixStyle: TextStyle(
                                          color: TriplTheme.primaryMint,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        filled: true,
                                        fillColor: TriplTheme.obsidianCard,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: TriplTheme.borderGreen),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: TriplTheme.primaryMint, width: 1.2),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: TriplTheme.borderGreen, width: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final double? limit = double.tryParse(_globalLimitController.text);
                    if (limit != null && limit >= 0) {
                      ref.read(globalBudgetProvider.notifier).setGlobalBudget(limit, _globalPeriod);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Global $_globalPeriod budget set to $currency${limit.toStringAsFixed(0)}! Categories skipped.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: TriplTheme.obsidianBg),
                          ),
                          backgroundColor: TriplTheme.primaryMint,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: TriplTheme.borderGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'SKIP & SAVE',
                    style: TextStyle(
                      color: TriplTheme.primaryMint,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final double? limit = double.tryParse(_globalLimitController.text);
                    if (limit != null && limit >= 0) {
                      // 1. Save global budget
                      ref.read(globalBudgetProvider.notifier).setGlobalBudget(limit, _globalPeriod);
                      
                      // 2. Save entered category budgets
                      final Map<String, double> categoryBudgetsToSave = {};
                      for (final cat in expenseCategories) {
                        final ctrl = _categoryControllers[cat];
                        if (ctrl != null && ctrl.text.isNotEmpty) {
                          final double? catLimit = double.tryParse(ctrl.text);
                          if (catLimit != null && catLimit >= 0) {
                            categoryBudgetsToSave[cat] = catLimit;
                          }
                        }
                      }
                      
                      if (categoryBudgetsToSave.isNotEmpty) {
                        ref.read(budgetLimitsProvider.notifier).setMultipleLimits(categoryBudgetsToSave);
                      }
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Global $_globalPeriod budget and category budgets saved!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: TriplTheme.obsidianBg),
                          ),
                          backgroundColor: TriplTheme.primaryMint,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TriplTheme.primaryMint,
                    foregroundColor: TriplTheme.obsidianBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SAVE ALL',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(kPrefTutorialAdjustBudget) ?? false;
    if (!hasSeen && mounted) {
      _initTutorial();
    }
  }

  void _initTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.6,
      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      beforeFocus: (target) async {
        if (target.keyTarget?.currentContext != null) {
          Scrollable.ensureVisible(
            target.keyTarget!.currentContext!,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          await Future.delayed(const Duration(milliseconds: 350));
        }
      },
      onClickOverlay: (target) {
        tutorialCoachMark?.next();
      },
      onFinish: () {
        if (!mounted) return;
        ref.read(tutorialProvider.notifier).markCompleted(kPrefTutorialAdjustBudget);
      },
      onSkip: () {
        if (!mounted) return true;
        ref.read(tutorialProvider.notifier).markCompleted(kPrefTutorialAdjustBudget);
        return true;
      },
    );
    tutorialCoachMark?.show(context: context);
  }

  Widget _buildTutorialContent(TutorialCoachMarkController controller, String title, String description, {String nextText = "Next"}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        const SizedBox(height: 10),
        Text(description, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => controller.next(),
            style: ElevatedButton.styleFrom(
              backgroundColor: TriplTheme.primaryMint,
              foregroundColor: TriplTheme.obsidianBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(nextText),
          ),
        ),
      ],
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    targets.add(TargetFocus(
      identify: "TargetGlobalBudget",
      keyTarget: TutorialService.adjustBudgetGlobalKey,
      alignSkip: Alignment.topRight,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => _buildTutorialContent(controller, "Global Budget", "Set your overall spending limit for the selected period here."),
        ),
      ],
    ));

    targets.add(TargetFocus(
      identify: "TargetCategoryLimits",
      keyTarget: TutorialService.adjustBudgetCategoryKey,
      alignSkip: Alignment.topRight,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => _buildTutorialContent(controller, "Category Limits", "Long-press and drag horizontally on any category card to quickly adjust its individual budget limit.", nextText: "Finish"),
        ),
      ],
    ));

    return targets;
  }
}
