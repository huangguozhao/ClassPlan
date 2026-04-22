import 'package:flutter/material.dart';

import '../../../domain/model/structured_course.dart';

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

  /// 点击已放置课程的回调（显示详情）
  final void Function(int courseIndex)? onCourseTapped;

  const TimetableGridEditor({
    super.key,
    required this.courses,
    required this.placedCourses,
    required this.onCourseDropped,
    this.onCourseRemoved,
    this.onCourseTapped,
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
        _buildHeaderRow(),
        Expanded(
          child: SingleChildScrollView(
            child: _buildGrid(context),
          ),
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
          Container(
            width: periodLabelWidth,
            alignment: Alignment.center,
            child: Text('节次', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Expanded(child: _buildDayHeaders()),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    return Row(
      children: List.generate(7, (index) {
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
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - periodLabelWidth;
        final dayColumnWidth = availableWidth / 7;
        final gridHeight = periods.length * cellHeight;

        return SizedBox(
          width: constraints.maxWidth,
          height: gridHeight,
          child: Stack(
            children: [
              // 背景网格（最底层）
              _buildGridBackground(dayColumnWidth),
              // DragTarget 层（中间，接收拖拽事件）
              _buildDragTargets(dayColumnWidth),
              // 放置的课程（最上层，显示在 DragTarget 之上）
              _buildPlacedCourses(dayColumnWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridBackground(double dayColumnWidth) {
    return Column(
      children: periods.map((period) {
        return SizedBox(
          height: cellHeight,
          child: Row(
            children: [
              Container(
                width: periodLabelWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(right: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Text('$period', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlacedCourses(double dayColumnWidth) {
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
        final left = periodLabelWidth + (dayOfWeek - 1) * dayColumnWidth + 1;
        final top = (startPeriod - 1) * cellHeight + 1;
        final width = dayColumnWidth - 2;
        final height = duration * cellHeight - 2;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: _buildCourseCard(course, courseIndex),
        );
      }).toList(),
    );
  }

  Widget _buildCourseCard(StructuredCourse course, int courseIndex) {
    final pos = placedCourses[courseIndex]!;
    final startPeriod = pos['startPeriod']!;
    final endPeriod = pos['endPeriod']!;
    final duration = endPeriod - startPeriod + 1;
    final isOddWeek = _isOddWeekCourse(course);
    final isEvenWeek = _isEvenWeekCourse(course);
    final color = _courseColor(course, isOddWeek, isEvenWeek);

    return GestureDetector(
      onTap: () => onCourseTapped?.call(courseIndex),
      onLongPress: () => onCourseRemoved?.call(courseIndex),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (duration >= 2 && course.location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    course.location!,
                    style: const TextStyle(fontSize: 8, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragTargets(double dayColumnWidth) {
    return Row(
      children: [
        SizedBox(width: periodLabelWidth),
        ...List.generate(7, (dayIndex) {
          final dayOfWeek = dayIndex + 1;
          return SizedBox(
            width: dayColumnWidth,
            child: Column(
              children: periods.map((period) {
                return SizedBox(
                  height: cellHeight,
                  child: _buildDragTarget(dayOfWeek, period),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDragTarget(int dayOfWeek, int period) {
    // 检查该格子是否被任何已放置的课程覆盖
    for (final entry in placedCourses.entries) {
      final pos = entry.value;
      if (pos['dayOfWeek'] == dayOfWeek) {
        final start = pos['startPeriod']!;
        final end = pos['endPeriod']!;
        if (period >= start && period <= end) {
          return const SizedBox(); // 被课程覆盖的格子不显示拖拽目标
        }
      }
    }

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
            if (period <= existingEnd && newEnd >= existingStart) {
              return false;
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

  bool _isOddWeekCourse(StructuredCourse course) {
    if (course.weeks == null || course.weeks!.isEmpty) return false;
    return course.weeks!.every((w) => w % 2 == 1);
  }

  bool _isEvenWeekCourse(StructuredCourse course) {
    if (course.weeks == null || course.weeks!.isEmpty) return false;
    return course.weeks!.every((w) => w % 2 == 0);
  }

  Color _courseColor(StructuredCourse course, bool isOddWeek, bool isEvenWeek) {
    if (course.colorHex != null) {
      try {
        final baseColor = Color(int.parse(course.colorHex!.replaceFirst('#', '0xFF')));
        if (isEvenWeek) {
          return HSLColor.fromColor(baseColor).withLightness(
            (HSLColor.fromColor(baseColor).lightness - 0.1).clamp(0.0, 1.0)
          ).toColor();
        }
        return baseColor;
      } catch (_) {}
    }
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.amber,
    ];
    return colors[course.name.hashCode % colors.length];
  }
}
