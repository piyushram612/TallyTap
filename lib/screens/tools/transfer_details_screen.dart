import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/transaction_service.dart';

class TransferDetailsScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransferDetailsScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransferDetailsScreen> createState() => _TransferDetailsScreenState();
}

class _TransferDetailsScreenState extends ConsumerState<TransferDetailsScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late String _sourceAccount;
  late String _destinationAccount;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    final transactions = ref.read(transactionListProvider);
    final tx = transactions.firstWhere(
      (t) => t.id == widget.transactionId,
      orElse: () => ExpenseTransaction(
        id: '',
        amount: 0.0,
        merchant: '',
        date: DateTime.now(),
        paymentMethod: '',
        category: 'Transfer',
      ),
    );

    _amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
    _notesController = TextEditingController(text: tx.notes);
    _sourceAccount = tx.paymentMethod;
    _destinationAccount = tx.paidTo;
    _selectedDate = tx.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  void _saveChanges() {
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

    if (_sourceAccount == _destinationAccount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Source and destination accounts must be different'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final transactions = ref.read(transactionListProvider);
    final tx = transactions.firstWhere((t) => t.id == widget.transactionId);

    final updatedTx = tx.copyWith(
      amount: amount,
      notes: _notesController.text.trim(),
      paymentMethod: _sourceAccount,
      paidTo: _destinationAccount,
      date: _selectedDate,
      merchant: 'Transfer from $_sourceAccount to $_destinationAccount',
    );

    ref.read(transactionListProvider.notifier).updateTransaction(updatedTx);

    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Transfer updated successfully'),
      backgroundColor: TriplTheme.primaryMint,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _deleteTransfer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TriplTheme.obsidianCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: TriplTheme.borderGreen, width: 1.5),
        ),
        title: const Text(
          'Delete Transfer?',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this transfer? This will restore balances on both accounts.',
          style: TextStyle(color: TriplTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: TriplTheme.textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await ref.read(transactionListProvider.notifier).deleteTransaction(widget.transactionId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Transfer deleted successfully'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final sources = ref.watch(sourcesListProvider);

    // Watch list to update fields if changed externally (e.g. Riverpod loads)
    ref.listen(transactionListProvider, (_, __) {
      if (!_isEditing) {
        setState(() {
          _initFields();
        });
      }
    });

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
          'Transfer Details',
          style: TextStyle(
            color: TriplTheme.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Outfit',
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(Icons.edit_rounded, color: TriplTheme.primaryMint),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: _deleteTransfer,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.close_rounded, color: TriplTheme.textGray),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initFields();
                });
              },
            ),
          ],
        ],
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
                    // Status Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFF94A3B8).withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz_rounded, color: Color(0xFF94A3B8), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Account Transfer',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: TriplTheme.obsidianCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isEditing ? TriplTheme.primaryMint : TriplTheme.borderGreen,
                          width: _isEditing ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'AMOUNT',
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
                                  enabled: _isEditing,
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

                    // Accounts Card
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
                                          disabledHint: Text(_sourceAccount),
                                          icon: _isEditing ? Icon(Icons.arrow_drop_down, color: TriplTheme.primaryMint) : const SizedBox(),
                                          style: TextStyle(
                                            color: TriplTheme.textLight,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          items: _isEditing
                                              ? sources.map((src) {
                                                  return DropdownMenuItem<String>(
                                                    value: src,
                                                    child: Text(src),
                                                  );
                                                }).toList()
                                              : null,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _sourceAccount = val;
                                              });
                                            }
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
                                          disabledHint: Text(_destinationAccount),
                                          icon: _isEditing ? Icon(Icons.arrow_drop_down, color: TriplTheme.primaryMint) : const SizedBox(),
                                          style: TextStyle(
                                            color: TriplTheme.textLight,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          items: _isEditing
                                              ? sources.map((src) {
                                                  return DropdownMenuItem<String>(
                                                    value: src,
                                                    child: Text(src),
                                                  );
                                                }).toList()
                                              : null,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _destinationAccount = val;
                                              });
                                            }
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

                    // Date & Time Selection Card
                    InkWell(
                      onTap: _isEditing ? () => _pickDate(context) : null,
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
                            Row(
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE & TIME',
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: TriplTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_isEditing)
                              Icon(Icons.edit_calendar_rounded, color: TriplTheme.textGray, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    Text(
                      'NOTES',
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
                      enabled: _isEditing,
                      style: TextStyle(
                        color: TriplTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'No notes provided.',
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: TriplTheme.borderGreen.withOpacity(0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Save Button
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TriplTheme.primaryMint,
                    foregroundColor: TriplTheme.obsidianBg,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Save Changes',
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
