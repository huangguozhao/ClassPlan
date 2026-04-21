/// 学期领域模型

class Semester {
  final String id;
  final String name;            // 如"2024-2025学年第一学期"
  final DateTime startDate;     // 学期开始日期（通常是开学第一天周一）
  final DateTime endDate;       // 学期结束日期
  final int totalWeeks;         // 学期总周数

  Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.totalWeeks,
  });

  /// 根据日期计算是第几周
  int weekNumberOf(DateTime date) {
    final diff = date.difference(startDate).inDays;
    if (diff < 0) return 0;
    return (diff ~/ 7) + 1;
  }

  /// 获取某周次的起始日期
  DateTime dateOfWeek(int week) {
    return startDate.add(Duration(days: (week - 1) * 7));
  }

  /// 获取今天的周次（如果不在学期内返回null）
  int? currentWeek() {
    final now = DateTime.now();
    final week = weekNumberOf(now);
    if (week < 1 || week > totalWeeks) return null;
    return week;
  }
}
