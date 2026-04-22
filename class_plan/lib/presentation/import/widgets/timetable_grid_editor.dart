import 'package:flutter/material.dart';

import '../../../domain/model/structured_course.dart';
import 'draggable_course_card.dart';

/// 时间表网格编辑器
/// 用于在导入确认页面接收拖拽的课程并显示在对应位置
class TimetableGridEditor extends StatelessWidget {
  /// 所有解析的课程
  final List<StructuredCourse> courses;

  /// 已放置的课程：courseIndex -> {dayOfWeek, startPeriod, endPeriod}
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
  static const double cellHeight = 50.0;
  static const double headerHeight = 36.0;
  static const double periodLabelWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 表头行：星期名称
        _buildHeaderRow(),
        // 时间表网格（使用 Stack 实现课程跨行显示）
        Expanded(
          child: _buildGrid(context),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // 左上角空白
          Container(
            width: periodLabelWidth,
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

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SizedBox(
            height: periods.length * cellHeight,
            width: constraints.maxWidth,
            child: Stack(
              children: [
                // 背景网格（纯色格子）
                _buildGridBackground(),
                // 放置的课程卡片（使用 Positioned 实现跨行显示）
                _buildPlacedCourses(),
                // DragTarget 层（接收拖拽）
                _buildDragTargets(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 背景网格（纯色格子，用于显示可放置区域）
  Widget _buildGridBackground() {
    return Column(
      children: periods.map((period) {
        return SizedBox(
          height: cellHeight,
          child: Row(
            children: [
              // 节次标签
              Container(
                width: periodLabelWidth,
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
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade200, width: 0.5),
                        bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 已放置的课程卡片（跨行显示）
  Widget _buildPlacedCourses() {
    // 按位置分组课程，用于处理同位置多课程（单周/双周）
    final coursesByPosition = <String, List<MapEntry<int, StructuredCourse>>>{};
    for (final entry in placedCourses.entries) {
      final courseIndex = entry.key;
      if (courseIndex >= courses.length) continue;
      final course = courses[courseIndex];
      final pos = entry.value;
      final key = '${pos['dayOfWeek']}_${pos['startPeriod']}';
      coursesByPosition.putIfAbsent(key, () => []).add(MapEntry(courseIndex, course));
    }

    return Stack(
      children: placedCourses.entries.map((entry) {
        final courseIndex = entry.key;
        if (courseIndex >= courses.length) return const SizedBox.shrink();
        final course = courses[courseIndex];
        final pos = entry.value;
        final dayOfWeek = pos['dayOfWeek']!;
        final startPeriod = pos['startPeriod']!;
        final endPeriod = pos['endPeriod']!;
        final duration = endPeriod - startPeriod + 1;

        // 计算位置和大小
        final left = periodLabelWidth + (dayOfWeek - 1) * _getDayColumnWidth();
        final top = (startPeriod - 1) * cellHeight;
        final width = _getDayColumnWidth() - 4;
        final height = duration * cellHeight - 4;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: _buildCourseCard(course, courseIndex, pos),
        );
      }).toList(),
    );
  }

  double _getDayColumnWidth() {
    // 动态计算每天列宽（基于可用宽度）
    // 这里使用固定值，实际会根据屏幕宽度调整
    return 70.0; // 后续会通过 LayoutBuilder 动态计算
  }

  /// 构建课程卡片
  Widget _buildCourseCard(StructuredCourse course, int courseIndex, Map<String, int> pos) {
    final isOddWeek = _isOddWeekCourse(course);
    final isEvenWeek = _isEvenWeekCourse(course);

    return GestureDetector(
      onLongPress: () {
        onCourseRemoved?.call(courseIndex);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _courseColor(course, isOddWeek, isEvenWeek),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            course.name,
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  bool _isOddWeekCourse(StructuredCourse course) {
    if (course.weeks == null || course.weeks!.isEmpty) return false;
    // 如果所有周次都是奇数
    return course.weeks!.every((w) => w % 2 == 1);
  }

  bool _isEvenWeekCourse(StructuredCourse course) {
    if (course.weeks == null || course.weeks!.isEmpty) return false;
    // 如果所有周次都是偶数
    return course.weeks!.every((w) => w % 2 == 0);
  }

  Color _courseColor(StructuredCourse course, bool isOddWeek, bool isEvenWeek) {
    if (course.colorHex != null) {
      try {
        final baseColor = Color(int.parse(course.colorHex!.replaceFirst('#', '0xFF')));
        if (isOddWeek && isEvenWeek) {
          // 两种周都有，不做特殊处理
          return baseColor;
        } else if (isEvenWeek) {
          // 只在双周，略微深一些
          return HSLColor.fromColor(baseColor).withLightness(
            (HSLColor.fromColor(baseColor).lightness - 0.1).clamp(0.0, 1.0)
          ).toColor();
        }
        return baseColor;
      } catch (_) {}
    }
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

  /// DragTarget 层
  Widget _buildDragTargets() {
    return Row(
      children: [
        // 节次标签列（不可放置）
        SizedBox(width: periodLabelWidth),
        // 7天的 DragTarget
        ...List.generate(7, (dayIndex) {
          final dayOfWeek = dayIndex + 1;
          return Expanded(
            child: SizedBox(
              height: periods.length * cellHeight,
              child: Stack(
                children: periods.map((period) {
                  return Positioned(
                    top: (period - 1) * cellHeight,
                    left: 0,
                    right: 0,
                    height: cellHeight,
                    child: _buildDragTarget(dayOfWeek, period),
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDragTarget(int dayOfWeek, int period) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final courseIndex = details.data;
        final course = courses[courseIndex];
        final duration = (course.endPeriod ?? course.startPeriod ?? 1) - (course.startPeriod ?? 1) + 1;

        // 检查时间冲突
        for (final entry in placedCourses.entries) {
          if (entry.key == courseIndex) continue;
          final pos = entry.value;
          if (pos['dayOfWeek'] == dayOfWeek) {
            final existingStart = pos['startPeriod']!;
            final existingEnd = pos['endPeriod']!;
            final newEnd = period + duration - 1;
            // 检查是否重叠
            if (period <= existingEnd && newEnd >= existingStart) {
              return false; // 时间冲突
            }
          }
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final courseIndex = details.data;
        final course = courses[courseIndex];
        final duration = (course.endPeriod ?? course.startPeriod ?? 1) - (course.startPeriod ?? 1) + 1;
        final endPeriod = period + duration - 1;
        onCourseDropped(courseIndex, dayOfWeek, period, endPeriod);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovering ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          ),
          child: isHovering
              ? Center(
                  child: Icon(Icons.add, color: Colors.blue.shade300, size: 20),
                )
              : null,
        );
      },
    );
  }
}
