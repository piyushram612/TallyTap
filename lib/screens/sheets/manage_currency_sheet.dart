import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/transaction_service.dart';

class ManageCurrencySheet extends ConsumerWidget {
  const ManageCurrencySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    final currencies = [
      {'symbol': '₹', 'name': 'Indian Rupee (INR)'},
      {'symbol': '\$', 'name': 'US Dollar (USD)'},
      {'symbol': '€', 'name': 'Euro (EUR)'},
      {'symbol': '£', 'name': 'British Pound (GBP)'},
      {'symbol': '¥', 'name': 'Japanese Yen (JPY)'},
      {'symbol': 'CN¥', 'name': 'Chinese Yuan (CNY)'},
      {'symbol': 'A\$', 'name': 'Australian Dollar (AUD)'},
      {'symbol': 'C\$', 'name': 'Canadian Dollar (CAD)'},
      {'symbol': 'CHF', 'name': 'Swiss Franc (CHF)'},
      {'symbol': 'AED', 'name': 'UAE Dirham (AED)'},
      {'symbol': 'S\$', 'name': 'Singapore Dollar (SGD)'},
      {'symbol': 'NZ\$', 'name': 'New Zealand Dollar (NZD)'},
      {'symbol': 'R\$', 'name': 'Brazilian Real (BRL)'},
      {'symbol': '₩', 'name': 'South Korean Won (KRW)'},
      {'symbol': 'SAR', 'name': 'Saudi Riyal (SAR)'},
      {'symbol': 'HK\$', 'name': 'Hong Kong Dollar (HKD)'},
      {'symbol': 'R', 'name': 'South African Rand (ZAR)'},
      {'symbol': '₽', 'name': 'Russian Ruble (RUB)'},
      {'symbol': '₺', 'name': 'Turkish Lira (TRY)'},
      {'symbol': 'kr', 'name': 'Swedish Krona (SEK)'},
      {'symbol': 'RM', 'name': 'Malaysian Ringgit (MYR)'},
      {'symbol': '฿', 'name': 'Thai Baht (THB)'},
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Currency',
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
          Text(
            'GLOBAL CURRENCY (CHANGING THIS WILL CONVERT ALL EXISTING VALUES)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: TriplTheme.textGray,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: currencies.map((currency) {
                  final isSelected = currentCurrency == currency['symbol'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Material(
                      color: isSelected ? TriplTheme.primaryMint.withOpacity(0.1) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? TriplTheme.primaryMint : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? TriplTheme.primaryMint : TriplTheme.obsidianCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? TriplTheme.primaryMint : TriplTheme.borderGreen,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        currency['symbol']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? TriplTheme.obsidianBg : TriplTheme.primaryMint,
                        ),
                      ),
                    ),
                    title: Text(
                      currency['name']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? TriplTheme.primaryMint : TriplTheme.textLight,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: TriplTheme.primaryMint)
                        : null,
                    onTap: () async {
                      if (!isSelected) {
                        final result = await showDialog<Map<String, bool>>(
                          context: context,
                          builder: (context) => CurrencySettingsDialog(
                            currency: currency,
                            oldCurrencySymbol: currentCurrency,
                          ),
                        );

                        if (result == null) return;

                        final convertValues = result['convertValues'] ?? true;
                        final applyToExisting = result['applyToExisting'] ?? true;

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: CircularProgressIndicator(color: TriplTheme.primaryMint),
                            ),
                          );
                        }

                        try {
                          await ref.read(currencyProvider.notifier).setCurrency(
                            currency['symbol']!,
                            convertValues: convertValues,
                            applyToExisting: applyToExisting,
                          );
                          
                          // Force a refresh of dependent providers
                          ref.read(transactionListProvider.notifier).loadTransactions();
                          ref.read(globalBudgetProvider.notifier).loadGlobalBudget();
                          ref.read(budgetLimitsProvider.notifier).loadLimits();
                          
                          if (context.mounted) {
                            Navigator.pop(context); // pop loading dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Currency updated to ${currency['name']}. '
                                  '${convertValues ? "Values converted" : "Symbol changed"}'
                                  '${applyToExisting ? " for all transactions." : " for new transactions onwards."}'
                                ),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(context); // pop sheet
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // pop loading dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update currency. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencySettingsDialog extends StatefulWidget {
  final Map<String, String> currency;
  final String oldCurrencySymbol;

  const CurrencySettingsDialog({
    super.key,
    required this.currency,
    required this.oldCurrencySymbol,
  });

  @override
  State<CurrencySettingsDialog> createState() => _CurrencySettingsDialogState();
}

class _CurrencySettingsDialogState extends State<CurrencySettingsDialog> {
  bool _convertValues = true;
  bool _applyToExisting = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TriplTheme.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: TriplTheme.borderGreen, width: 1.5),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'Change Currency to ${widget.currency['symbol']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TriplTheme.primaryMint,
                fontFamily: 'Outfit',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Question 1: Convert or Symbol Only
            Text(
              'CONVERSION OPTION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: TriplTheme.textGray,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectionCard(
              title: 'Convert Values',
              subtitle: 'Use exchange rates to convert all numeric amounts.',
              selected: _convertValues,
              onTap: () => setState(() => _convertValues = true),
            ),
            const SizedBox(height: 8),
            _buildSelectionCard(
              title: 'Change Symbol Only',
              subtitle: 'Keep all existing numbers exactly the same.',
              selected: !_convertValues,
              onTap: () => setState(() => _convertValues = false),
            ),
            const SizedBox(height: 20),

            // Question 2: All or From Now Onwards
            Text(
              'APPLY TO WHICH TRANSACTIONS?',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: TriplTheme.textGray,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectionCard(
              title: 'All Transactions',
              subtitle: 'Apply changes to all existing and future transactions.',
              selected: _applyToExisting,
              onTap: () => setState(() => _applyToExisting = true),
            ),
            const SizedBox(height: 8),
            _buildSelectionCard(
              title: 'From Now Onwards',
              subtitle: 'Keep existing transactions as is; only apply to new transactions.',
              selected: !_applyToExisting,
              onTap: () => setState(() => _applyToExisting = false),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: TriplTheme.textGray, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TriplTheme.primaryMint,
                      foregroundColor: TriplTheme.obsidianBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'convertValues': _convertValues,
                        'applyToExisting': _applyToExisting,
                      });
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? TriplTheme.primaryMint.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TriplTheme.primaryMint : TriplTheme.borderGreen,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? TriplTheme.primaryMint : TriplTheme.textGray,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: TriplTheme.primaryMint,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selected ? TriplTheme.primaryMint : TriplTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }
}
