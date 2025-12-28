import 'dart:io'; // Needed to check Platform
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'laundry_item.dart';

// NEW: Import the desktop database support
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('laundry.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // NEW: Initialize the database engine for Linux/Windows
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE laundry (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      count INTEGER NOT NULL
    )
    ''');
  }

  Future<int> create(LaundryItem item) async {
    final db = await instance.database;
    return await db.insert('laundry', item.toMap());
  }

  Future<List<LaundryItem>> readAllItems() async {
    final db = await instance.database;
    final result = await db.query('laundry');
    return result.map((json) => LaundryItem.fromMap(json)).toList();
  }

  Future<int> update(LaundryItem item) async {
    final db = await instance.database;
    return db.update(
      'laundry',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'laundry',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}