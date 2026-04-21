import 'package:flutter/material.dart';

import '../../../domain/model/structured_course.dart';
import 'draggable_course_card.dart';

/// 时间表网格编辑器
/// 用于在导入确认页面接收拖拽的课程并显示在对应位置
class TimetableGridEditor extends StatelessWidget {
  /// 所有解析的课程
  final List<StructuredCourse> courses;

  /// 已放置的课程：courseIndex -> (dayOfWeek, startPeriod)
  final Map<int, Map<String, int>> placedCourses;

  /// 课程被放置到网格时的回调
  final void Function(int courseIndex, int dayOfWeek, int startPeriod, int endPeriod) onCourseDropped;

  /// 被移除的课程索引（重新放回顶部）
  final void Function(int courseIndex)? onCourseRemoved;

  const TimetableGridEditor({
    super.key,
    required this.courses,
    required this.placedCourses,
    required this.onCourseDropped,
    this.onCourseRemoved,
  });

  static const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const periods = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 表头行：星期名称
        _buildHeaderRow(),
        // 时间表网格
        Expanded(
          child: _buildGrid(),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // 左上角空白
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text('节次', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          // 星期标题
          ...List.generate(7, (index) {
            return Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  dayNames[index],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return SingleChildScrollView(
      child: Column(
        children: periods.map((period) => _buildPeriodRow(period)).toList(),
      ),
    );
  }

  Widget _buildPeriodRow(int period) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 50,
          width: constraints.maxWidth,
          child: Row(
            children: [
              // 节次标签
              Container(
                width: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(right: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Text(
                  '$period',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              // 7天的格子
              ...List.generate(7, (dayIndex) {
                final dayOfWeek = dayIndex + 1;
                return Expanded(
                  child: _TimetableCell(
                    period: period,
                    dayOfWeek: dayOfWeek,
                    courses: courses,
                    placedCourses: placedCourses,
                    onCourseDropped: onCourseDropped,
                    onCourseRemoved: onCourseRemoved,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

/// 时间表格子（DragTarget）
class _TimetableCell extends StatelessWidget {
  final int period;
  final int dayOfWeek;
  final List<StructuredCourse> courses;
  final Map<int, Map<String, int>> placedCourses;
  final void Function(int courseIndex, int dayOfWeek, int startPeriod, int endPeriod) onCourseDropped;
  final void Function(int courseIndex)? onCourseRemoved;

  const _TimetableCell({
    required this.period,
    required this.dayOfWeek,
    required this.courses,
    required this.placedCourses,
    required this.onCourseDropped,
    this.onCourseRemoved,
  });

  @override
  Widget build(BuildContext context) {
    // 找出放在这个位置的课程
    final placedHere = <MapEntry<int, StructuredCourse>>[];
    for (final entry in placedCourses.entries) {
      final courseIndex = entry.key;
      final pos = entry.value;
      if (pos['dayOfWeek'] == dayOfWeek && pos['startPeriod'] == period) {
        if (courseIndex < courses.length) {
          placedHere.add(MapEntry(courseIndex, courses[courseIndex]));
        }
      }
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final courseIndex = details.data;
        // 不能接受已经在这个位置的课程
        final existing = placedCourses[courseIndex];
        if (existing != null && existing['dayOfWeek'] == dayOfWeek && existing['startPeriod'] == period) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final courseIndex = details.data;
        // 获取原课程的时长（endPeriod - startPeriod + 1）
        final course = courses[courseIndex];
        final duration = (course.endPeriod ?? course.startPeriod ?? 1) - (course.startPeriod ?? 1) + 1;
        // 拖拽放置时，endPeriod = startPeriod + duration - 1
        final endPeriod = period + duration - 1;
        onCourseDropped(courseIndex, dayOfWeek, period, endPeriod);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isHovering ? Colors.blue.shade50 : Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade200, width: 0.5),
              bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: placedHere.isEmpty
              ? (isHovering
                  ? Center(
                      child: Icon(Icons.add, color: Colors.blue.shade300, size: 20),
                    )
                  : null)
              : _buildPlacedCourses(placedHere),
        );
      },
    );
  }

  Widget _buildPlacedCourses(List<MapEntry<int, StructuredCourse>> placedHere) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: placedHere.map((entry) {
        final courseIndex = entry.key;
        final course = entry.value;
        return GestureDetector(
          onLongPress: () {
            // 长按移除课程，放回顶部
            onCourseRemoved?.call(courseIndex);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _courseColor(course),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              course.name,
              style: const TextStyle(fontSize: 10, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _courseColor(StructuredCourse course) {
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
}