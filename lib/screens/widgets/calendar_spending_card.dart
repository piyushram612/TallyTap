import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/theme.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/tripl_badge.dart';
import '../../widgets/tripl_button.dart';
import '../../widgets/tripl_card.dart';
import '../sheets/day_transactions_sheet.dart';

class CalendarSpendingCard extends ConsumerWidget {
  const CalendarSpendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final focusedMonth = ref.watch(calendarFocusedMonthProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final spendMap = ref.watch(dailySpendMapProvider);
    final avgDailySpend = ref.watch(monthAverageDailySpendProvider);

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return TriplCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Calendar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TriplButton.icon(
                        icon: Icons.chevron_left_rounded,
                        size: 26,
                        onPressed: () {
                          if (viewMode == 'month') {
                            ref.read(calendarFocusedMonthProvider.notifier).state =
                                DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
                          } else {
                            ref.read(calendarFocusedMonthProvider.notifier).state =
                                focusedMonth.subtract(const Duration(days: 7));
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        viewMode == 'week'
                            ? (() {
                                final startOfWeek = focusedMonth.subtract(Duration(days: focusedMonth.weekday - 1));
                                final endOfWeek = startOfWeek.add(const Duration(days: 6));
                                if (startOfWeek.month == endOfWeek.month) {
                                  return "${DateFormat('MMM d').format(startOfWeek)} - ${endOfWeek.day}, ${endOfWeek.year}";
                                }
                                return "${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}";
                              })()
                            : DateFormat('MMMM yyyy').format(focusedMonth),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: context.primaryAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TriplButton.icon(
                        icon: Icons.chevron_right_rounded,
                        size: 26,
                        onPressed: () {
                          if (viewMode == 'month') {
                            ref.read(calendarFocusedMonthProvider.notifier).state =
                                DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
                          } else {
                            ref.read(calendarFocusedMonthProvider.notifier).state =
                                focusedMonth.add(const Duration(days: 7));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // View Mode Toggle (MONTH | WEEK)
              TriplPillToggle<String>(
                options: const ['month', 'week'],
                selectedValue: viewMode,
                labelBuilder: (opt) => opt,
                onSelected: (val) => ref.read(calendarViewModeProvider.notifier).state = val,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Header Labels (Mon - Sun)
          Row(
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: TriplTheme.textGray,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // Calendar Grid (Month or Week)
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < 0) {
                  // Swipe Left -> Next Month or Next Week
                  if (viewMode == 'month') {
                    ref.read(calendarFocusedMonthProvider.notifier).state =
                        DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
                  } else {
                    ref.read(calendarFocusedMonthProvider.notifier).state =
                        focusedMonth.add(const Duration(days: 7));
                  }
                } else if (details.primaryVelocity! > 0) {
                  // Swipe Right -> Previous Month or Previous Week
                  if (viewMode == 'month') {
                    ref.read(calendarFocusedMonthProvider.notifier).state =
                        DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
                  } else {
                    ref.read(calendarFocusedMonthProvider.notifier).state =
                        focusedMonth.subtract(const Duration(days: 7));
                  }
                }
              }
            },
            child: viewMode == 'month'
                ? _buildMonthGrid(context, ref, focusedMonth, spendMap, avgDailySpend, todayStr, currency)
                : _buildWeekGrid(context, ref, focusedMonth, spendMap, avgDailySpend, todayStr, currency),
          ),

          const SizedBox(height: 8),

          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFF10B981), 'Low Spend'),
              const SizedBox(width: 12),
              _buildLegendDot(const Color(0xFFF59E0B), 'Moderate'),
              const SizedBox(width: 12),
              _buildLegendDot(const Color(0xFFEF4444), 'High Spike'),
              const SizedBox(width: 12),
              _buildLegendDot(TriplTheme.primarySlate, 'Scheduled', isDotted: true),
            ],
          ),
          const SizedBox(height: 10),

          // Drag Handle Visual Indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TriplTheme.textGray.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    WidgetRef ref,
    DateTime focusedMonth,
    Map<String, DailySpendData> spendMap,
    double avgDailySpend,
    String todayStr,
    String currency,
  ) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    // Determine weekday offset (Monday = 1, Sunday = 7 -> convert to 0-indexed offset)
    int leadingDays = firstDayOfMonth.weekday - 1;
    final totalCells = ((leadingDays + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.04,
        crossAxisSpacing: 3.0,
        mainAxisSpacing: 3.0,
      ),
      itemBuilder: (context, index) {
        final dayOffset = index - leadingDays;
        final cellDate = DateTime(focusedMonth.year, focusedMonth.month, dayOffset + 1);
        final isCurrentMonth = dayOffset >= 0 && dayOffset < daysInMonth;

        return _buildDayCell(
          context: context,
          ref: ref,
          date: cellDate,
          isCurrentMonth: isCurrentMonth,
          spendMap: spendMap,
          avgDailySpend: avgDailySpend,
          todayStr: todayStr,
          currency: currency,
        );
      },
    );
  }

  Widget _buildWeekGrid(
    BuildContext context,
    WidgetRef ref,
    DateTime focusedMonth,
    Map<String, DailySpendData> spendMap,
    double avgDailySpend,
    String todayStr,
    String currency,
  ) {
    // Show 7 days starting from Monday of the focused date
    final startOfWeek = focusedMonth.subtract(Duration(days: focusedMonth.weekday - 1));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.04,
        crossAxisSpacing: 3.0,
        mainAxisSpacing: 3.0,
      ),
      itemBuilder: (context, index) {
        final cellDate = startOfWeek.add(Duration(days: index));

        return _buildDayCell(
          context: context,
          ref: ref,
          date: cellDate,
          isCurrentMonth: true,
          spendMap: spendMap,
          avgDailySpend: avgDailySpend,
          todayStr: todayStr,
          currency: currency,
        );
      },
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime date,
    required bool isCurrentMonth,
    required Map<String, DailySpendData> spendMap,
    required double avgDailySpend,
    required String todayStr,
    required String currency,
  }) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dayData = spendMap[dateKey];
    final isToday = dateKey == todayStr;

    final double totalExpense = dayData?.totalExpense ?? 0.0;
    final int scheduledCount = dayData?.scheduledRecurring.length ?? 0;

    // Intensity Heatmap Logic
    Color badgeBg = Colors.transparent;
    Color badgeText = TriplTheme.textGray;
    BorderSide cellBorder = BorderSide(color: TriplTheme.borderGreen, width: 0.5);

    if (totalExpense > 0) {
      if (totalExpense > avgDailySpend * 1.5) {
        // High spend spike
        badgeBg = const Color(0xFFEF4444).withOpacity(0.15);
        badgeText = const Color(0xFFEF4444);
        cellBorder = const BorderSide(color: Color(0xFFEF4444), width: 1.0);
      } else if (totalExpense > avgDailySpend * 0.5) {
        // Moderate spend
        badgeBg = const Color(0xFFF59E0B).withOpacity(0.15);
        badgeText = const Color(0xFFF59E0B);
        cellBorder = const BorderSide(color: Color(0xFFF59E0B), width: 0.8);
      } else {
        // Low spend
        badgeBg = const Color(0xFF10B981).withOpacity(0.15);
        badgeText = const Color(0xFF10B981);
        cellBorder = const BorderSide(color: Color(0xFF10B981), width: 0.8);
      }
    }

    if (isToday) {
      cellBorder = BorderSide(color: TriplTheme.primaryMint, width: 1.5);
    }

    // Category Color Micro Dots
    final Set<String> categories = dayData?.transactions.map((t) => t.category).toSet() ?? {};

    return GestureDetector(
      onTap: () {
        ref.read(calendarSelectedDateProvider.notifier).state = date;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DayTransactionsSheet(date: date),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isCurrentMonth
              ? (totalExpense > 0 ? badgeBg : TriplTheme.obsidianBg.withOpacity(0.4))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.fromBorderSide(
            isCurrentMonth ? cellBorder : const BorderSide(color: Colors.transparent),
          ),
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: TriplTheme.primaryMint.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Date number & Scheduled indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.0,
                    fontWeight: isToday || totalExpense > 0 ? FontWeight.w900 : FontWeight.w600,
                    color: !isCurrentMonth
                        ? TriplTheme.textGray.withOpacity(0.3)
                        : (isToday ? TriplTheme.primaryMint : TriplTheme.textLight),
                  ),
                ),
                if (scheduledCount > 0 && isCurrentMonth)
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TriplTheme.primarySlate,
                    ),
                  ),
              ],
            ),

            // Category Micro Dots
            if (categories.isNotEmpty && isCurrentMonth)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: categories.take(3).map((cat) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      width: 3.0,
                      height: 3.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TriplTheme.getColorForCategory(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Daily Spend Amount Pill
            if (totalExpense > 0 && isCurrentMonth)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    child: Text(
                      '$currency${totalExpense.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 7.5,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: badgeText,
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

  Widget _buildLegendDot(Color color, String label, {bool isDotted = false}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: isDotted ? Border.all(color: TriplTheme.textLight, width: 0.8) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: TriplTheme.textGray,
          ),
        ),
      ],
    );
  }
}
