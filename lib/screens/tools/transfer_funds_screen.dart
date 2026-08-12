import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/transaction_service.dart';

class TransferFundsScreen extends ConsumerStatefulWidget {
  const TransferFundsScreen({super.key});

  @override
  ConsumerState<TransferFundsScreen> createState() => _TransferFundsScreenState();
}

class _TransferFundsScreenState extends ConsumerState<TransferFundsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _sourceAccount;
  String? _destinationAccount;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateUuid() {
    final random = Random();
    final List<int> values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) buffer.write('-');
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Future<void> _pickDate(BuildContext context) async {
    final darkScheme = ColorScheme.dark(
      primary: TriplTheme.primaryMint,
      onPrimary: TriplTheme.obsidianBg,
      surface: TriplTheme.obsidianCard,
      onSurface: TriplTheme.textLight,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (ctx, child) =>
          Theme(data: Theme.of(ctx).copyWith(colorScheme: darkScheme), child: child!),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (ctx, child) =>
          Theme(data: Theme.of(ctx).copyWith(colorScheme: darkScheme), child: child!),
    );
    if (time == null) return;
    setState(() {
      _selectedDate = DateTime(
          picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  void _submitTransfer() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid amount'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_sourceAccount == null || _destinationAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both source and destination accounts'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_sourceAccount == _destinationAccount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Source and destination accounts must be different'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final notesText = _notesController.text.trim();

    final transferTx = ExpenseTransaction(
      id: _generateUuid(),
      amount: amount,
      merchant: 'Transfer from $_sourceAccount to $_destinationAccount',
      date: _selectedDate,
      paymentMethod: _sourceAccount!,
      category: 'Transfer',
      notes: notesText,
      paidTo: _destinationAccount!,
      isIncome: false,
    );

    ref.read(transactionListProvider.notifier).addTransaction(transferTx);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Funds transferred successfully!'),
      backgroundColor: TriplTheme.primaryMint,
      behavior: SnackBarBehavior.floating,
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final sources = ref.watch(sourcesListProvider);

    // Auto-populate accounts if not selected
    if (_sourceAccount == null && sources.isNotEmpty) {
      _sourceAccount = sources.first;
    }
    if (_destinationAccount == null && sources.length > 1) {
      _destinationAccount = sources[1];
    }

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateLabel = isToday
        ? 'Today, ${DateFormat('MMM d, y').format(_selectedDate)}'
        : DateFormat('EEE, MMM d, y').format(_selectedDate);
    final timeLabel = DateFormat('h:mm a').format(_selectedDate);

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
          'Account Transfer',
          style: TextStyle(
            color: TriplTheme.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Outfit',
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: TriplTheme.obsidianCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: TriplTheme.borderGreen, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: TriplTheme.primaryMint.withOpacity(0.02),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'AMOUNT TO TRANSFER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: TriplTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currency,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: TriplTheme.primaryMint,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const SizedBox(width: 4),
                              IntrinsicWidth(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: TriplTheme.textLight,
                                    fontFamily: 'Outfit',
                                  ),
                                  textAlign: TextAlign.center,
                                  cursorColor: TriplTheme.primaryMint,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(color: TriplTheme.textGray),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isCollapsed: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    final val = double.tryParse(value);
                                    if (val == null || val <= 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Accounts Transfer Row (From -> To)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: TriplTheme.obsidianCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TriplTheme.borderGreen, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCOUNTS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: TriplTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Source
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From',
                                      style: TextStyle(fontSize: 12, color: TriplTheme.textGray),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: TriplTheme.obsidianBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: TriplTheme.borderGreen.withOpacity(0.5)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _sourceAccount,
                                          dropdownColor: TriplTheme.obsidianBg,
                                          isExpanded: true,
                                          icon: Icon(Icons.arrow_drop_down, color: TriplTheme.primaryMint),
                                          style: TextStyle(
                                            color: TriplTheme.textLight,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          items: sources.map((src) {
                                            return DropdownMenuItem<String>(
                                              value: src,
                                              child: Text(src),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _sourceAccount = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Icon(Icons.arrow_forward_rounded, color: TriplTheme.primaryMint, size: 20),
                              ),
                              // Destination
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'To',
                                      style: TextStyle(fontSize: 12, color: TriplTheme.textGray),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: TriplTheme.obsidianBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: TriplTheme.borderGreen.withOpacity(0.5)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _destinationAccount,
                                          dropdownColor: TriplTheme.obsidianBg,
                                          isExpanded: true,
                                          icon: Icon(Icons.arrow_drop_down, color: TriplTheme.primaryMint),
                                          style: TextStyle(
                                            color: TriplTheme.textLight,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          items: sources.map((src) {
                                            return DropdownMenuItem<String>(
                                              value: src,
                                              child: Text(src),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _destinationAccount = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Selection Card
                    InkWell(
                      onTap: () => _pickDate(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: TriplTheme.obsidianCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TriplTheme.borderGreen, width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: TriplTheme.obsidianBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.calendar_month_rounded, color: TriplTheme.primaryMint, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DATE & TIME',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                            color: TriplTheme.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$dateLabel @ $timeLabel',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: TriplTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.edit_calendar_rounded, color: TriplTheme.textGray, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notes Field
                    Text(
                      'NOTES (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: TriplTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      style: TextStyle(
                        color: TriplTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add transfer receipt numbers, details, or reasons...',
                        hintStyle: TextStyle(color: TriplTheme.textGray, fontSize: 13),
                        filled: true,
                        fillColor: TriplTheme.obsidianCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  ],
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _submitTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TriplTheme.primaryMint,
                  foregroundColor: TriplTheme.obsidianBg,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: TriplTheme.primaryMint.withOpacity(0.2),
                ),
                child: const Text(
                  'Record Transfer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Outfit'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
