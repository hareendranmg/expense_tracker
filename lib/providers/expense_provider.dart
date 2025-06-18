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

  List<Expense> get expenses {
    List<Expense> filteredExpenses = _expenses;
    if (_filterCategory != null) {
      filteredExpenses = filteredExpenses
          .where((exp) => exp.category == _filterCategory)
          .toList();
    }
    return filteredExpenses;
  }

  SortBy get sortBy => _sortBy;
  Category? get filterCategory => _filterCategory;

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
}
