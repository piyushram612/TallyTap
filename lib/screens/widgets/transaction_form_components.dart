import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/math_evaluator.dart';
import '../../models/transaction_model.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: TriplTheme.textGray,
        ),
      );
}

class TypeToggle extends StatelessWidget {
  const TypeToggle({super.key, required this.isIncome, required this.onChanged});
  final bool isIncome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return Container(
      height: 34 * textScale,
      decoration: BoxDecoration(
        color: TriplTheme.obsidianCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TriplTheme.borderGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pill('Expense', !isIncome, TriplTheme.primaryMint,
              () => onChanged(false)),
          _pill('Income', isIncome, const Color(0xFF10B981),
              () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _pill(
      String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(color: color.withOpacity(0.6), width: 1.0)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? color : TriplTheme.textGray,
            ),
          ),
        ),
      ),
    );
  }
}

class AmountCard extends StatelessWidget {
  const AmountCard({
    super.key,
    required this.currency,
    required this.controller,
    required this.activeColor,
    required this.catColor,
  });

  final String currency;
  final TextEditingController controller;
  final Color activeColor;
  final Color catColor;

  Future<void> _openCalculatorSheet(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final currentFocus = FocusScope.of(context);
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (isKeyboardVisible || currentFocus.focusedChild != null) {
      // 1. Explicitly unfocus active text field and request OS keyboard hide
      currentFocus.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod('TextInput.hide');

      // 2. Wait 220ms for OS soft keyboard collapse animation to complete smoothly
      // This prevents double layout animation collisions between OS keyboard and bottom sheet route
      await Future.delayed(const Duration(milliseconds: 220));
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => _CalculatorKeyboardSheet(
        controller: controller,
        currency: currency,
        activeColor: activeColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCalculatorSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: TriplTheme.obsidianCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TriplTheme.borderGreen),
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRANSACTION AMOUNT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: TriplTheme.textGray,
                  ),
                ),
                Icon(
                  Icons.calculate_rounded,
                  color: activeColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  currency,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: activeColor,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: IntrinsicWidth(
                    child: TextFormField(
                      controller: controller,
                      readOnly: true,
                      onTap: () => _openCalculatorSheet(context),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: TriplTheme.textLight,
                        fontFamily: 'Outfit',
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.left,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\+\-\*\/\×\÷\%\ \(\)]')),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: TriplTheme.textGray.withOpacity(0.25),
                          fontFamily: 'Outfit',
                          letterSpacing: -1,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        final parsed = MathEvaluator.tryParseAmount(val);
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid calculation';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Bottom Sheet Calculator Keyboard using Obsidian glassmorphic card styling
class _CalculatorKeyboardSheet extends StatefulWidget {
  const _CalculatorKeyboardSheet({
    required this.controller,
    required this.currency,
    required this.activeColor,
  });

  final TextEditingController controller;
  final String currency;
  final Color activeColor;

  @override
  State<_CalculatorKeyboardSheet> createState() => _CalculatorKeyboardSheetState();
}

class _CalculatorKeyboardSheetState extends State<_CalculatorKeyboardSheet> {
  late String _expr;

  @override
  void initState() {
    super.initState();
    _expr = widget.controller.text.trim();
  }

  void _onKeyPress(String key) {
    HapticFeedback.selectionClick();
    final evaluated = MathEvaluator.evaluate(_expr);

    setState(() {
      if (key == 'C') {
        _expr = '';
      } else if (key == '⌫') {
        if (_expr.isNotEmpty) {
          _expr = _expr.substring(0, _expr.length - 1).trimRight();
        }
      } else if (key == '=') {
        if (evaluated != null) {
          _expr = MathEvaluator.formatResult(evaluated);
        }
      } else if (key == '+' || key == '-' || key == '×' || key == '÷') {
        if (_expr.isNotEmpty && !_expr.endsWith(' ')) {
          _expr = '$_expr $key ';
        }
      } else {
        _expr += key;
      }
    });
  }

  void _onSetAmount() {
    HapticFeedback.mediumImpact();
    String finalAmountStr = _expr.trim();

    if (MathEvaluator.hasOperator(finalAmountStr)) {
      final evaluated = MathEvaluator.evaluate(finalAmountStr);
      if (evaluated != null) {
        finalAmountStr = MathEvaluator.formatResult(evaluated);
      }
    }

    widget.controller.text = finalAmountStr;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double? evaluated = MathEvaluator.hasOperator(_expr) ? MathEvaluator.evaluate(_expr) : null;
    final String? evaluatedStr = evaluated != null ? MathEvaluator.formatResult(evaluated) : null;

    return Container(
      decoration: BoxDecoration(
        color: TriplTheme.obsidianBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: TriplTheme.borderGreen),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -6)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TriplTheme.textGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row: "Enter Amount" & Live Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Enter Amount',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: TriplTheme.textLight,
                  fontFamily: 'Outfit',
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expr.isEmpty ? '${widget.currency}0' : '${widget.currency}$_expr',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: TriplTheme.textLight,
                        fontFamily: 'Outfit',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (evaluatedStr != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '= ${widget.currency}$evaluatedStr',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: widget.activeColor,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Obsidian Keypad Container Card (Matching User's Screenshot UI)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TriplTheme.obsidianCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: TriplTheme.borderGreen),
            ),
            child: Column(
              children: [
                _buildRow(['C', '(', ')', '÷']),
                const SizedBox(height: 10),
                _buildRow(['7', '8', '9', '×']),
                const SizedBox(height: 10),
                _buildRow(['4', '5', '6', '-']),
                const SizedBox(height: 10),
                _buildRow(['1', '2', '3', '+']),
                const SizedBox(height: 10),
                _buildRow(['0', '.', '⌫', '=']),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Set Amount Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onSetAmount,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.activeColor,
                foregroundColor: TriplTheme.obsidianBg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                evaluatedStr != null ? 'SET AMOUNT (= $evaluatedStr)' : 'SET AMOUNT',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((k) => Expanded(child: _buildKey(k))).toList(),
    );
  }

  Widget _buildKey(String label) {
    final bool isOperator = label == '+' || label == '-' || label == '×' || label == '÷' || label == '=';
    final bool isBack = label == '⌫';
    final bool isClear = label == 'C';
    final Color color = isClear
        ? Colors.redAccent
        : (isOperator ? widget.activeColor : TriplTheme.textLight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onKeyPress(label),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isClear
                  ? Colors.redAccent.withOpacity(0.12)
                  : (isOperator ? widget.activeColor.withOpacity(0.15) : TriplTheme.obsidianCard),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClear
                    ? Colors.redAccent.withOpacity(0.4)
                    : (isOperator ? widget.activeColor.withOpacity(0.4) : TriplTheme.borderGreen),
              ),
            ),
            child: isBack
                ? Icon(Icons.backspace_outlined, color: TriplTheme.textGray, size: 20)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Outfit',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AutofillSuggestion {
  final String merchant;
  final String category;
  final String paidTo;
  final bool isIncome;
  final DateTime date;

  AutofillSuggestion({
    required this.merchant,
    required this.category,
    required this.paidTo,
    required this.isIncome,
    required this.date,
  });
}

class MerchantAutofillField extends StatefulWidget {
  const MerchantAutofillField({
    super.key,
    required this.controller,
    required this.transactions,
    required this.activeColor,
    required this.hintText,
    required this.onSuggestionSelected,
    this.isIncome = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final List<ExpenseTransaction> transactions;
  final Color activeColor;
  final String hintText;
  final ValueChanged<AutofillSuggestion> onSuggestionSelected;
  final bool isIncome;
  final FocusNode? focusNode;

  @override
  State<MerchantAutofillField> createState() => _MerchantAutofillFieldState();
}

class _MerchantAutofillFieldState extends State<MerchantAutofillField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  List<AutofillSuggestion> _getSuggestions() {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) return [];

    // Deduplicate by merchant title (case-insensitive), keeping the most recent transaction
    final Map<String, ExpenseTransaction> uniqueMap = {};
    for (final tx in widget.transactions) {
      final merchantKey = tx.merchant.trim().toLowerCase();
      if (merchantKey.isEmpty) continue;

      if (!uniqueMap.containsKey(merchantKey)) {
        uniqueMap[merchantKey] = tx;
      } else {
        if (tx.date.isAfter(uniqueMap[merchantKey]!.date)) {
          uniqueMap[merchantKey] = tx;
        }
      }
    }

    final suggestions = uniqueMap.values
        .where((tx) => tx.merchant.trim().toLowerCase().contains(query))
        .map((tx) => AutofillSuggestion(
              merchant: tx.merchant.trim(),
              category: tx.category,
              paidTo: tx.paidTo,
              isIncome: tx.isIncome,
              date: tx.date,
            ))
        .toList();

    // Sort: prefix matches first, then matching isIncome type, then by recency
    suggestions.sort((a, b) {
      final aLower = a.merchant.toLowerCase();
      final bLower = b.merchant.toLowerCase();
      final aStartsWith = aLower.startsWith(query);
      final bStartsWith = bLower.startsWith(query);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      final aSameType = a.isIncome == widget.isIncome;
      final bSameType = b.isIncome == widget.isIncome;
      if (aSameType && !bSameType) return -1;
      if (!aSameType && bSameType) return 1;

      return b.date.compareTo(a.date);
    });

    return suggestions.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _focusNode.hasFocus ? _getSuggestions() : <AutofillSuggestion>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: TextStyle(
            color: TriplTheme.textLight,
            fontWeight: FontWeight.w600,
          ),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: TriplTheme.textGray,
              fontSize: 14,
            ),
            filled: true,
            fillColor: TriplTheme.obsidianCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: TriplTheme.borderGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: widget.activeColor, width: 1.5),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: suggestions.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TriplTheme.obsidianCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.activeColor.withOpacity(0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.activeColor.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: widget.activeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AUTOFILL SUGGESTIONS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: widget.activeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: suggestions.map((s) {
                          final catColor = s.isIncome
                              ? const Color(0xFF10B981)
                              : TriplTheme.getColorForCategory(s.category);
                          final catIcon = TriplTheme.getIconForCategory(
                              s.category, s.isIncome);

                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onSuggestionSelected(s);
                              _focusNode.unfocus();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: TriplTheme.obsidianBg.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: TriplTheme.borderGreen.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 16,
                                    color: TriplTheme.textGray,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.merchant,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: TriplTheme.textLight,
                                          ),
                                        ),
                                        if (s.paidTo.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Paid to: ${s.paidTo}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: TriplTheme.textGray,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: catColor.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          catIcon,
                                          size: 12,
                                          color: catColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          s.category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: catColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

