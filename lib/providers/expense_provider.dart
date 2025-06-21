// lib/providers/expense_provider.dart

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense_model.dart';

// Enum for sorting options
enum SortBy { date_newest, date_oldest, amount_high, amount_low }

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  SortBy _sortBy = SortBy.date_newest;
  Category? _filterCategory;
  String _searchQuery = '';
  DateTime? _filterDate;
  DateTime _chartDate = DateTime.now();

  List<Expense> get expenses {
    List<Expense> filteredExpenses = _expenses;

    filteredExpenses = filteredExpenses.where((expense) {
      return expense.date.year == _chartDate.year &&
          expense.date.month == _chartDate.month;
    }).toList();

    if (_filterDate != null) {
      filteredExpenses = filteredExpenses.where((exp) {
        // Compare year, month, and day, ignoring the time part of DateTime
        return exp.date.year == _filterDate!.year &&
            exp.date.month == _filterDate!.month &&
            exp.date.day == _filterDate!.day;
      }).toList();
    }

    if (_filterCategory != null) {
      filteredExpenses = filteredExpenses
          .where((exp) => exp.category == _filterCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredExpenses = filteredExpenses
          .where(
            (exp) =>
                exp.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filteredExpenses;
  }

  SortBy get sortBy => _sortBy;
  Category? get filterCategory => _filterCategory;
  DateTime? get filterDate => _filterDate;
  DateTime get chartDate => _chartDate;

  ExpenseProvider() {
    fetchExpenses();
  }

  String _getOrderBy() {
    switch (_sortBy) {
      case SortBy.date_newest:
        return 'date DESC';
      case SortBy.date_oldest:
        return 'date ASC';
      case SortBy.amount_high:
        return 'amount DESC';
      case SortBy.amount_low:
        return 'amount ASC';
    }
  }

  Future<void> fetchExpenses() async {
    _expenses = await _dbHelper.queryAllExpenses(orderBy: _getOrderBy());
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insert(expense);
    await fetchExpenses(); // Refetch to get the latest sorted list
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.update(expense);
    await fetchExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.delete(id);
    await fetchExpenses();
  }

  void setSortBy(SortBy sortBy) {
    _sortBy = sortBy;
    fetchExpenses(); // Refetch with new sorting
  }

  void setFilterCategory(Category? category) {
    _filterCategory = category;
    notifyListeners(); // Just notify, no need to refetch as filtering is done on the client side
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners(); // Notify listeners to rebuild the UI with the filtered list
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void goToPreviousMonth() {
    _chartDate = DateTime(_chartDate.year, _chartDate.month - 1, 1);
    notifyListeners(); // Tell the UI to rebuild the chart
  }

  void goToNextMonth() {
    final now = DateTime.now();
    // Prevent navigating to a future month.
    if (_chartDate.year == now.year && _chartDate.month == now.month) {
      return;
    }
    _chartDate = DateTime(_chartDate.year, _chartDate.month + 1, 1);
    notifyListeners(); // Tell the UI to rebuild the chart
  }
}
