import 'package:flutter/material.dart';

import '../../../domain/model/structured_course.dart';

/// 可拖拽的课程卡片
/// 用于在导入确认页面拖拽课程到时间表网格中
class DraggableCourseCard extends StatelessWidget {
  final StructuredCourse course;
  final int courseIndex;
  final bool isPlaced;
  final VoidCallback? onTap;

  const DraggableCourseCard({
    super.key,
    required this.course,
    required this.courseIndex,
    this.isPlaced = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    if (isPlaced) {
      // 已放置的课程不可再拖拽，显示为普通卡片
      return card;
    }

    // 未放置的课程可以拖拽
    return LongPressDraggable<int>(
      data: courseIndex,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 120,
          child: _buildCardContent(context, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: card,
      ),
      child: card,
    );
  }

  Widget _buildCard(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPlaced ? Colors.grey.shade200 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPlaced ? Colors.grey.shade400 : Colors.blue.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPlaced ? Colors.grey.shade600 : Colors.blue.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPlaced)
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (course.teacher != null)
                  Expanded(
                    child: Text(
                      course.teacher!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (course.location != null)
                  Text(
                    course.location!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade400, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (course.location != null)
            Text(
              course.location!,
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
              maxLines: 1,
            ),
        ],
      ),
    );
  }
}

/// 拖拽课程数据
class DragCourseData {
  final int courseIndex;
  final StructuredCourse course;

  DragCourseData({required this.courseIndex, required this.course});
}