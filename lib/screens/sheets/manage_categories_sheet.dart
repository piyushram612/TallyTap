import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'manage_items_sheet.dart';
import '../../providers/category_provider.dart';
import '../../providers/customization_provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import '../../core/theme.dart';

class ManageCategoriesSheet extends ConsumerStatefulWidget {
  const ManageCategoriesSheet({super.key});

  @override
  ConsumerState<ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends ConsumerState<ManageCategoriesSheet> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  static const double _minSize = 0.35;
  static const double _maxSize = 0.95;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesListProvider);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final currentInitialSize = keyboardOpen ? 0.90 : 0.55;
    final currentMinSize = keyboardOpen ? 0.90 : _minSize;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: currentInitialSize,
      minChildSize: currentMinSize,
      maxChildSize: _maxSize,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: TriplTheme.obsidianBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ManageItemsSheet(
                  title: 'Manage Categories',
                  itemLabel: 'Category',
                  hintText: 'Category name (e.g. Health)',
                  items: categories,
                  scrollController: scrollController,
            onAdd: (name) async {
              await ref.read(categoriesListProvider.notifier).addCategory(name);
              await ref.read(budgetLimitsProvider.notifier).loadLimits();
            },
            onDelete: (name) async {
              await ref.read(categoryVisibilityProvider.notifier).removeVisibility(name);
              await ref.read(categoriesListProvider.notifier).deleteCategory(name);
              await ref.read(budgetLimitsProvider.notifier).loadLimits();
            },
            onUpdate: (oldName, newName) async {
              await ref.read(customizationProvider.notifier).migrateCategoryCustomizations(oldName, newName);
              await ref.read(categoryVisibilityProvider.notifier).renameVisibility(oldName, newName);
              await ref.read(categoriesListProvider.notifier).updateCategory(oldName, newName);
              try {
                final txListNotifier = ref.read(transactionListProvider.notifier);
                final transactions = ref.read(transactionListProvider);
                for (var tx in transactions) {
                  if (tx.category == oldName) {
                    final updatedTx = tx.copyWith(category: newName);
                    await txListNotifier.updateTransaction(updatedTx);
                  }
                }
              } catch (e) {
                debugPrint("Error updating transactions: $e");
              }
              await ref.read(budgetLimitsProvider.notifier).loadLimits();
            },
            onReorder: (oldIndex, newIndex) async {
              await ref.read(categoriesListProvider.notifier).reorderCategories(oldIndex, newIndex);
              await ref.read(budgetLimitsProvider.notifier).loadLimits();
            },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
