import 'package:uuid/uuid.dart';

import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../../domain/model/week_schedule.dart';
import '../database/course_dao.dart';
import 'course_change_notifier.dart';
import 'course_repository.dart';

/// Local course repository with SQLite persistence
class LocalCourseRepository implements CourseRepository {
  final CourseDao _courseDao = CourseDao();
  final _uuid = const Uuid();

  // In-memory cache
  List<Course> _courses = [];
  bool _initialized = false;

  /// Initialize repository by loading data from database
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _courses = await _courseDao.getAll();
    _initialized = true;
  }

  @override
  Future<void> saveCourse(Course course) async {
    await _ensureInitialized();
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index >= 0) {
      _courses[index] = course;
      await _courseDao.update(course);
    } else {
      _courses.add(course);
      await _courseDao.insert(course);
    }
    CourseChangeNotifier().notify();
  }

  @override
  Future<void> saveCourses(List<Course> courses) async {
    await _ensureInitialized();
    for (final course in courses) {
      // Generate new ID for each course
      final newCourse = course.copyWith(id: _uuid.v4());
      _courses.add(newCourse);
      await _courseDao.insert(newCourse);
    }
    CourseChangeNotifier().notify();
  }

  @override
  Future<List<Course>> getAllCourses() async {
    await _ensureInitialized();
    return List.from(_courses);
  }

  @override
  Future<List<Course>> getCoursesBySemester(String semesterId) async {
    // TODO: Course model has no semesterId field, cannot filter precisely
    // Sprint 1 temporary solution: return all courses
    // Proper implementation requires course-semester relationship
    await _ensureInitialized();
    return List.from(_courses);
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    await _ensureInitialized();
    _courses.removeWhere((c) => c.id == courseId);
    await _courseDao.delete(courseId);
    CourseChangeNotifier().notify();
  }

  @override
  Future<void> clearAll() async {
    _courses.clear();
    await _courseDao.deleteAll();
    CourseChangeNotifier().notify();
  }

  static const String _currentSemesterKey = 'currentSemesterId';

  @override
  Future<void> saveSemester(Semester semester) async {
    await _courseDao.insertSemester(semester);
    // Always set this semester as current when explicitly saved
    await _courseDao.setSetting(_currentSemesterKey, semester.id);
  }

  @override
  Future<Semester?> getCurrentSemester() async {
    final currentId = await _courseDao.getSetting(_currentSemesterKey);
    if (currentId == null) return null;
    return await _courseDao.getSemesterById(currentId);
  }

  @override
  Future<List<Semester>> getAllSemesters() async {
    return await _courseDao.getAllSemesters();
  }

  /// Generate week schedule for a specific week
  Future<WeekSchedule> getWeekSchedule(int weekNumber, Semester semester) async {
    await _ensureInitialized();
    final weekStartDate = semester.dateOfWeek(weekNumber);
    final coursesByDay = <int, List<Course>>{};

    for (int day = 1; day <= 7; day++) {
      final dayCourses = _courses.where((course) {
        return course.dayOfWeek == day && course.isActiveInWeek(weekNumber);
      }).toList();

      // Sort by start period
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
