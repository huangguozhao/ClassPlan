import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repository/local_course_repository.dart';
import '../../di/app_module.dart';
import '../../domain/model/course.dart';
import '../import/course_edit_screen.dart';
import 'weekly_schedule_state.dart';

final weeklyScheduleProvider =
    StateNotifierProvider<WeeklyScheduleNotifier, WeeklyScheduleState>((ref) {
  return WeeklyScheduleNotifier(getIt<LocalCourseRepository>());
});

class WeeklyScheduleScreen extends ConsumerWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklyScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课表'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _WeekNavigator(state: state, ref: ref),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _WeekScheduleGrid(state: state),
          ),
        ],
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final WeeklyScheduleState state;
  final WidgetRef ref;

  const _WeekNavigator({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');
    final weekLabel = '${dateFormat.format(state.weekStartDate)} 周';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.currentWeek > 1
                ? () => ref.read(weeklyScheduleProvider.notifier).previousWeek()
                : null,
          ),
          GestureDetector(
            onTap: () => _showWeekPicker(context),
            child: Column(
              children: [
                Text(
                  '第 ${state.currentWeek} 周',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  weekLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.currentWeek < state.totalWeeks
                ? () => ref.read(weeklyScheduleProvider.notifier).nextWeek()
                : null,
          ),
        ],
      ),
    );
  }

  void _showWeekPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('选择周次', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: state.totalWeeks,
                  itemBuilder: (context, index) {
                    final week = index + 1;
                    return ListTile(
                      title: Text('第 $week 周'),
                      trailing: week == state.currentWeek
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        ref
                            .read(weeklyScheduleProvider.notifier)
                            .goToWeek(week);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekScheduleGrid extends StatelessWidget {
  final WeeklyScheduleState state;

  const _WeekScheduleGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    const dayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const periods = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 节次列
            Column(
              children: [
                _buildCell(context, '', isHeader: true, width: 40),
                ...periods.map((p) => _buildCell(
                      context,
                      '$p',
                      isHeader: false,
                      width: 40,
                      isPeriodCell: true,
                    )),
              ],
            ),
            // 周一~周日列
            for (int day = 1; day <= 7; day++) ...[
              Column(
                children: [
                  _buildCell(
                    context,
                    dayNames[day],
                    isHeader: true,
                    width: 70,
                    isToday: _isToday(day),
                  ),
                  ...periods.map((period) {
                    final course = _findCourseAt(state, day, period);
                    return _buildCell(
                      context,
                      course?.name ?? '',
                      course: course,
                      isHeader: false,
                      width: 70,
                      isToday: _isToday(day),
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    // 不仅要匹配星期几，还要确认今天在本周范围内
    final isInWeek = !now.isBefore(state.weekStartDate) &&
        !now.isAfter(state.weekStartDate.add(const Duration(days: 6)));
    return now.weekday == day && isInWeek;
  }

  Course? _findCourseAt(WeeklyScheduleState state, int day, int period) {
    final dayCourses = state.coursesByDay[day] ?? [];
    for (final course in dayCourses) {
      if (period >= course.startPeriod && period <= course.endPeriod) {
        return course;
      }
    }
    return null;
  }

  Widget _buildCell(
    BuildContext context,
    String text, {
    bool isHeader = false,
    bool isPeriodCell = false,
    bool isToday = false,
    Course? course,
    required double width,
  }) {
    final bgColor = isToday
        ? Colors.blue.shade50
        : (isHeader ? Colors.grey.shade100 : Colors.white);
    final textColor = isHeader ? Colors.black87 : Colors.black54;

    if (course != null) {
      return GestureDetector(
        onTap: () => _showCourseDetailDialog(context, course),
        child: Container(
          width: width,
          height: 44,
          decoration: BoxDecoration(
            color: _courseColor(course),
            border: Border.all(color: Colors.white, width: 0.5),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                course.name,
                style: const TextStyle(fontSize: 10, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (course.location != null)
                Text(
                  course.location!,
                  style: const TextStyle(fontSize: 8, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  Color _courseColor(Course course) {
    if (course.colorHex != null) {
      try {
        return Color(int.parse(course.colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    // 默认颜色轮换
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[course.name.hashCode % colors.length];
  }

  void _showCourseDetailDialog(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => _CourseDetailDialog(course: course),
    );
  }
}

class _CourseDetailDialog extends StatelessWidget {
  final Course course;

  const _CourseDetailDialog({required this.course});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return AlertDialog(
      title: Text(course.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(icon: Icons.person, label: '教师', value: course.teacher),
            _DetailRow(icon: Icons.location_on, label: '地点', value: course.location),
            _DetailRow(
              icon: Icons.calendar_today,
              label: '时间',
              value: course.dayOfWeek != null
                  ? '${dayNames[course.dayOfWeek! - 1]} ${course.startPeriod}-${course.endPeriod}节'
                  : '未知',
            ),
            _DetailRow(
              icon: Icons.date_range,
              label: '周次',
              value: (course.weekStart != null && course.weekEnd != null)
                  ? '第${course.weekStart}-${course.weekEnd}周'
                  : (course.weekStart != null ? '第${course.weekStart}周起' : '未知'),
            ),
            if (course.weeks != null && course.weeks!.isNotEmpty)
              _DetailRow(
                icon: Icons.filter_list,
                label: '单双周',
                value: _getWeeksLabel(course.weeks!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context); // 关闭弹窗
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseEditScreen(course: course),
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('编辑'),
        ),
      ],
    );
  }

  String _getWeeksLabel(List<int> weeks) {
    if (weeks.length <= 4) {
      return weeks.map((w) => '第$w周').join('、');
    }
    // 如果太多，简化显示
    final odd = weeks.where((w) => w % 2 == 1).toList();
    final even = weeks.where((w) => w % 2 == 0).toList();
    if (odd.length > even.length) {
      return '单周 ${odd.length}门课';
    } else if (even.length > odd.length) {
      return '双周 ${even.length}门课';
    }
    return '${weeks.length}个周次';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              value ?? '未设置',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// 占位：设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Center(child: Text('设置页面（待实现）')),
    );
  }
}
