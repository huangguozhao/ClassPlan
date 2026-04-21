import 'package:uuid/uuid.dart';

import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../../domain/model/week_schedule.dart';
import 'course_change_notifier.dart';
import 'course_repository.dart';

/// 内存实现的课程仓库（Sprint 1 临时方案）
/// 后续替换为 Room 数据库实现

class LocalCourseRepository implements CourseRepository {
  final _courses = <Course>[];
  final _semesters = <Semester>[];
  Semester? _currentSemester;
  final _uuid = const Uuid();

  @override
  Future<void> saveCourse(Course course) async {
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index >= 0) {
      _courses[index] = course;
    } else {
      _courses.add(course);
    }
    CourseChangeNotifier().notify();
  }

  @override
  Future<void> saveCourses(List<Course> courses) async {
    for (final course in courses) {
      // 生成新ID
      final newCourse = course.copyWith(id: _uuid.v4());
      _courses.add(newCourse);
    }
    CourseChangeNotifier().notify();
  }

  @override
  Future<List<Course>> getAllCourses() async {
    return List.from(_courses);
  }

  @override
  Future<List<Course>> getCoursesBySemester(String semesterId) async {
    // TODO: Course 模型暂无 semesterId 字段，无法精确按学期筛选
    // Sprint 1 临时方案：返回所有课程
    // 正确实现需要课程和学期关联（需持久化层支持）
    return List.from(_courses);
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    _courses.removeWhere((c) => c.id == courseId);
    CourseChangeNotifier().notify();
  }

  @override
  Future<void> clearAll() async {
    _courses.clear();
    CourseChangeNotifier().notify();
  }

  @override
  Future<void> saveSemester(Semester semester) async {
    final index = _semesters.indexWhere((s) => s.id == semester.id);
    if (index >= 0) {
      _semesters[index] = semester;
    } else {
      _semesters.add(semester);
    }
    _currentSemester ??= semester;
    CourseChangeNotifier().notify();
  }

  @override
  Future<Semester?> getCurrentSemester() async {
    return _currentSemester;
  }

  @override
  Future<List<Semester>> getAllSemesters() async {
    return List.from(_semesters);
  }

  /// 生成指定周的课表
  Future<WeekSchedule> getWeekSchedule(int weekNumber, Semester semester) async {
    final weekStartDate = semester.dateOfWeek(weekNumber);
    final coursesByDay = <int, List<Course>>{};

    for (int day = 1; day <= 7; day++) {
      final dayCourses = _courses.where((course) {
        return course.dayOfWeek == day && course.isActiveInWeek(weekNumber);
      }).toList();

      // 按开始节次排序
      dayCourses.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
      coursesByDay[day] = dayCourses;
    }

    return WeekSchedule(
      weekNumber: weekNumber,
      weekStartDate: weekStartDate,
      coursesByDay: coursesByDay,
    );
  }
}
