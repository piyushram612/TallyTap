import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';
import 'budget_provider.dart';
import 'category_provider.dart';

class DonutChartCategory {
  final String name;
  final double amount;

  DonutChartCategory({required this.name, required this.amount});
}

class DashboardState {
  final double totalSpent;
  final List<double> weeklyTrend;
  final List<DonutChartCategory> dynamicCategories;
  final Map<String, double> spentPerCategory;

  DashboardState({
    required this.totalSpent,
    required this.weeklyTrend,
    required this.dynamicCategories,
    required this.spentPerCategory,
  });
}

final dashboardProvider = Provider<DashboardState>((ref) {
  final transactions = ref.watch(transactionListProvider);
  final globalBudget = ref.watch(globalBudgetProvider);
  final categories = ref.watch(categoriesListProvider);

  bool isDateInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return date.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
  }

  bool isDateInCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  double totalSpent = 0.0;
  final Map<String, double> catSum = {};

  final categoryMap = {for (var c in categories) c.toLowerCase(): c};

  String capitalizeCategory(String cat) {
    if (cat.isEmpty) return cat;
    final match = categoryMap[cat.toLowerCase()];
    if (match != null) return match;
    return cat.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  for (var tx in transactions) {
    if (tx.category.toLowerCase() == 'transfer') continue;
    if (!tx.isIncome) {
      if (globalBudget.period == 'weekly') {
        if (!isDateInCurrentWeek(tx.date)) continue;
      } else {
        if (!isDateInCurrentMonth(tx.date)) continue;
      }
      totalSpent += tx.amount;
      
      final normalizedCat = capitalizeCategory(tx.category);
      catSum[normalizedCat] = (catSum[normalizedCat] ?? 0.0) + tx.amount;
    }
  }

  final now = DateTime.now();
  final oldestTrendDay = now.subtract(const Duration(days: 6));
  final oldestDateOnly = DateTime(oldestTrendDay.year, oldestTrendDay.month, oldestTrendDay.day);

  double initialBalance = 0.0;
  final List<double> dailyChanges = List.filled(7, 0.0);

  for (var tx in transactions) {
    if (tx.category.toLowerCase() == 'transfer') continue;

    final txDate = tx.date;
    final txDateOnly = DateTime(txDate.year, txDate.month, txDate.day);

    if (txDateOnly.isBefore(oldestDateOnly)) {
      if (tx.isIncome) {
        initialBalance += tx.amount;
      } else {
        initialBalance -= tx.amount;
      }
    } else {
      final difference = txDateOnly.difference(oldestDateOnly).inDays;
      if (difference >= 0 && difference < 7) {
        final change = tx.isIncome ? tx.amount : -tx.amount;
        dailyChanges[difference] += change;
      }
    }
  }

  double currentBalance = initialBalance;
  final List<double> weeklyTrend = List.generate(7, (index) {
    currentBalance += dailyChanges[index];
    return currentBalance;
  });

  final dynamicCategories = catSum.entries.map((entry) {
    return DonutChartCategory(
      name: entry.key,
      amount: entry.value,
    );
  }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

  return DashboardState(
    totalSpent: totalSpent,
    weeklyTrend: weeklyTrend,
    dynamicCategories: dynamicCategories,
    spentPerCategory: catSum,
  );
});
