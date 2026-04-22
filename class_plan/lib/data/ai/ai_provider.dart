import 'dart:convert';

import '../../domain/model/raw_schedule_data.dart';
import '../../domain/model/structured_course.dart';
import '../../presentation/debug/debug_log_screen.dart';

/// AI Provider 接口
/// 所有 AI 提供者都实现此接口
abstract class AiProvider {
  /// 提供者唯一标识
  String get id;

  /// 显示名称
  String get name;

  /// 是否需要 API Key
  bool get requiresApiKey => true;

  /// 调用 AI 解析课表
  Future<List<StructuredCourse>> parse(RawScheduleData raw);

  /// 发送请求到 AI API（子类实现）
  Future<String> callApi(String text, String apiKey);

  /// 解析 JSON 响应为课程列表（通用）
  List<StructuredCourse> parseJsonResponse(String jsonStr) {
    // 清理 JSON 字符串（移除 markdown 代码块标记）
    var cleaned = jsonStr.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // 提取 JSON 数组部分
    int arrayStart = cleaned.indexOf('[');
    int arrayEnd = cleaned.lastIndexOf(']');
    if (arrayStart == -1 || arrayEnd == -1 || arrayEnd <= arrayStart) {
      return [];
    }
    String arrayStr = cleaned.substring(arrayStart, arrayEnd + 1);

    dynamic decoded;
    try {
      decoded = jsonDecode(arrayStr);
    } on FormatException {
      // JSON 格式有问题，尝试修复常见问题
      final fixed = _fixJsonString(arrayStr);
      try {
        decoded = jsonDecode(fixed);
      } catch (e) {
        // 修复也失败了，返回空列表
        DebugLogService().warning('JSON 解析失败，已修复仍失败: $e', tag: 'AI');
        return [];
      }
    } catch (e) {
      // 其他异常（如类型错误）也安全返回空列表
      return [];
    }
    if (decoded == null) return [];
    if (decoded is! List<dynamic>) return [];

    return (decoded).map((item) {
      if (item is! Map<String, dynamic>) return null;
      final map = Map<String, dynamic>.from(item);

      // 提取已知字段
      final name = map['name'] as String? ?? '未知课程';
      final teacher = _extractString(map, 'teacher');
      final location = _extractString(map, 'location');
      final dayOfWeek = _extractInt(map, 'dayOfWeek');
      final startPeriod = _extractInt(map, 'startPeriod');
      final endPeriod = _extractInt(map, 'endPeriod');
      final weekStart = _extractInt(map, 'weekStart');
      final weekEnd = _extractInt(map, 'weekEnd');
      final weeks = _extractIntList(map, 'weeks');

      // 移除已知字段，保留其余作为 extraData
      final knownKeys = [
        'name', 'teacher', 'location', 'dayOfWeek',
        'startPeriod', 'endPeriod', 'weekStart', 'weekEnd', 'weeks'
      ];
      final extraData = <String, dynamic>{};
      for (final entry in map.entries) {
        if (!knownKeys.contains(entry.key)) {
          extraData[entry.key] = entry.value;
        }
      }

      return StructuredCourse(
        name: name,
        teacher: teacher,
        location: location,
        dayOfWeek: dayOfWeek,
        startPeriod: startPeriod,
        endPeriod: endPeriod,
        weekStart: weekStart,
        weekEnd: weekEnd,
        weeks: weeks,
        extraData: extraData.isNotEmpty ? extraData : null,
      );
    }).whereType<StructuredCourse>().toList();
  }

  String? _extractString(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    return v.toString();
  }

  int? _extractInt(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  List<int>? _extractIntList(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is List) {
      return v.map((e) {
        if (e == null) return null;
        if (e is int) return e;
        if (e is double) return e.toInt();
        if (e is String) return int.tryParse(e);
        return null;
      }).whereType<int>().toList();
    }
    return null;
  }

  /// 修复常见的 JSON 格式问题
  String _fixJsonString(String input) {
    var result = input;

    // 1. 将单引号替换为双引号（但要避开已经存在的双引号内容）
    // 匹配 'key': 或 'value' 格式
    result = result.replaceAllMapped(
      RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'"),
      (m) {
        final inner = m.group(1)!;
        // 如果内容是数字、null、true、false，不加引号
        if (inner == 'null' || inner == 'true' || inner == 'false' ||
            RegExp(r'^-?\d+\.?\d*$').hasMatch(inner)) {
          return inner;
        }
        return '"$inner"';
      },
    );

    // 2. 修复 key 使用单引号的问题：将 'key' 转为 "key"
    result = result.replaceAllMapped(
      RegExp(r"'([^']+)':\s*"),
      (m) => '"${m.group(1)}": ',
    );

    // 3. 修复缺少逗号的问题：在 } 或 ] 前添加逗号（如果后面是 { 或 [ 或 "）
    result = result.replaceAllMapped(
      RegExp(r'}(?=\s*[{["\w])'),
      (m) => '},',
    );

    // 4. 修复尾部多余逗号
    result = result.replaceAll(RegExp(r',\s*\]'), ']');
    result = result.replaceAll(RegExp(r',\s*}'), '}');

    return result;
  }
}
