// lib/ui/home_page.dart
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'add_edit_expense_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Expense Tracker'),
            pinned: true,
            expandedHeight: 250.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(
                  top: 80.0,
                ), // Adjust for app bar height
                child: Consumer<ExpenseProvider>(
                  builder: (context, provider, child) {
                    return _buildChart(context, provider.expenses);
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildControls(context)),
          _buildExpenseList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditExpensePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const Center(child: Text("No expenses yet. Add one!"));
    }

    Map<Category, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    double totalExpense = expenses.fold(0, (sum, item) => sum + item.amount);

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.map((entry) {
                    return PieChartSectionData(
                      color: _getCategoryColor(entry.key),
                      value: entry.value,
                      title:
                          '${((entry.value / totalExpense) * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
                swapAnimationDuration: const Duration(milliseconds: 750),
                swapAnimationCurve: Curves.easeInOutCubic,
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categoryTotals.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: _getCategoryColor(entry.key),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key.toString().split('.').last.capitalize()}: ${NumberFormat.currency(symbol: '₹').format(entry.value)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final currentSortBy = Provider.of<ExpenseProvider>(context).sortBy;
    final currentFilter = Provider.of<ExpenseProvider>(context).filterCategory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sorting Dropdown
          DropdownButton<SortBy>(
            value: currentSortBy,
            underline: Container(),
            items: SortBy.values.map((sort) {
              return DropdownMenuItem(
                value: sort,
                child: Text(
                  sort
                      .toString()
                      .split('.')
                      .last
                      .replaceAll('_', ' ')
                      .capitalize(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                provider.setSortBy(value);
              }
            },
          ),
          // Filtering Dropdown
          DropdownButton<Category?>(
            value: currentFilter,
            hint: const Text('Filter'),
            underline: Container(),
            items: [
              const DropdownMenuItem<Category?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...Category.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.toString().split('.').last.capitalize()),
                );
              }),
            ],
            onChanged: (value) {
              provider.setFilterCategory(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.expenses.isEmpty && provider.filterCategory != null) {
          return const SliverFillRemaining(
            child: Center(child: Text("No expenses found for this filter.")),
          );
        }
        if (provider.expenses.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(""),
            ), // The chart already says "No expenses yet"
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final expense = provider.expenses[index];
            return FadeInUp(
              delay: Duration(milliseconds: 100 * index),
              child: _buildExpenseListItem(context, expense),
            );
          }, childCount: provider.expenses.length),
        );
      },
    );
  }

  Widget _buildExpenseListItem(BuildContext context, Expense expense) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    return Slidable(
      key: ValueKey(expense.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (ctx) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditExpensePage(expense: expense),
                ),
              );
            },
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (ctx) {
              provider.deleteExpense(expense.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 3,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: _getCategoryColor(
              expense.category,
            ).withOpacity(0.2),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: _getCategoryColor(expense.category),
            ),
          ),
          title: Text(
            expense.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(DateFormat.yMMMd().format(expense.date)),
          trailing: Text(
            NumberFormat.currency(symbol: '₹').format(expense.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(Category category) {
    switch (category) {
      case Category.food:
        return Colors.orange;
      case Category.transport:
        return Colors.blue;
      case Category.work:
        return Colors.green;
      case Category.entertainment:
        return Colors.purple;
      case Category.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.food:
        return Icons.fastfood;
      case Category.transport:
        return Icons.directions_car;
      case Category.work:
        return Icons.work;
      case Category.entertainment:
        return Icons.movie;
      case Category.other:
        return Icons.more_horiz;
    }
  }
}

// Simple extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
