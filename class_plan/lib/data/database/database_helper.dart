import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite database helper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'class_plan.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create courses table
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        teacher TEXT,
        location TEXT,
        dayOfWeek INTEGER NOT NULL,
        startPeriod INTEGER NOT NULL,
        endPeriod INTEGER NOT NULL,
        weekStart INTEGER,
        weekEnd INTEGER,
        weeks TEXT,
        colorHex TEXT,
        extraData TEXT
      )
    ''');

    // Create semesters table
    await db.execute('''
      CREATE TABLE semesters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        totalWeeks INTEGER NOT NULL
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
