import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';

/// 课表导出服务
/// 生成课表图片供分享
class ScheduleExportService {
  /// 导出课表为图片
  Future<String?> exportToImage({
    required GlobalKey repaintKey,
    required String fileName,
  }) async {
    try {
      // 等待一帧确保渲染完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 获取 RenderRepaintBoundary
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // 转换为图片
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();

      // 保存到临时目录
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// 生成课表 Widget（用于导出）
  static Widget buildScheduleWidget({
    required Map<int, List<Course>> coursesByDay,
    required int totalWeeks,
    String? semesterName,
  }) {
    const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const periods = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          if (semesterName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                semesterName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          // 课表
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 节次列
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 30,
                    alignment: Alignment.center,
                    child: const Text('', style: TextStyle(fontSize: 10)),
                  ),
                  ...periods.map((p) => Container(
                    width: 40,
                    height: 60,
                    alignment: Alignment.center,
                    child: Text('$p', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  )),
                ],
              ),
              // 周一~周日
              for (int day = 1; day <= 7; day++) ...[
                const SizedBox(width: 4),
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 30,
                      alignment: Alignment.center,
                      child: Text(dayNames[day - 1], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    ...periods.map((period) {
                      final course = _findCourseAt(coursesByDay[day] ?? [], period);
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: course != null
                            ? Container(
                                margin: const EdgeInsets.all(2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _parseColor(course.colorHex),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      course.name,
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
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
                              )
                            : null,
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Course? _findCourseAt(List<Course> courses, int period) {
    for (final course in courses) {
      if (period >= course.startPeriod && period <= course.endPeriod) {
        return course;
      }
    }
    return null;
  }

  static Color _parseColor(String? colorHex) {
    if (colorHex == null) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}