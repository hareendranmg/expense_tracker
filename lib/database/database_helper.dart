// lib/database/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense_model.dart';

class DatabaseHelper {
  static const _databaseName = "ExpenseTracker.db";
  static const _databaseVersion = 1;
  static const table = 'expenses';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database and create it if it doesn't exist
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            category TEXT NOT NULL
          )
          ''');
  }

  // --- Helper methods ---

  // Insert an expense into the database
  Future<int> insert(Expense expense) async {
    Database db = await instance.database;
    return await db.insert(table, expense.toMap());
  }

  // Query all expenses. Can be sorted.
  Future<List<Expense>> queryAllExpenses({String? orderBy}) async {
    Database db = await instance.database;
    final maps = await db.query(table, orderBy: orderBy);
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Update an expense
  Future<int> update(Expense expense) async {
    Database db = await instance.database;
    return await db.update(
      table,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
