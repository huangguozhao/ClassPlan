import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import 'database_helper.dart';

/// Course Data Access Object for SQLite operations
class CourseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert a course into the database
  Future<void> insert(Course course) async {
    final db = await _dbHelper.database;
    await db.insert(
      'courses',
      _toMap(course),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple courses
  Future<void> insertAll(List<Course> courses) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final course in courses) {
      batch.insert(
        'courses',
        _toMap(course),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get all courses
  Future<List<Course>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('courses');
    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get courses by semester
  Future<List<Course>> getBySemester(String semesterId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'courses',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update a course
  Future<void> update(Course course) async {
    final db = await _dbHelper.database;
    await db.update(
      'courses',
      _toMap(course),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  /// Delete a course by ID
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

/// Delete all courses
  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('courses');
  }

  // ============ Semester Operations ============

  /// Insert or update a semester
  Future<void> insertSemester(Semester semester) async {
    final db = await _dbHelper.database;
    await db.insert(
      'semesters',
      _semesterToMap(semester),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all semesters
  Future<List<Semester>> getAllSemesters() async {
    final db = await _dbHelper.database;
    final maps = await db.query('semesters');
    return maps.map((map) => _semesterFromMap(map)).toList();
  }

  /// Get semester by ID
  Future<Semester?> getSemesterById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'semesters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _semesterFromMap(maps.first);
  }

  /// Delete a semester by ID
  Future<void> deleteSemester(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'semesters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ Settings Operations ============

  /// Get a setting value by key
  Future<String?> getSetting(String key) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  /// Set a setting value
  Future<void> setSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> _semesterToMap(Semester semester) {
    return {
      'id': semester.id,
      'name': semester.name,
      'startDate': semester.startDate.toIso8601String(),
      'endDate': semester.endDate.toIso8601String(),
      'totalWeeks': semester.totalWeeks,
    };
  }

  Semester _semesterFromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      totalWeeks: map['totalWeeks'] as int,
    );
  }

  Map<String, dynamic> _toMap(Course course) {
    return {
      'id': course.id,
      'name': course.name,
      'semesterId': course.semesterId,
      'teacher': course.teacher,
      'location': course.location,
      'dayOfWeek': course.dayOfWeek,
      'startPeriod': course.startPeriod,
      'endPeriod': course.endPeriod,
      'weekStart': course.weekStart,
      'weekEnd': course.weekEnd,
      'weeks': course.weeks != null ? jsonEncode(course.weeks) : null,
      'colorHex': course.colorHex,
      'extraData': course.extraData != null ? jsonEncode(course.extraData) : null,
    };
  }

  Course _fromMap(Map<String, dynamic> map) {
    List<int>? weeks;
    if (map['weeks'] != null) {
      final weeksList = jsonDecode(map['weeks'] as String) as List<dynamic>;
      weeks = weeksList.cast<int>();
    }

    Map<String, dynamic>? extraData;
    if (map['extraData'] != null) {
      extraData = jsonDecode(map['extraData'] as String) as Map<String, dynamic>;
    }

    return Course(
      id: map['id'] as String,
      name: map['name'] as String,
      semesterId: (map['semesterId'] as String?) ?? 'default',
      teacher: map['teacher'] as String?,
      location: map['location'] as String?,
      dayOfWeek: map['dayOfWeek'] as int,
      startPeriod: map['startPeriod'] as int,
      endPeriod: map['endPeriod'] as int,
      weekStart: map['weekStart'] as int?,
      weekEnd: map['weekEnd'] as int?,
      weeks: weeks,
      colorHex: map['colorHex'] as String?,
      extraData: extraData,
    );
  }
}
