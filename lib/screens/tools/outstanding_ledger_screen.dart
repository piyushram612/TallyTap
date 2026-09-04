import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/math_evaluator.dart';
import '../../models/outstanding_model.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../providers/outstanding_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/notification_service.dart';
import 'dart:ui';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tutorial_service.dart';
import '../../providers/tutorial_provider.dart';

class OutstandingLedgerScreen extends ConsumerStatefulWidget {
  const OutstandingLedgerScreen({super.key});

  @override
  ConsumerState<OutstandingLedgerScreen> createState() => _OutstandingLedgerScreenState();
}

class _OutstandingLedgerScreenState extends ConsumerState<OutstandingLedgerScreen> {
  String _activeFilter = 'Active'; // 'Active', 'Settled', 'All'
  final Set<String> _expandedPersons = {};
  TutorialCoachMark? tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorialStatus();
    });
  }

  void _togglePersonExpanded(String person) {
    setState(() {
      if (_expandedPersons.contains(person)) {
        _expandedPersons.remove(person);
      } else {
        _expandedPersons.add(person);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(combinedOutstandingProvider);
    final currency = ref.watch(currencyProvider);
    final sources = ref.watch(sourcesListProvider);

    // Calculate dynamic totals of ACTIVE outstanding entries
    double theyOweMe = 0.0;
    double iOweThem = 0.0;

    for (final r in records) {
      if (!r.isSettled) {
        if (r.isLent) {
          theyOweMe += r.amount;
        } else {
          iOweThem += r.amount;
        }
      }
    }

    final double netBalance = theyOweMe - iOweThem;

    // Filter records
    final List<OutstandingRecord> filteredRecords;
    if (_activeFilter == 'Active') {
      filteredRecords = records.where((r) => !r.isSettled).toList();
    } else if (_activeFilter == 'Settled') {
      filteredRecords = records.where((r) => r.isSettled).toList();
    } else {
      filteredRecords = records;
    }

    // Group records by Person Name
    final Map<String, List<OutstandingRecord>> personGroups = {};
    for (final r in filteredRecords) {
      personGroups.putIfAbsent(r.personName, () => []).add(r);
    }

    // Sort persons by net active balance
    final List<String> sortedPersons = personGroups.keys.toList()
      ..sort((a, b) {
        double netA = 0.0;
        for (final r in personGroups[a]!) {
          if (!r.isSettled) netA += r.isLent ? r.amount : -r.amount;
        }
        double netB = 0.0;
        for (final r in personGroups[b]!) {
          if (!r.isSettled) netB += r.isLent ? r.amount : -r.amount;
        }
        return netB.abs().compareTo(netA.abs()); // Sort by largest absolute outstanding debt
      });

    return Scaffold(
      backgroundColor: TriplTheme.obsidianBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TriplTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Outstanding Ledger',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: TriplTheme.textLight,
            fontFamily: 'Outfit',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TriplTheme.obsidianCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: TriplTheme.borderGreen),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          key: TutorialService.ledgerWhoOwesMeKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THEY OWE ME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: TriplTheme.textGray,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$currency${theyOweMe.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: TriplTheme.primaryMint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: TriplTheme.borderGreen,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          key: TutorialService.ledgerWhoIOweKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I OWE THEM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: TriplTheme.textGray,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$currency${iOweThem.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: TriplTheme.borderGreen, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NET OUTSTANDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: TriplTheme.textGray,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          netBalance >= 0
                              ? '+ $currency${netBalance.toStringAsFixed(2)}'
                              : '- $currency${netBalance.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: netBalance >= 0 ? TriplTheme.primaryMint : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Segmented Filters View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: TriplTheme.obsidianCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TriplTheme.borderGreen),
                ),
                child: Row(
                  children: ['Active', 'Settled', 'All'].map((tab) {
                    final isSel = _activeFilter == tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _activeFilter = tab;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? TriplTheme.primaryMint : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tab.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isSel ? TriplTheme.obsidianBg : TriplTheme.textGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Main Ledger List View
            Expanded(
              child: sortedPersons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: TriplTheme.textGray.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $_activeFilter Records Found',
                            style: TextStyle(
                              color: TriplTheme.textGray,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      itemCount: sortedPersons.length,
                      itemBuilder: (context, index) {
                        final person = sortedPersons[index];
                        final items = personGroups[person]!;
                        final isExp = _expandedPersons.contains(person);

                        // Calculate net outstanding for this person
                        double netPerson = 0.0;
                        int activeCount = 0;
                        for (final r in items) {
                          if (!r.isSettled) {
                            activeCount++;
                            netPerson += r.isLent ? r.amount : -r.amount;
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              ListTile(
                                onTap: () => _togglePersonExpanded(person),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: netPerson >= 0
                                      ? TriplTheme.primaryMint.withOpacity(0.12)
                                      : const Color(0xFFF59E0B).withOpacity(0.12),
                                  child: Text(
                                    person.isNotEmpty ? person[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: netPerson >= 0 ? TriplTheme.primaryMint : const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  person,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: TriplTheme.textLight,
                                  ),
                                ),
                                subtitle: Text(
                                  activeCount == 0
                                      ? 'All settled up'
                                      : '$activeCount active logs',
                                  style: TextStyle(fontSize: 12, color: TriplTheme.textGray),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          netPerson == 0
                                              ? 'Settled'
                                              : netPerson > 0
                                                  ? 'Owes you'
                                                  : 'You owe',
                                          style: TextStyle(fontSize: 9, color: TriplTheme.textGray, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          netPerson == 0
                                              ? '${currency}0'
                                              : '$currency${netPerson.abs().toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: netPerson == 0
                                                ? TriplTheme.textGray
                                                : netPerson > 0
                                                    ? TriplTheme.primaryMint
                                                    : const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: TriplTheme.textGray,
                                    ),
                                  ],
                                ),
                              ),

                              // Expanded nested details log
                              if (isExp) ...[
                                Divider(color: TriplTheme.borderGreen, height: 1),
                                Container(
                                  color: Colors.black.withOpacity(0.12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Column(
                                    children: [
                                      ...items.map((r) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                r.isSettled
                                                    ? Icons.check_circle_outline_rounded
                                                    : r.isLent
                                                        ? Icons.arrow_upward_rounded
                                                        : Icons.arrow_downward_rounded,
                                                color: r.isSettled
                                                    ? TriplTheme.textGray
                                                    : r.isLent
                                                        ? TriplTheme.primaryMint
                                                        : const Color(0xFFF59E0B),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      r.notes.isNotEmpty ? r.notes : (r.isLent ? 'Lent money' : 'Borrowed money'),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: r.isSettled ? TriplTheme.textGray : TriplTheme.textLight,
                                                        decoration: r.isSettled ? TextDecoration.lineThrough : null,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${r.date.day}/${r.date.month}/${r.date.year}',
                                                      style: TextStyle(fontSize: 10, color: TriplTheme.textGray),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '$currency${r.amount.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: r.isSettled
                                                          ? TriplTheme.textGray
                                                          : r.isLent
                                                              ? TriplTheme.primaryMint
                                                              : const Color(0xFFF59E0B),
                                                      decoration: r.isSettled ? TextDecoration.lineThrough : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (!r.isSettled)
                                                    IconButton(
                                                      icon: Icon(Icons.check_rounded, color: TriplTheme.primaryMint, size: 18),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        HapticFeedback.lightImpact();
                                                        _showSettleDialog(context, r);
                                                      },
                                                    )
                                                  else
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        HapticFeedback.lightImpact();
                                                        final allTx = ref.read(transactionListProvider);
                                                        final isSynth = allTx.any((t) => t.id == r.id && t.wasFinishLater);
                                                        if (isSynth) {
                                                          final tx = allTx.firstWhere((t) => t.id == r.id);
                                                          final updatedTx = tx.copyWith(
                                                            hideFromLedger: true,
                                                          );
                                                          ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);
                                                        } else {
                                                          ref.read(outstandingListProvider.notifier).deleteRecord(r.id);
                                                        }
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),

                                      // Settle Balance CTAs
                                      if (netPerson != 0) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: netPerson > 0 ? TriplTheme.primaryMint : const Color(0xFFF59E0B),
                                                  foregroundColor: TriplTheme.obsidianBg,
                                                  minimumSize: const Size.fromHeight(40),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.handshake_rounded, size: 16),
                                                label: Text(
                                                  'Settle Net ($currency${netPerson.abs().toStringAsFixed(0)})',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                onPressed: () {
                                                  HapticFeedback.mediumImpact();
                                                  _showSettleNetDialog(
                                                    context,
                                                    person,
                                                    netPerson,
                                                    items.where((r) => !r.isSettled).toList(),
                                                    initialPartial: false,
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: netPerson > 0 ? TriplTheme.primaryMint : const Color(0xFFF59E0B),
                                                  side: BorderSide(
                                                    color: (netPerson > 0 ? TriplTheme.primaryMint : const Color(0xFFF59E0B)).withOpacity(0.5),
                                                    width: 1.2,
                                                  ),
                                                  minimumSize: const Size.fromHeight(40),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.pie_chart_outline_rounded, size: 15),
                                                label: const Text(
                                                  'Partial',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                onPressed: () {
                                                  HapticFeedback.mediumImpact();
                                                  _showSettleNetDialog(
                                                    context,
                                                    person,
                                                    netPerson,
                                                    items.where((r) => !r.isSettled).toList(),
                                                    initialPartial: true,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TriplTheme.primaryMint,
        foregroundColor: TriplTheme.obsidianBg,
        shape: const CircleBorder(),
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddIOUSheet(context, sources);
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // Settle Single Debt Dialog
  void _showSettleDialog(BuildContext context, OutstandingRecord record) {
    bool recordTimelineTx = true;
    final allTx = ref.read(transactionListProvider);
    final isSynth = allTx.any((t) => t.id == record.id && t.wasFinishLater);
    ExpenseTransaction? synthTx;
    if (isSynth) {
      synthTx = allTx.firstWhere((t) => t.id == record.id);
    }

    String selectedSource = synthTx?.paymentMethod ?? 'Cash';
    final sources = ref.read(sourcesListProvider);
    if (synthTx != null && synthTx.paymentMethod.isNotEmpty && sources.contains(synthTx.paymentMethod)) {
      selectedSource = synthTx.paymentMethod;
    } else if (!sources.contains(selectedSource)) {
      selectedSource = sources.isNotEmpty ? sources.first : 'Cash';
    }

    bool isPartial = false;
    final partialController = TextEditingController();
    final currency = ref.read(currencyProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final partialVal = MathEvaluator.tryParseAmount(partialController.text) ?? 0.0;
          final remaining = (record.amount - partialVal).clamp(0.0, record.amount);

          return AlertDialog(
            backgroundColor: TriplTheme.obsidianCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: TriplTheme.borderGreen, width: 1.5),
            ),
            title: Text(
              record.isLent ? 'Settle Lent Balance' : 'Settle Owed Balance',
              style: TextStyle(color: TriplTheme.primaryMint, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full vs Partial Tab Switcher
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: TriplTheme.obsidianBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TriplTheme.borderGreen),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setStateDialog(() => isPartial = false);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !isPartial ? TriplTheme.primaryMint : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Full ($currency${record.amount.toStringAsFixed(0)})',
                                style: TextStyle(
                                  color: !isPartial ? TriplTheme.obsidianBg : TriplTheme.textGray,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setStateDialog(() => isPartial = true);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isPartial ? TriplTheme.primaryMint : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Partial Amount',
                                style: TextStyle(
                                  color: isPartial ? TriplTheme.obsidianBg : TriplTheme.textGray,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isPartial) ...[
                    Text(
                      record.isLent
                          ? 'Confirm Rahul paid you back the full amount of $currency${record.amount.toStringAsFixed(0)}.'
                              .replaceAll('Rahul', record.personName)
                          : 'Confirm you paid Rahul back the full amount of $currency${record.amount.toStringAsFixed(0)}.'
                              .replaceAll('Rahul', record.personName),
                      style: TextStyle(color: TriplTheme.textLight, fontSize: 13, height: 1.4),
                    ),
                  ] else ...[
                    Text(
                      'AMOUNT TO SETTLE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: partialController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\+\-\*\/\×\÷\%\ \(\)]')),
                      ],
                      style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '$currency ',
                        prefixStyle: TextStyle(color: TriplTheme.primaryMint, fontWeight: FontWeight.bold),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: TriplTheme.textGray),
                        filled: true,
                        fillColor: TriplTheme.obsidianBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TriplTheme.borderGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TriplTheme.primaryMint),
                        ),
                      ),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 8),
                    // Quick Chips
                    Row(
                      children: [0.25, 0.5, 0.75].map((factor) {
                        final amt = (record.amount * factor).round();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setStateDialog(() {
                                partialController.text = amt.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: TriplTheme.obsidianBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: TriplTheme.borderGreen),
                              ),
                              child: Text(
                                '${(factor * 100).toInt()}% ($currency$amt)',
                                style: TextStyle(color: TriplTheme.textGray, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remaining after settlement: $currency${remaining.toStringAsFixed(0)}',
                      style: TextStyle(color: TriplTheme.primaryMint.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: recordTimelineTx,
                        activeColor: TriplTheme.primaryMint,
                        onChanged: (val) {
                          setStateDialog(() {
                            recordTimelineTx = val ?? true;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          isSynth
                              ? 'Complete transaction in timeline'
                              : 'Record Settlement in Timeline',
                          style: TextStyle(color: TriplTheme.textLight, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (recordTimelineTx) ...[
                    const SizedBox(height: 8),
                    Text(
                      'SELECT PAYMENT SOURCE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: TriplTheme.obsidianBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TriplTheme.borderGreen),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSource,
                          dropdownColor: TriplTheme.obsidianCard,
                          isExpanded: true,
                          style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                          items: ref.read(sourcesListProvider).map((s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedSource = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: TriplTheme.textGray)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TriplTheme.primaryMint,
                  foregroundColor: TriplTheme.obsidianBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final amtToSettle = isPartial
                      ? (MathEvaluator.tryParseAmount(partialController.text) ?? 0.0)
                      : record.amount;

                  if (amtToSettle <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount greater than 0'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  if (amtToSettle > record.amount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Amount cannot exceed $currency${record.amount.toStringAsFixed(0)}'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  final isFull = amtToSettle >= record.amount - 0.0001;

                  if (isSynth && synthTx != null) {
                    if (isFull) {
                      if (recordTimelineTx) {
                        final updatedTx = synthTx.copyWith(
                          paymentMethod: selectedSource,
                          needsVerification: false,
                          reminderDate: null,
                        );
                        await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);
                        NotificationService.cancelNotification(synthTx.id);
                      } else {
                        final updatedTx = synthTx.copyWith(
                          hideFromLedger: true,
                        );
                        await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);
                      }
                    } else {
                      final updatedTx = synthTx.copyWith(
                        amount: synthTx.amount - amtToSettle,
                      );
                      await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);

                      if (recordTimelineTx) {
                        final completedTx = ExpenseTransaction(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amtToSettle,
                          merchant: synthTx.merchant,
                          date: DateTime.now(),
                          paymentMethod: selectedSource,
                          category: synthTx.category,
                          notes: '${synthTx.notes} (Partial settlement)'.trim(),
                          paidTo: synthTx.paidTo,
                          needsVerification: false,
                          isIncome: synthTx.isIncome,
                        );
                        await ref.read(transactionListProvider.notifier).addTransaction(completedTx);
                      }

                      await ref.read(outstandingListProvider.notifier).addRecord(
                        OutstandingRecord(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          personName: record.personName,
                          amount: amtToSettle,
                          notes: '${record.notes} (Partial settlement)'.trim(),
                          date: DateTime.now(),
                          isLent: record.isLent,
                          isSettled: true,
                          settledDate: DateTime.now(),
                        ),
                      );
                    }
                  } else {
                    if (isFull) {
                      await ref.read(outstandingListProvider.notifier).settleRecord(
                            record.id,
                            recordTimelineTx: recordTimelineTx,
                            paymentMethod: recordTimelineTx ? selectedSource : null,
                          );
                    } else {
                      await ref.read(outstandingListProvider.notifier).settleRecordPartial(
                            record.id,
                            amtToSettle,
                            recordTimelineTx: recordTimelineTx,
                            paymentMethod: recordTimelineTx ? selectedSource : null,
                          );
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFull
                            ? 'Settled ${record.personName}\'s log!'
                            : 'Settled $currency${amtToSettle.toStringAsFixed(0)} for ${record.personName}! Remaining: $currency${(record.amount - amtToSettle).toStringAsFixed(0)}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(isPartial ? 'Settle Partial' : 'Settle', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Settle Net Balance Dialog
  void _showSettleNetDialog(
    BuildContext context,
    String person,
    double netAmount,
    List<OutstandingRecord> activeItems, {
    bool initialPartial = false,
  }) {
    final allTx = ref.read(transactionListProvider);
    final synthesizedItems = activeItems.where((r) => allTx.any((t) => t.id == r.id && t.wasFinishLater)).toList();
    final manualItems = activeItems.where((r) => !allTx.any((t) => t.id == r.id && t.wasFinishLater)).toList();

    bool onlySynthesized = synthesizedItems.isNotEmpty && manualItems.isEmpty;
    bool mixed = synthesizedItems.isNotEmpty && manualItems.isNotEmpty;

    bool recordTimelineTx = true;
    String selectedSource = 'Cash';

    // Auto-fetch source if only one synthesized record is being settled
    if (onlySynthesized && synthesizedItems.length == 1) {
      final synthTx = allTx.firstWhere((t) => t.id == synthesizedItems.first.id);
      final sources = ref.read(sourcesListProvider);
      if (synthTx.paymentMethod.isNotEmpty && sources.contains(synthTx.paymentMethod)) {
        selectedSource = synthTx.paymentMethod;
      } else if (!sources.contains(selectedSource) && sources.isNotEmpty) {
        selectedSource = sources.first;
      }
    } else {
      final sources = ref.read(sourcesListProvider);
      if (!sources.contains(selectedSource) && sources.isNotEmpty) {
        selectedSource = sources.first;
      }
    }

    bool isPartial = initialPartial;
    final partialAmountController = TextEditingController();
    final currency = ref.read(currencyProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final partialVal = MathEvaluator.tryParseAmount(partialAmountController.text) ?? 0.0;
          final remaining = (netAmount.abs() - partialVal).clamp(0.0, netAmount.abs());

          return AlertDialog(
            backgroundColor: TriplTheme.obsidianCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: TriplTheme.borderGreen, width: 1.5),
            ),
            title: Text(
              isPartial ? 'Settle Partial Balance' : 'Settle Net Account',
              style: TextStyle(color: TriplTheme.primaryMint, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode Selector Tabs
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: TriplTheme.obsidianBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TriplTheme.borderGreen),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setStateDialog(() => isPartial = false);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !isPartial ? TriplTheme.primaryMint : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Full Net ($currency${netAmount.abs().toStringAsFixed(0)})',
                                style: TextStyle(
                                  color: !isPartial ? TriplTheme.obsidianBg : TriplTheme.textGray,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setStateDialog(() => isPartial = true);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isPartial ? TriplTheme.primaryMint : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Partial Amount',
                                style: TextStyle(
                                  color: isPartial ? TriplTheme.obsidianBg : TriplTheme.textGray,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isPartial) ...[
                    Text(
                      netAmount > 0
                          ? 'Confirm Rahul paid you the full net balance of $currency${netAmount.abs().toStringAsFixed(0)}.'
                              .replaceAll('Rahul', person)
                          : 'Confirm you paid Rahul the full net balance of $currency${netAmount.abs().toStringAsFixed(0)}.'
                              .replaceAll('Rahul', person),
                      style: TextStyle(color: TriplTheme.textLight, fontSize: 13, height: 1.4),
                    ),
                  ] else ...[
                    Text(
                      'AMOUNT TO SETTLE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: partialAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\+\-\*\/\×\÷\%\ \(\)]')),
                      ],
                      style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '$currency ',
                        prefixStyle: TextStyle(color: TriplTheme.primaryMint, fontWeight: FontWeight.bold),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: TriplTheme.textGray),
                        filled: true,
                        fillColor: TriplTheme.obsidianBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TriplTheme.borderGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TriplTheme.primaryMint),
                        ),
                      ),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 8),
                    // Quick Chips
                    Row(
                      children: [0.25, 0.5, 0.75].map((factor) {
                        final amt = (netAmount.abs() * factor).round();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setStateDialog(() {
                                partialAmountController.text = amt.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: TriplTheme.obsidianBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: TriplTheme.borderGreen),
                              ),
                              child: Text(
                                '${(factor * 100).toInt()}% ($currency$amt)',
                                style: TextStyle(color: TriplTheme.textGray, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remaining balance after settlement: $currency${remaining.toStringAsFixed(0)}',
                      style: TextStyle(color: TriplTheme.primaryMint.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: recordTimelineTx,
                        activeColor: TriplTheme.primaryMint,
                        onChanged: (val) {
                          setStateDialog(() {
                            recordTimelineTx = val ?? true;
                          });
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              onlySynthesized 
                                  ? 'Complete transaction(s) in timeline' 
                                  : mixed 
                                      ? 'Record settlement & complete pending'
                                      : 'Record Settlement in Timeline',
                              style: TextStyle(color: TriplTheme.textLight, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              netAmount > 0 ? 'Logged as Income (+)' : 'Logged as Expense (-)',
                              style: TextStyle(
                                color: netAmount > 0 ? const Color(0xFF10B981) : TriplTheme.textGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (recordTimelineTx) ...[
                    const SizedBox(height: 8),
                    Text(
                      'SELECT PAYMENT SOURCE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: TriplTheme.obsidianBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TriplTheme.borderGreen),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSource,
                          dropdownColor: TriplTheme.obsidianCard,
                          isExpanded: true,
                          style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                          items: ref.read(sourcesListProvider).map((s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedSource = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: TriplTheme.textGray)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TriplTheme.primaryMint,
                  foregroundColor: TriplTheme.obsidianBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final settleAmount = isPartial
                      ? (MathEvaluator.tryParseAmount(partialAmountController.text) ?? 0.0)
                      : netAmount.abs();

                  if (settleAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount greater than 0'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  if (settleAmount > netAmount.abs()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Amount cannot exceed net balance ($currency${netAmount.abs().toStringAsFixed(0)})'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  final isFull = settleAmount >= netAmount.abs() - 0.0001;

                  if (isFull) {
                    // Settle synthesized logs for this person
                    for (final record in synthesizedItems) {
                      final synthTx = allTx.firstWhere((t) => t.id == record.id);
                      if (recordTimelineTx) {
                        final updatedTx = synthTx.copyWith(
                          paymentMethod: selectedSource,
                          needsVerification: false,
                          reminderDate: null,
                        );
                        await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);
                        NotificationService.cancelNotification(synthTx.id);
                      } else {
                        final updatedTx = synthTx.copyWith(
                          hideFromLedger: true,
                        );
                        await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);
                      }
                    }

                    // Settle manual logs for this person
                    for (final record in manualItems) {
                      await ref.read(outstandingListProvider.notifier).settleRecord(record.id, recordTimelineTx: false);
                    }

                    // If timeline tracking was requested and there are manual items, log the NET settlement as a single entry
                    if (recordTimelineTx && manualItems.isNotEmpty) {
                      double manualNetAmount = 0;
                      for (final record in manualItems) {
                        manualNetAmount += record.isLent ? record.amount : -record.amount;
                      }

                      if (manualNetAmount != 0) {
                        final isIncome = manualNetAmount > 0;
                        final txId = DateTime.now().millisecondsSinceEpoch.toString();

                        final netTx = ExpenseTransaction(
                          id: txId,
                          amount: manualNetAmount.abs(),
                          merchant: person,
                          date: DateTime.now(),
                          paymentMethod: selectedSource,
                          category: isIncome ? 'Income' : 'Other',
                          notes: isIncome
                              ? 'Settled net balance: $person paid back'
                              : 'Settled net balance: Paid back $person',
                          paidTo: !isIncome ? person : '',
                          isIncome: isIncome, // <<-- FIXED: Explicitly set isIncome!
                        );

                        await ref.read(transactionListProvider.notifier).addTransaction(netTx);
                      }
                    }
                  } else {
                    // Partial settlement across records
                    double remainingToSettle = settleAmount;

                    // 1. Settle synthesized items first if any
                    for (final record in synthesizedItems) {
                      if (remainingToSettle <= 0) break;
                      final synthTx = allTx.firstWhere((t) => t.id == record.id);
                      if (synthTx.amount <= remainingToSettle + 0.0001) {
                        remainingToSettle -= synthTx.amount;
                        final updatedTx = synthTx.copyWith(
                          paymentMethod: selectedSource,
                          needsVerification: false,
                          reminderDate: null,
                        );
                        await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);
                        NotificationService.cancelNotification(synthTx.id);
                      } else {
                        final portion = remainingToSettle;
                        remainingToSettle = 0;
                        final updatedTx = synthTx.copyWith(
                          amount: synthTx.amount - portion,
                        );
                        await ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);

                        if (recordTimelineTx) {
                          final splitTx = ExpenseTransaction(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            amount: portion,
                            merchant: synthTx.merchant,
                            date: DateTime.now(),
                            paymentMethod: selectedSource,
                            category: synthTx.category,
                            notes: '${synthTx.notes} (Partial settlement)'.trim(),
                            paidTo: synthTx.paidTo,
                            needsVerification: false,
                            isIncome: synthTx.isIncome,
                          );
                          await ref.read(transactionListProvider.notifier).addTransaction(splitTx);
                        }

                        await ref.read(outstandingListProvider.notifier).addRecord(
                          OutstandingRecord(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            personName: person,
                            amount: portion,
                            notes: 'Partial settlement',
                            date: DateTime.now(),
                            isLent: synthTx.isIncome,
                            isSettled: true,
                            settledDate: DateTime.now(),
                          ),
                        );
                      }
                    }

                    // 2. Settle manual items with remainingToSettle
                    if (remainingToSettle > 0) {
                      final isLentDirection = netAmount > 0;
                      String? timelineTxId;
                      if (recordTimelineTx) {
                        timelineTxId = DateTime.now().millisecondsSinceEpoch.toString();
                        final isIncome = isLentDirection;
                        final partialTx = ExpenseTransaction(
                          id: timelineTxId,
                          amount: remainingToSettle,
                          merchant: person,
                          date: DateTime.now(),
                          paymentMethod: selectedSource,
                          category: isIncome ? 'Income' : 'Other',
                          notes: isIncome
                              ? 'Partial settlement: $person paid back'
                              : 'Partial settlement: Paid back $person',
                          paidTo: !isIncome ? person : '',
                          isIncome: isIncome, // <<-- FIXED: Explicitly set isIncome!
                        );
                        await ref.read(transactionListProvider.notifier).addTransaction(partialTx);
                      }

                      await ref.read(outstandingListProvider.notifier).settlePersonAmount(
                        person,
                        remainingToSettle,
                        isLentDirection,
                        linkedTimelineTxId: timelineTxId,
                      );
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFull
                            ? 'Net outstanding for $person settled!'
                            : 'Settled $currency${settleAmount.toStringAsFixed(0)} for $person! Remaining: $currency${(netAmount.abs() - settleAmount).toStringAsFixed(0)}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(isPartial ? 'Settle Partial' : 'Settle Net', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Quick Add Bottom Sheet
  void _showAddIOUSheet(BuildContext context, List<String> availableSources) {
    bool isLent = true;
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    
    bool recordTimelineTx = false;
    String selectedSource = 'Cash';

    // Get predictive names suggestions
    final existingRecords = ref.read(outstandingListProvider);
    final suggestions = existingRecords.map((e) => e.personName).toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriplTheme.obsidianBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TriplTheme.borderGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add IOU Record',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: TriplTheme.textLight, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 20),

                // Lent vs Borrowed Switcher
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: TriplTheme.obsidianCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TriplTheme.borderGreen),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setSheetState(() {
                              isLent = true;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isLent ? TriplTheme.primaryMint : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  'THEY OWE ME (LENT)',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isLent ? TriplTheme.obsidianBg : TriplTheme.textGray,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setSheetState(() {
                              isLent = false;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !isLent ? const Color(0xFFF59E0B) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  'I OWE THEM (BORROWED)',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: !isLent ? TriplTheme.obsidianBg : TriplTheme.textGray,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Friend's Name Field
                Text(
                  'FRIEND\'S NAME',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return suggestions.where((name) {
                      return name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync autocomplete controller with our local controller
                    controller.addListener(() {
                      nameController.text = controller.text;
                    });
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Who is this with?',
                        hintStyle: TextStyle(color: TriplTheme.textGray),
                        filled: true,
                        fillColor: TriplTheme.obsidianCard,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: TriplTheme.borderGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isLent ? TriplTheme.primaryMint : const Color(0xFFF59E0B)),
                        ),
                      ),
                    );
                  },
                  onSelected: (String selection) {
                    nameController.text = selection;
                  },
                ),
                const SizedBox(height: 16),

                // Amount and Notes Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AMOUNT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\+\-\*\/\×\÷\%\ \(\)]')),
                            ],
                            style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(color: TriplTheme.textGray),
                              filled: true,
                              fillColor: TriplTheme.obsidianCard,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: TriplTheme.borderGreen),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: isLent ? TriplTheme.primaryMint : const Color(0xFFF59E0B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOTES / DESCRIPTION',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: notesController,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'e.g. Dinner, Rent split...',
                              hintStyle: TextStyle(color: TriplTheme.textGray),
                              filled: true,
                              fillColor: TriplTheme.obsidianCard,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: TriplTheme.borderGreen),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: isLent ? TriplTheme.primaryMint : const Color(0xFFF59E0B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Direct Timeline Toggle
                Row(
                  children: [
                    Checkbox(
                      value: recordTimelineTx,
                      activeColor: isLent ? TriplTheme.primaryMint : const Color(0xFFF59E0B),
                      onChanged: (val) {
                        setSheetState(() {
                          recordTimelineTx = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Record in Wallet Timeline',
                        style: TextStyle(color: TriplTheme.textLight, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (recordTimelineTx) ...[
                  const SizedBox(height: 12),
                  Text(
                    'SELECT PAYMENT SOURCE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: TriplTheme.textGray, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: TriplTheme.obsidianCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: TriplTheme.borderGreen),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSource,
                        dropdownColor: TriplTheme.obsidianCard,
                        isExpanded: true,
                        style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
                        items: availableSources.map((s) {
                          return DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              selectedSource = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Save Action Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLent ? TriplTheme.primaryMint : const Color(0xFFF59E0B),
                    foregroundColor: TriplTheme.obsidianBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final notes = notesController.text.trim();
                    final amt = MathEvaluator.tryParseAmount(amountController.text) ?? 0.0;

                    if (name.isEmpty || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid name and amount.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final newRecord = OutstandingRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      personName: name,
                      amount: amt,
                      notes: notes,
                      date: DateTime.now(),
                      isLent: isLent,
                    );

                    await ref.read(outstandingListProvider.notifier).addRecord(
                          newRecord,
                          recordTimelineTx: recordTimelineTx,
                          paymentMethod: recordTimelineTx ? selectedSource : null,
                        );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isLent ? 'Lent log saved successfully!' : 'Borrowed log saved successfully!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save Log',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(kPrefTutorialLedger) ?? false;
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
        ref.read(tutorialProvider.notifier).markCompleted(kPrefTutorialLedger);
      },
      onSkip: () {
        if (!mounted) return true;
        ref.read(tutorialProvider.notifier).markCompleted(kPrefTutorialLedger);
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
      identify: "TargetWhoOwesMe",
      keyTarget: TutorialService.ledgerWhoOwesMeKey,
      alignSkip: Alignment.topRight,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => _buildTutorialContent(controller, "Pending Receivables", "This shows money others owe you. Note: Transactions marked as 'Finish later' (pending) are automatically logged in this ledger. You can finish them here or from the transaction itself."),
        ),
      ],
    ));

    targets.add(TargetFocus(
      identify: "TargetWhoIOwe",
      keyTarget: TutorialService.ledgerWhoIOweKey,
      alignSkip: Alignment.topRight,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => _buildTutorialContent(controller, "Your Debts", "This shows money you owe. Tap the (+) button below to manually log new IOUs, or tap an existing person's name to settle up balances.", nextText: "Finish"),
        ),
      ],
    ));

    return targets;
  }
}

