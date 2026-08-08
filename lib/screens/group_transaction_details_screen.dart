import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/transaction_model.dart';
import '../providers/currency_provider.dart';
import '../services/transaction_service.dart';
import '../services/notification_service.dart';
import 'transaction_details_screen.dart';
import 'tools/expense_splitter_screen.dart';

class GroupTransactionDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupTransactionDetailsScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupTransactionDetailsScreen> createState() => _GroupTransactionDetailsScreenState();
}

class _GroupTransactionDetailsScreenState extends ConsumerState<GroupTransactionDetailsScreen> {
  void _verifyTransaction(ExpenseTransaction tx) async {
    HapticFeedback.heavyImpact();

    final updatedTx = ExpenseTransaction(
      id: tx.id,
      amount: tx.amount,
      merchant: tx.merchant,
      date: tx.date,
      paymentMethod: tx.paymentMethod,
      category: tx.category,
      notes: tx.notes,
      paidTo: tx.paidTo,
      needsVerification: false,
      reminderDate: null,
      wasFinishLater: true,
      hideFromLedger: tx.hideFromLedger,
      groupId: tx.groupId,
    );

    await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);
    NotificationService.cancelNotification(tx.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt Verified Successfully!'),
          backgroundColor: TallyTapTheme.primaryMint,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getGroupName() {
    final parts = widget.groupId.split('_');
    if (parts.length >= 3) {
      return parts.sublist(2).join('_');
    }
    return "Group Transaction";
  }

  Widget _buildHeaderMetricColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: TallyTapTheme.textGray,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final allTransactions = ref.watch(transactionListProvider);
    final groupTransactions = allTransactions.where((t) => t.groupId == widget.groupId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    ExpenseTransaction? mainTx;
    for (final t in groupTransactions) {
      if (t.id.endsWith('_main') || !t.isIncome) {
        mainTx = t;
        break;
      }
    }
    mainTx ??= groupTransactions.isNotEmpty ? groupTransactions.first : null;

    final isItemizedSplit = mainTx != null && mainTx.notes.contains('Itemized Receipt:');

    List<String> rawReceiptItems = [];
    if (isItemizedSplit && mainTx != null) {
      final receiptData = mainTx.notes.split('Itemized Receipt:\n').last.trim();
      rawReceiptItems = receiptData.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }

    double totalBillAmount = mainTx?.amount ?? 0.0;
    double friendsOweAmount = 0.0;
    for (final tx in groupTransactions) {
      if (tx.isIncome) {
        friendsOweAmount += tx.amount;
      }
    }
    double yourShareAmount = (totalBillAmount - friendsOweAmount);
    if (yourShareAmount < 0) yourShareAmount = 0.0;

    double netAmount = 0.0;
    for (final tx in groupTransactions) {
      final isInc = tx.isIncome;
      netAmount += isInc ? tx.amount : -tx.amount;
    }
    final isNetIncome = netAmount >= 0;
    final displayAmount = netAmount.abs();
    final groupName = _getGroupName();

    return Scaffold(
      backgroundColor: TallyTapTheme.obsidianBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: TallyTapTheme.textLight, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Group Details',
          style: TextStyle(
            color: TallyTapTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: TallyTapTheme.primaryMint, size: 28),
            tooltip: 'Edit Group Split',
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseSplitterScreen(initialGroupId: widget.groupId),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: groupTransactions.isEmpty
            ? const Center(child: Text("No transactions found for this group", style: TextStyle(color: TallyTapTheme.textGray)))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            TallyTapTheme.primaryMint.withOpacity(0.15),
                            TallyTapTheme.primaryMint.withOpacity(0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: TallyTapTheme.primaryMint.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: TallyTapTheme.primaryMint.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: TallyTapTheme.primaryMint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: TallyTapTheme.primaryMint.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group_work_rounded, color: TallyTapTheme.primaryMint, size: 14),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    groupName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: TallyTapTheme.primaryMint,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'NET AMOUNT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: TallyTapTheme.textGray,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isNetIncome ? '+' : '-',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isNetIncome ? const Color(0xFF10B981) : TallyTapTheme.textLight,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                currency,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isNetIncome ? const Color(0xFF10B981) : TallyTapTheme.textLight,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                displayAmount.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: isNetIncome ? const Color(0xFF10B981) : TallyTapTheme.textLight,
                                  height: 1.0,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isItemizedSplit
                                ? '${rawReceiptItems.length} Receipt Items • ${groupTransactions.length} Participants'
                                : '${groupTransactions.length} Participants',
                            style: const TextStyle(fontSize: 12, color: TallyTapTheme.textGray, fontWeight: FontWeight.bold),
                          ),
                          if (isItemizedSplit) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: TallyTapTheme.obsidianBg.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: TallyTapTheme.primaryMint.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildHeaderMetricColumn('Total Bill', '$currency${totalBillAmount.toStringAsFixed(2)}', TallyTapTheme.textLight),
                                  Container(width: 1, height: 24, color: TallyTapTheme.borderGreen),
                                  _buildHeaderMetricColumn('Your Share', '$currency${yourShareAmount.toStringAsFixed(2)}', TallyTapTheme.primaryMint),
                                  Container(width: 1, height: 24, color: TallyTapTheme.borderGreen),
                                  _buildHeaderMetricColumn('Friends Owe', '$currency${friendsOweAmount.toStringAsFixed(2)}', const Color(0xFF10B981)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    if (isItemizedSplit) ...[
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECEIPT DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: TallyTapTheme.textGray,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: TallyTapTheme.primaryMint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: TallyTapTheme.primaryMint.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${rawReceiptItems.length} ITEMS',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TallyTapTheme.primaryMint),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: TallyTapTheme.obsidianCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TallyTapTheme.borderGreen, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: rawReceiptItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final line = entry.value;
                            final parts = line.split(':::');

                            Widget childWidget;
                            if (parts.length != 3) {
                              childWidget = Text(line, style: const TextStyle(color: TallyTapTheme.textLight, fontSize: 13));
                            } else {
                              final itemName = parts[0];
                              final itemPrice = parts[1];
                              final sharedByStr = parts[2];
                              final namesList = sharedByStr.split(', ').map((s) => s.trim()).toList();

                              childWidget = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          itemName,
                                          style: const TextStyle(
                                            color: TallyTapTheme.textLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "$currency$itemPrice",
                                        style: const TextStyle(
                                          color: TallyTapTheme.textLight,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        "Shared by:",
                                        style: TextStyle(color: TallyTapTheme.textGray, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      ...namesList.map((name) {
                                        final isYou = name == "You";
                                        final isUnassigned = name.toLowerCase() == "unassigned";

                                        if (isUnassigned) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF59E0B).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFF59E0B)),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Unassigned",
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isYou
                                                ? TallyTapTheme.primaryMint.withOpacity(0.18)
                                                : TallyTapTheme.primaryMint.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isYou
                                                  ? TallyTapTheme.primaryMint.withOpacity(0.5)
                                                  : TallyTapTheme.primaryMint.withOpacity(0.25),
                                            ),
                                          ),
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isYou ? TallyTapTheme.primaryMint : TallyTapTheme.textLight,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                if (index > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Divider(
                                      color: TallyTapTheme.borderGreen.withOpacity(0.6),
                                      height: 1,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: childWidget,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    
                    const Text(
                      'PARTICIPANTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: TallyTapTheme.textGray,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupTransactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = groupTransactions[index];
                        final isInc = tx.isIncome;
                        final color = isInc ? const Color(0xFF10B981) : TallyTapTheme.textLight;
                        
                        final dateStr = DateFormat('MMM d, y • h:mm a').format(tx.date);
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailsScreen(transaction: tx),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: tx.needsVerification ? const Color(0xFFF59E0B).withOpacity(0.05) : TallyTapTheme.obsidianCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: tx.needsVerification ? const Color(0xFFF59E0B).withOpacity(0.3) : TallyTapTheme.borderGreen,
                                width: 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: TallyTapTheme.getIconBgForCategory(tx.category, isInc),
                                        border: Border.all(color: TallyTapTheme.borderGreen, width: 0.5),
                                      ),
                                      child: Icon(
                                        TallyTapTheme.getIconForCategory(tx.category, isInc),
                                        color: isInc ? const Color(0xFF10B981) : TallyTapTheme.textLight,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.merchant,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: TallyTapTheme.textLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(fontSize: 11, color: TallyTapTheme.textGray),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isInc ? '+' : '-'} $currency${tx.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                        if (tx.needsVerification) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B2314),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFF7A3E14), width: 0.5),
                                            ),
                                            child: const Text(
                                              'Pending',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                if (tx.needsVerification) ...[
                                  const SizedBox(height: 16),
                                  const Divider(color: TallyTapTheme.borderGreen, height: 1),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _verifyTransaction(tx),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: TallyTapTheme.primaryMint,
                                        foregroundColor: TallyTapTheme.obsidianBg,
                                        elevation: 8,
                                        shadowColor: TallyTapTheme.primaryMint.withOpacity(0.4),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                      label: const Text(
                                        'Verify Receipt',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}
