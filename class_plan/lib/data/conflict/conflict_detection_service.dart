import '../repository/local_course_repository.dart';
import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';

/// 课程冲突类型
enum ConflictType {
  time,     // 时间冲突：同一时间有多门课
  location, // 地点冲突：同一地点同时有多门课
}

/// 冲突信息
class CourseConflict {
  final Course course1;
  final Course course2;
  final ConflictType type;
  final String description;

  CourseConflict({
    required this.course1,
    required this.course2,
    required this.type,
    required this.description,
  });
}

/// 课程冲突检测服务
class ConflictDetectionService {
  final LocalCourseRepository _repository;

  ConflictDetectionService(this._repository);

  /// 检测所有冲突
  Future<List<CourseConflict>> detectAllConflicts({String? semesterId}) async {
    final courses = semesterId != null
        ? await _repository.getCoursesBySemester(semesterId)
        : await _repository.getAllCourses();

    final conflicts = <CourseConflict>[];

    // 时间冲突检测
    conflicts.addAll(_detectTimeConflicts(courses));

    // 地点冲突检测
    conflicts.addAll(_detectLocationConflicts(courses));

    return conflicts;
  }

  /// 检测时间冲突（同一天同一时段有多门课）
  List<CourseConflict> _detectTimeConflicts(List<Course> courses) {
    final conflicts = <CourseConflict>[];

    // 按星期分组
    final byDay = <int, List<Course>>{};
    for (final course in courses) {
      byDay.putIfAbsent(course.dayOfWeek, () => []).add(course);
    }

    for (final day in byDay.keys) {
      final dayCourses = byDay[day]!;
      // 两两比较检查时间重叠
      for (int i = 0; i < dayCourses.length; i++) {
        for (int j = i + 1; j < dayCourses.length; j++) {
          final c1 = dayCourses[i];
          final c2 = dayCourses[j];

          if (_hasTimeOverlap(c1, c2)) {
            conflicts.add(CourseConflict(
              course1: c1,
              course2: c2,
              type: ConflictType.time,
              description: '${c1.name} 和 ${c2.name} 在星期${_dayName(c1.dayOfWeek)} ${c1.startPeriod}-${c1.endPeriod}节 时间冲突',
            ));
          }
        }
      }
    }

    return conflicts;
  }

  /// 检测地点冲突（同一地点同时有多门课）
  List<CourseConflict> _detectLocationConflicts(List<Course> courses) {
    final conflicts = <CourseConflict>[];

    // 过滤掉没有地点的课程
    final coursesWithLocation = courses.where((c) =>
        c.location != null && c.location!.isNotEmpty).toList();

    // 按地点分组
    final byLocation = <String, List<Course>>{};
    for (final course in coursesWithLocation) {
      byLocation.putIfAbsent(course.location!, () => []).add(course);
    }

    for (final location in byLocation.keys) {
      final locCourses = byLocation[location]!;
      // 按星期分组
      final byDay = <int, List<Course>>{};
      for (final course in locCourses) {
        byDay.putIfAbsent(course.dayOfWeek, () => []).add(course);
      }

      for (final day in byDay.keys) {
        final dayCourses = byDay[day]!;
        // 两两比较检查时间重叠
        for (int i = 0; i < dayCourses.length; i++) {
          for (int j = i + 1; j < dayCourses.length; j++) {
            final c1 = dayCourses[i];
            final c2 = dayCourses[j];

            if (_hasTimeOverlap(c1, c2)) {
              conflicts.add(CourseConflict(
                course1: c1,
                course2: c2,
                type: ConflictType.location,
                description: '${c1.name} 和 ${c2.name} 都在 ${c1.location} 星期${_dayName(c1.dayOfWeek)} ${c1.startPeriod}-${c1.endPeriod}节',
              ));
            }
          }
        }
      }
    }

    return conflicts;
  }

  /// 判断两门课程时间是否重叠
  bool _hasTimeOverlap(Course c1, Course c2) {
    // 检查周次是否有交集
    if (!_hasWeekOverlap(c1, c2)) return false;

    // 检查节次是否有交集
    return !(c1.endPeriod < c2.startPeriod || c2.endPeriod < c1.startPeriod);
  }

  /// 判断两门课程周次是否有交集
  bool _hasWeekOverlap(Course c1, Course c2) {
    // 如果都没有周次限制，默认每周都上，有冲突
    if (c1.weeks == null && c2.weeks == null) return true;

    // 如果一个有周次限制，另一个没有，有冲突（假设另一个每周都上）
    if (c1.weeks == null) return true;
    if (c2.weeks == null) return true;

    // 检查具体周次是否有交集
    for (final week in c1.weeks!) {
      if (c2.weeks!.contains(week)) return true;
    }

    // 检查周范围是否有交集
    if (c1.weekStart != null && c1.weekEnd != null &&
        c2.weekStart != null && c2.weekEnd != null) {
      // 周范围重叠检查
      if (c1.weekStart! <= c2.weekEnd! && c2.weekStart! <= c1.weekEnd!) {
        return true;
      }
    }

    return false;
  }

  String _dayName(int day) {
    const names = ['', '一', '二', '三', '四', '五', '六', '日'];
    return names[day];
  }
}

/// 冲突检测结果
class ConflictDetectionResult {
  final List<CourseConflict> timeConflicts;
  final List<CourseConflict> locationConflicts;

  ConflictDetectionResult({
    required this.timeConflicts,
    required this.locationConflicts,
  });

  int get totalCount => timeConflicts.length + locationConflicts.length;
  bool get hasConflicts => totalCount > 0;
}