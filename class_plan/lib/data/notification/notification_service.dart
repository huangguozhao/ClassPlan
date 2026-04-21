import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';

/// 课程提醒通知服务
class ReminderService {
  static final ReminderService _instance = ReminderService._();
  factory ReminderService() => _instance;
  ReminderService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 记录每个课程的通知 ID（用于精确取消）
  final _courseNotificationIds = <String, List<int>>{};

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  /// 请求通知权限（Android 13+）
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// 为一门课程设置提醒
  Future<void> scheduleCourseReminder({
    required Course course,
    required Semester semester,
    required int minutesBefore, // 上课前多少分钟提醒
  }) async {
    await initialize();

    // 先取消该课程的旧提醒
    await cancelCourseReminders(course.id);

    // 计算下一次上课时间
    final now = DateTime.now();
    final currentWeek = semester.currentWeek() ?? 1;
    final ids = <int>[];

    for (int week = currentWeek; week <= semester.totalWeeks; week++) {
      if (!course.isActiveInWeek(week)) continue;

      final weekDate = semester.dateOfWeek(week);
      // dayOfWeek: 1=周一, 7=周日
      final courseDate = weekDate.add(Duration(days: course.dayOfWeek - 1));

      // 假设每天第N节课的上课时间（简化计算）
      // 实际上课时间应根据学校作息时间
      final periodStartHour = _estimatePeriodHour(course.startPeriod);
      final courseDateTime = DateTime(
        courseDate.year,
        courseDate.month,
        courseDate.day,
        periodStartHour,
        0,
      );

      // 提醒时间
      final reminderTime = courseDateTime.subtract(Duration(minutes: minutesBefore));

      if (reminderTime.isBefore(now)) continue;

      final notificationId = '${course.id}_$week'.hashCode.abs();
      ids.add(notificationId);

      await _notifications.zonedSchedule(
        notificationId,
        '课前提醒',
        '${course.name} 将于 $minutesBefore 分钟后开始${course.location != null ? '（${course.location}）' : ''}',
        tz.TZDateTime.from(reminderTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'course_reminders',
            '课程提醒',
            channelDescription: '上课前提醒',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              '${course.name}\n'
              '${course.location ?? '未知地点'}\n'
              '${course.teacher != null ? '教师：${course.teacher}' : ''}',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    }

    _courseNotificationIds[course.id] = ids;
  }

  /// 取消一门课程的所有提醒（只取消该课程的，不影响其他）
  Future<void> cancelCourseReminders(String courseId) async {
    final ids = _courseNotificationIds[courseId];
    if (ids != null) {
      for (final id in ids) {
        await _notifications.cancel(id);
      }
      _courseNotificationIds.remove(courseId);
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    _courseNotificationIds.clear();
  }

  /// 估算某节课的大致上课时间（小时）
  int _estimatePeriodHour(int period) {
    // 假设上午8点开始第1节课，每节课45分钟，课间10分钟
    // 这只是估算，实际应从学校作息时间表读取
    const startHour = 8;
    const periodDuration = 45;
    const breakDuration = 10;
    final totalMinutes = (period - 1) * (periodDuration + breakDuration) + startHour * 60;
    return totalMinutes ~/ 60;
  }
}
