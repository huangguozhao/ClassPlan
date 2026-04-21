import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/model/course.dart';
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

  /// Get courses by semester (currently returns all, semester filtering not implemented)
  Future<List<Course>> getBySemester(String semesterId) async {
    // TODO: Implement semester filtering when Course has semesterId
    return getAll();
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

  Map<String, dynamic> _toMap(Course course) {
    return {
      'id': course.id,
      'name': course.name,
      'teacher': course.teacher,
      'location': course.location,
      'dayOfWeek': course.dayOfWeek,
      'startPeriod': course.startPeriod,
      'endPeriod': course.endPeriod,
      'weekStart': course.weekStart,
      'weekEnd': course.weekEnd,
      'weeks': course.weeks != null ? jsonEncode(course.weeks) : null,
      'colorHex': course.colorHex,
    };
  }

  Course _fromMap(Map<String, dynamic> map) {
    List<int>? weeks;
    if (map['weeks'] != null) {
      final weeksList = jsonDecode(map['weeks'] as String) as List<dynamic>;
      weeks = weeksList.cast<int>();
    }

    return Course(
      id: map['id'] as String,
      name: map['name'] as String,
      teacher: map['teacher'] as String?,
      location: map['location'] as String?,
      dayOfWeek: map['dayOfWeek'] as int,
      startPeriod: map['startPeriod'] as int,
      endPeriod: map['endPeriod'] as int,
      weekStart: map['weekStart'] as int?,
      weekEnd: map['weekEnd'] as int?,
      weeks: weeks,
      colorHex: map['colorHex'] as String?,
    );
  }
}
