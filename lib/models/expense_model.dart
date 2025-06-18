// lib/models/expense_model.dart

// An enum to represent the different expense categories
enum Category { food, transport, work, entertainment, other }

class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  // Method to convert an Expense object to a Map, suitable for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(), // Store date as a string
      'category': category.toString().split('.').last, // Store enum as string
    };
  }

  // Factory constructor to create an Expense object from a Map (from the database).
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: Category.values.firstWhere(
        (e) => e.toString() == 'Category.${map['category']}',
        orElse: () => Category.other,
      ),
    );
  }
}
