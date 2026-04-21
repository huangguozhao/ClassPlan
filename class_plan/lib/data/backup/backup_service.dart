import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../repository/local_course_repository.dart';

/// 数据备份与恢复服务
class BackupService {
  final LocalCourseRepository _repository;

  BackupService(this._repository);

  /// 导出所有数据为 JSON 文件
  Future<String> exportToJson() async {
    final courses = await _repository.getAllCourses();
    final semesters = await _repository.getAllSemesters();
    final currentSemester = await _repository.getCurrentSemester();

    final data = {
      'version': 1,
      'exportTime': DateTime.now().toIso8601String(),
      'courses': courses.map(_courseToJson).toList(),
      'semesters': semesters.map(_semesterToJson).toList(),
      'currentSemesterId': currentSemester?.id,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 保存到文件并返回文件路径
  Future<String> exportToFile() async {
    final json = await exportToJson();
    final dir = await getApplicationDocumentsDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/classplan_backup_$dateStr.json');
    await file.writeAsString(json);
    return file.path;
  }

  /// 从 JSON 字符串导入数据
  Future<void> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final version = data['version'] as int?;

    if (version == null || version > 1) {
      throw Exception('不支持的备份版本');
    }

    final courses = (data['courses'] as List<dynamic>)
        .map((c) => _courseFromJson(c as Map<String, dynamic>))
        .toList();

    // 清空现有数据并导入
    await _repository.clearAll();
    await _repository.saveCourses(courses);

    if (data['semesters'] != null) {
      final semesters = (data['semesters'] as List<dynamic>)
          .map((s) => _semesterFromJson(s as Map<String, dynamic>))
          .toList();
      for (final semester in semesters) {
        await _repository.saveSemester(semester);
      }
    }
  }

  /// 从文件导入
  Future<void> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('备份文件不存在');
    }
    final jsonStr = await file.readAsString();
    await importFromJson(jsonStr);
  }

  Map<String, dynamic> _courseToJson(Course c) {
    return {
      'id': c.id,
      'name': c.name,
      'teacher': c.teacher,
      'location': c.location,
      'dayOfWeek': c.dayOfWeek,
      'startPeriod': c.startPeriod,
      'endPeriod': c.endPeriod,
      'weekStart': c.weekStart,
      'weekEnd': c.weekEnd,
      'weeks': c.weeks,
      'colorHex': c.colorHex,
    };
  }

  Course _courseFromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      teacher: json['teacher'] as String?,
      location: json['location'] as String?,
      dayOfWeek: json['dayOfWeek'] as int,
      startPeriod: json['startPeriod'] as int,
      endPeriod: json['endPeriod'] as int,
      weekStart: json['weekStart'] as int?,
      weekEnd: json['weekEnd'] as int?,
      weeks: (json['weeks'] as List<dynamic>?)?.cast<int>(),
      colorHex: json['colorHex'] as String?,
    );
  }

  Map<String, dynamic> _semesterToJson(Semester s) {
    return {
      'id': s.id,
      'name': s.name,
      'startDate': s.startDate.toIso8601String(),
      'endDate': s.endDate.toIso8601String(),
      'totalWeeks': s.totalWeeks,
    };
  }

  Semester _semesterFromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalWeeks: json['totalWeeks'] as int,
    );
  }
}
