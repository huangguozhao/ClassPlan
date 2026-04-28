import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/course_change_notifier.dart';
import '../../data/repository/local_course_repository.dart';
import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';

/// 周课表状态
class WeeklyScheduleState {
  final int currentWeek;
  final int totalWeeks;
  final DateTime weekStartDate;
  final Map<int, List<Course>> coursesByDay;
  final bool isLoading;
  final Semester? semester;
  final List<Semester> allSemesters;

  WeeklyScheduleState({
    required this.currentWeek,
    required this.totalWeeks,
    required this.weekStartDate,
    required this.coursesByDay,
    this.isLoading = false,
    this.semester,
    this.allSemesters = const [],
  });
}

/// 周课表状态管理
class WeeklyScheduleNotifier extends StateNotifier<WeeklyScheduleState> {
  final LocalCourseRepository _repository;
  StreamSubscription? _subscription;

  WeeklyScheduleNotifier(this._repository)
      : super(WeeklyScheduleState(
          currentWeek: 1,
          totalWeeks: 20,
          weekStartDate: DateTime.now(),
          coursesByDay: {},
          isLoading: true,
        )) {
    _loadSchedule();
    _subscription = CourseChangeNotifier().changes.listen((_) {
      _loadSchedule();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    final semester = await _repository.getCurrentSemester();
    final allSemesters = await _repository.getAllSemesters();
    final now = DateTime.now();
    final week = semester?.currentWeek() ?? 1;
    final totalWeeks = semester?.totalWeeks ?? 20;
    final weekStart = semester?.dateOfWeek(week) ?? now;

    final schedule = await _repository.getWeekSchedule(week, semester ?? Semester(
      id: 'default',
      name: '默认学期',
      startDate: now,
      endDate: now.add(const Duration(days: 139)),
      totalWeeks: 20,
    ));

    state = WeeklyScheduleState(
      currentWeek: week,
      totalWeeks: totalWeeks,
      weekStartDate: weekStart,
      coursesByDay: schedule.coursesByDay,
      isLoading: false,
      semester: semester,
      allSemesters: allSemesters,
    );
  }

  Future<void> switchSemester(String semesterId) async {
    final targetSemester = state.allSemesters.firstWhere(
      (s) => s.id == semesterId,
      orElse: () => state.semester!,
    );

    // 保存为当前学期
    await _repository.saveSemester(targetSemester);

    // 重新加载课表
    await _loadSchedule();
  }

  void goToWeek(int week) {
    if (week < 1 || week > state.totalWeeks) return;
    _loadWeek(week);
  }

  void nextWeek() {
    goToWeek(state.currentWeek + 1);
  }

  void previousWeek() {
    goToWeek(state.currentWeek - 1);
  }

  Future<void> _loadWeek(int week) async {
    var semester = state.semester ?? await _repository.getCurrentSemester();
    if (semester == null) {
      final now = DateTime.now();
      semester = Semester(
        id: 'default',
        name: '默认学期',
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now.add(const Duration(days: 139)),
        totalWeeks: 20,
      );
      await _repository.saveSemester(semester);
    }

    state = state.copyWith(isLoading: true, semester: semester);

    final weekStart = semester.dateOfWeek(week);
    final schedule = await _repository.getWeekSchedule(week, semester);

    state = state.copyWith(
      currentWeek: week,
      weekStartDate: weekStart,
      coursesByDay: schedule.coursesByDay,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    await _loadSchedule();
  }
}

extension WeeklyScheduleStateCopyWith on WeeklyScheduleState {
  WeeklyScheduleState copyWith({
    int? currentWeek,
    int? totalWeeks,
    DateTime? weekStartDate,
    Map<int, List<Course>>? coursesByDay,
    bool? isLoading,
    Semester? semester,
    List<Semester>? allSemesters,
  }) {
    return WeeklyScheduleState(
      currentWeek: currentWeek ?? this.currentWeek,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      coursesByDay: coursesByDay ?? this.coursesByDay,
      isLoading: isLoading ?? this.isLoading,
      semester: semester ?? this.semester,
      allSemesters: allSemesters ?? this.allSemesters,
    );
  }
}

