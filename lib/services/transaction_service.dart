import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

final transactionListProvider = StateNotifierProvider<TransactionListNotifier, List<ExpenseTransaction>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return TransactionListNotifier(service);
});

class TransactionListNotifier extends StateNotifier<List<ExpenseTransaction>> {
  final TransactionService _service;
  int _currentSession = 0;

  TransactionListNotifier(this._service) : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final session = ++_currentSession;
    final list = await _service.getTransactions();
    if (session == _currentSession) {
      state = list;
    }
  }

  Future<void> addTransaction(ExpenseTransaction tx) async {
    final updatedList = [tx, ...state]..sort((a, b) => b.date.compareTo(a.date));
    state = updatedList;
    await _service.saveTransactions(updatedList, overwrite: true);
  }

  Future<void> addTransactions(List<ExpenseTransaction> txs) async {
    final Map<String, ExpenseTransaction> merged = {
      for (var tx in state) tx.id: tx,
    };
    for (var tx in txs) {
      merged[tx.id] = tx;
    }
    final updatedList = merged.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    state = updatedList;
    await _service.saveTransactions(updatedList, overwrite: true);
  }

  Future<void> updateTransaction(ExpenseTransaction tx) async {
    final updatedList = state.map((item) => item.id == tx.id ? tx : item).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    state = updatedList;
    await _service.saveTransactions(updatedList, overwrite: true);
  }

  Future<void> updateTransfer({
    required String groupId,
    required String fromAccount,
    required String toAccount,
    required double amount,
    required DateTime date,
    required String notes,
  }) async {
    final list = List<ExpenseTransaction>.from(state);
    final sourceLegIndex = list.indexWhere((tx) => tx.groupId == groupId && !tx.isIncome);
    final destLegIndex = list.indexWhere((tx) => tx.groupId == groupId && tx.isIncome);

    if (sourceLegIndex != -1 && destLegIndex != -1) {
      final sourceLeg = list[sourceLegIndex];
      final destLeg = list[destLegIndex];

      list[sourceLegIndex] = sourceLeg.copyWith(
        paymentMethod: fromAccount,
        amount: amount,
        date: date,
        notes: notes,
        merchant: 'Transfer to $toAccount',
      );

      list[destLegIndex] = destLeg.copyWith(
        paymentMethod: toAccount,
        amount: amount,
        date: date,
        notes: notes,
        merchant: 'Transfer from $fromAccount',
      );

      list.sort((a, b) => b.date.compareTo(a.date));
      state = list;
      await _service.saveTransactions(list, overwrite: true);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final toDeleteIndex = state.indexWhere((tx) => tx.id == id);
    if (toDeleteIndex == -1) return;

    final toDelete = state[toDeleteIndex];
    final updatedList = List<ExpenseTransaction>.from(state);
    if (toDelete.category.toLowerCase() == 'transfer' && toDelete.groupId != null) {
      updatedList.removeWhere((tx) => tx.groupId == toDelete.groupId);
    } else {
      updatedList.removeAt(toDeleteIndex);
    }
    state = updatedList;
    await _service.saveTransactions(updatedList, overwrite: true);
  }

  Future<void> clearTransactions() async {
    state = [];
    await _service.clearAll();
  }

  Future<void> importTransactions(List<ExpenseTransaction> txs, {bool overwrite = false}) async {
    if (overwrite) {
      final updatedList = List<ExpenseTransaction>.from(txs)..sort((a, b) => b.date.compareTo(a.date));
      state = updatedList;
      await _service.saveTransactions(updatedList, overwrite: true);
    } else {
      final Map<String, ExpenseTransaction> merged = {
        for (var tx in state) tx.id: tx,
      };
      for (var tx in txs) {
        merged[tx.id] = tx;
      }
      final updatedList = merged.values.toList()..sort((a, b) => b.date.compareTo(a.date));
      state = updatedList;
      await _service.saveTransactions(updatedList, overwrite: true);
    }
  }
}

class TransactionService {
  static const String _key = 'transactions_json';

  Future<List<ExpenseTransaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // One-time clear of old mock data so the user starts with a clean database
    if (!(prefs.getBool('is_mock_cleared_v3') ?? false)) {
      await prefs.remove(_key);
      await prefs.setBool('is_mock_cleared_v3', true);
    }
    
    await prefs.reload(); // Force reload from disk to sync with native overlay instantly!
    final jsonStr = prefs.getString(_key);

    if (jsonStr == null || jsonStr == '[]') {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((item) => ExpenseTransaction.fromMap(item)).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
    } catch (e) {
      print("Error decoding transactions: $e");
      return [];
    }
  }

  Future<void> saveTransaction(ExpenseTransaction tx) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getTransactions();
    list.add(tx);
    await prefs.setString(_key, json.encode(list.map((e) => e.toMap()).toList()));
  }

  Future<void> updateTransaction(ExpenseTransaction updatedTx) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getTransactions();
    final index = list.indexWhere((tx) => tx.id == updatedTx.id);
    if (index != -1) {
      list[index] = updatedTx;
      await prefs.setString(_key, json.encode(list.map((e) => e.toMap()).toList()));
    }
  }

  Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getTransactions();
    final toDeleteIndex = list.indexWhere((tx) => tx.id == id);
    if (toDeleteIndex != -1) {
      final toDelete = list[toDeleteIndex];
      if (toDelete.category.toLowerCase() == 'transfer' && toDelete.groupId != null) {
        list.removeWhere((tx) => tx.groupId == toDelete.groupId);
      } else {
        list.removeAt(toDeleteIndex);
      }
      await prefs.setString(_key, json.encode(list.map((e) => e.toMap()).toList()));
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> saveTransactions(List<ExpenseTransaction> txs, {bool overwrite = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<ExpenseTransaction> currentList = [];
    if (!overwrite) {
      currentList = await getTransactions();
      final Map<String, ExpenseTransaction> merged = {
        for (var tx in currentList) tx.id: tx,
      };
      for (var tx in txs) {
        merged[tx.id] = tx;
      }
      currentList = merged.values.toList();
    } else {
      currentList = txs;
    }
    await prefs.setString(_key, json.encode(currentList.map((e) => e.toMap()).toList()));
  }
}
