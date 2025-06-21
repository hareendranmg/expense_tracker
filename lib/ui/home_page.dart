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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    provider.fetchExpenses(); // Initial fetch
    _searchController.addListener(() {
      provider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.grey,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 12,
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            pinned: true,
            expandedHeight: 320.0, // Increased height to better fit content
            flexibleSpace: FlexibleSpaceBar(
              // THE FIX: Use SafeArea to prevent content from being clipped by the status bar.
              background: SafeArea(
                child: _buildChart(context, provider.expenses),
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

  Future<void> _selectFilterDate(BuildContext context) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.filterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      provider.setFilterDate(picked);
    }
  }

  Widget _buildChart(BuildContext context, List<Expense> expensesForMonth) {
    // Get the provider to access the new chart date state.
    final provider = Provider.of<ExpenseProvider>(context);

    if (expensesForMonth.isEmpty) {
      // Show empty state with navigation arrows.
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMonthNavigationRow(context, provider, true), // is Empty = true
          const Spacer(),
          Text(
            "No expenses recorded this month.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const Spacer(),
        ],
      );
    }

    Map<Category, double> categoryTotals = {};
    for (var expense in expensesForMonth) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    double totalExpense = expensesForMonth.fold(
      0,
      (sum, item) => sum + item.amount,
    );

    return FadeInUp(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildMonthNavigationRow(context, provider, false),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: categoryTotals.entries.map((entry) {
                            return PieChartSectionData(
                              color: _getCategoryColor(entry.key),
                              value: entry.value,
                              title:
                                  '${((entry.value / totalExpense) * 100).toStringAsFixed(0)}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 3,
                          centerSpaceRadius: 45,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            NumberFormat.compactCurrency(
                              symbol: '₹',
                              decimalDigits: 2,
                            ).format(totalExpense),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Total",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
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
                            Expanded(
                              child: Text(
                                '${entry.key.toString().split('.').last.capitalize()}: ${NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(entry.value)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildMonthNavigationRow(
    BuildContext context,
    ExpenseProvider provider,
    bool isEmpty,
  ) {
    final chartDate = provider.chartDate;
    final now = DateTime.now();
    final isCurrentMonth =
        chartDate.year == now.year && chartDate.month == now.month;

    return Padding(
      padding: EdgeInsets.only(top: 52),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => provider.goToPreviousMonth(),
          ),
          const Spacer(),
          Text(
            "Expenses for ${DateFormat('MMMM y').format(chartDate)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: isCurrentMonth ? Colors.grey[300] : Colors.black,
            ),
            onPressed: isCurrentMonth ? null : () => provider.goToNextMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<SortBy>(
                value: provider.sortBy,
                underline: Container(),
                items: SortBy.values
                    .map(
                      (sort) => DropdownMenuItem(
                        value: sort,
                        child: Text(
                          sort
                              .toString()
                              .split('.')
                              .last
                              .replaceAll('_', ' ')
                              .capitalize(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null)
                    Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    ).setSortBy(value);
                },
              ),
              DropdownButton<Category?>(
                value: provider.filterCategory,
                hint: const Text('All Categories'),
                underline: Container(),
                items: [
                  const DropdownMenuItem<Category?>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...Category.values.map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat.toString().split('.').last.capitalize()),
                    ),
                  ),
                ],
                onChanged: (value) => Provider.of<ExpenseProvider>(
                  context,
                  listen: false,
                ).setFilterCategory(value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: InputChip(
              avatar: Icon(
                provider.filterDate != null
                    ? Icons.event_available
                    : Icons.calendar_today_outlined,
                color: provider.filterDate != null
                    ? Colors.deepPurple[800]
                    : Colors.black54,
                size: 20,
              ),
              label: Text(
                provider.filterDate == null
                    ? 'Filter by Date'
                    : DateFormat.yMMMd().format(provider.filterDate!),
              ),
              selected: provider.filterDate != null,
              onPressed: () => _selectFilterDate(context),
              onDeleted: provider.filterDate != null
                  ? () => Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    ).setFilterDate(null)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.expenses.isEmpty)
          return const SliverToBoxAdapter(child: SizedBox.shrink());
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
            onPressed: (ctx) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditExpensePage(expense: expense),
              ),
            ),
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
                  duration: Duration(seconds: 2),
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
            NumberFormat.currency(
              symbol: '₹',
              decimalDigits: 2,
            ).format(expense.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
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
        return Colors.grey.shade500;
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
        return Icons.theaters;
      case Category.other:
        return Icons.more_horiz;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
