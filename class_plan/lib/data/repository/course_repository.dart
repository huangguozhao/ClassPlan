import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../../domain/model/week_schedule.dart';

/// 课程仓库接口（领域层定义，数据层实现）
abstract class CourseRepository {
  /// 保存一门课程
  Future<void> saveCourse(Course course);

  /// 批量保存课程
  Future<void> saveCourses(List<Course> courses);

  /// 获取所有课程
  Future<List<Course>> getAllCourses();

  /// 获取指定学期的课程
  Future<List<Course>> getCoursesBySemester(String semesterId);

  /// 删除课程
  Future<void> deleteCourse(String courseId);

  /// 清空所有课程
  Future<void> clearAll();

  /// 保存学期信息
  Future<void> saveSemester(Semester semester);

  /// 获取当前学期
  Future<Semester?> getCurrentSemester();

  /// 获取所有学期
  Future<List<Semester>> getAllSemesters();
}
