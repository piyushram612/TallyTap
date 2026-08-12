import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/currency_provider.dart';
import '../create_transaction_screen.dart';
import '../widgets/transaction_item.dart';

class DayTransactionsSheet extends ConsumerWidget {
  final DateTime date;

  const DayTransactionsSheet({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final spendMap = ref.watch(dailySpendMapProvider);
    final dayData = spendMap[dateKey];

    final double totalExpense = dayData?.totalExpense ?? 0.0;
    final double totalIncome = dayData?.totalIncome ?? 0.0;
    final transactions = dayData?.transactions ?? [];
    final scheduledRecurring = dayData?.scheduledRecurring ?? [];

    final String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: TriplTheme.obsidianBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: TriplTheme.borderGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: TriplTheme.textLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DAILY REFLECTIONS & SCHEDULING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: TriplTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: TriplTheme.textGray),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daily Totals Metric Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TriplTheme.obsidianCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: TriplTheme.borderGreen, width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL EXPENSE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: TriplTheme.textGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currency${totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: TriplTheme.borderGreen,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL INCOME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: TriplTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currency${totalIncome.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Scheduled Payments Section (if any)
            if (scheduledRecurring.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.autorenew_rounded, color: TriplTheme.primarySlate, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'SCHEDULED BILLS & RECURRING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: TriplTheme.primarySlate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...scheduledRecurring.map((rec) {
                final catColor = TriplTheme.getColorForCategory(rec.category);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: TriplTheme.obsidianCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: catColor.withOpacity(0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: catColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              TriplTheme.getIconForCategory(rec.category),
                              color: catColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: TriplTheme.textLight,
                                ),
                              ),
                              Text(
                                '${rec.category} • ${rec.frequency.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: TriplTheme.textGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TriplTheme.primarySlate.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TriplTheme.primarySlate.withOpacity(0.4), width: 0.5),
                        ),
                        child: Text(
                          '$currency${rec.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: TriplTheme.primarySlate,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Itemized Logged Transactions
            Text(
              'LOGGED TRANSACTIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: TriplTheme.textGray,
              ),
            ),
            const SizedBox(height: 10),

            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 40,
                      color: TriplTheme.textGray.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No transactions logged on this day',
                      style: TextStyle(
                        color: TriplTheme.textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => Divider(
                  color: TriplTheme.borderGreen,
                  height: 16,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final formattedTime = DateFormat('h:mm a').format(tx.date);
                  return TransactionItem(
                    transaction: tx,
                    currency: currency,
                    subtitle: '$formattedTime • ${tx.paymentMethod}',
                  );
                },
              ),

            const SizedBox(height: 24),

            // Quick Log Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTransactionScreen(initialDate: date),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text('LOG EXPENSE FOR ${DateFormat('MMM d').format(date).toUpperCase()}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TriplTheme.primaryMint,
                foregroundColor: TriplTheme.obsidianBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
