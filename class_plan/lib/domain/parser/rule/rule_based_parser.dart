import '../../../domain/model/raw_schedule_data.dart';
import '../../../domain/model/structured_course.dart';
import '../schedule_parser.dart';

/// 基于规则的课表解析器 v2
/// 针对格式混乱的 PDF课表优化：支持按行块顺序关联课程名和详细信息
class RuleBasedParser implements ScheduleParser {
  @override
  String get name => '规则解析';

  @override
  int get priority => 1;

  // 节次匹配：(1-4节)、1-4节、1、2等
  static final _periodPattern = RegExp(
    r'^\s*\(?(\d+)\s*[-–~]\s*(\d+)\s*节?\)?|^\s*\(?(\d+)\s*节\)?',
  );

  // 周次匹配：1-15周、1-16周、单周、双周
  static final _weekPattern = RegExp(
    r'\d+\s*[-–~]\s*\d+\s*周|单周|双周|奇数周|偶数周',
  );

  // 地点匹配：教学楼XXX、主楼XXX、教室XXX
  static final _locationPattern = RegExp(
    r'(?:教学楼|主楼|学活|教室|实验室|体育馆|场馆)([^\s/]+)|'
    r'([A-Za-z0-9]+(?:楼|室|馆|厅|舍|堂|场))',
  );

  // 教师匹配：教师:XXX、
  static final _teacherPattern = RegExp(
    r'教师:\s*([^\s/]+)',
  );

  // 课程名行检测：包含中文且在课程详情行之前
  static final _courseNameCandidatePattern = RegExp(
    r'[\u4e00-\u9fa5]',
  );

  // 星期行检测：一行全是星期名称
  static final _weekdayRowPattern = RegExp(
    r'^[\s\u4e00-\u9fa5]*$',
  );

  static final _weekdayMap = {
    '周一': 1, '周二': 2, '周三': 3, '周四': 4,
    '周五': 5, '周六': 6, '周日': 7, '周天': 7,
  };

  // 星期行检测：只包含星期标记
  static final _singleWeekdayPattern = RegExp(
    r'^[\s]*('
    r'周一|周二|周三|周四|周五|周六|周日|星期[一二三四五六日天]'
    r')[\s]*$',
  );

  @override
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    final lines = raw.rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final courses = <StructuredCourse>[];
    String? pendingCourseName;
    int? currentDayOfWeek; // 当前解析上下文的星期

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 检测独立的星期标题行（如 "周一" 单独一行）
      final weekdayMatch = _singleWeekdayPattern.firstMatch(line);
      if (weekdayMatch != null) {
        final dayText = weekdayMatch.group(1)!;
        currentDayOfWeek = _weekdayMap[dayText];
        continue;
      }

      // 尝试从行内识别星期标记（如 "周一 1-2节 3-4节" 混在一起的情况）
      if (currentDayOfWeek == null) {
        for (final entry in _weekdayMap.entries) {
          if (line.contains(entry.key)) {
            currentDayOfWeek = entry.value;
            break;
          }
        }
      }

      // 策略1: 检测课程详情行（有节次+周次格式）
      if (_isCourseDetailLine(line)) {
        final parsed = _parseCourseDetailLine(line);

        if (parsed != null) {
          // 尝试关联前面几行中找到的课程名
          final courseName = _extractCourseNameFromContext(lines, i, pendingCourseName);
          courses.add(parsed.copyWith(
            name: courseName ?? pendingCourseName ?? '未知课程',
            dayOfWeek: currentDayOfWeek,
          ));
          pendingCourseName = null;
        }
        continue;
      }

      // 策略2: 检测可能是课程名的行（在课程详情行之前，且包含中文）
      if (_courseNameCandidatePattern.hasMatch(line) &&
          !_weekdayRowPattern.hasMatch(line)) {
        if (!_isHeaderLine(line) && !_isLikelyMetadata(line)) {
          final candidate = _cleanCourseName(line);
          if (candidate != null && candidate.isNotEmpty) {
            pendingCourseName = candidate;
          }
        }
      }
    }

    return _deduplicateAndMerge(courses);
  }

  bool _isCourseDetailLine(String line) {
    // 课程详情行特征：包含节次信息（数字+节）或周次信息（数字+周）
    // 且格式类似 (1-4节)1-15周 或 1-4节 1-15周
    final hasPeriod = RegExp(r'\d+\s*[-–~]\s*\d+\s*节').hasMatch(line);
    final hasWeek = RegExp(r'\d+\s*[-–~]\s*\d+\s*周').hasMatch(line);
    return hasPeriod || hasWeek;
  }

  bool _isHeaderLine(String line) {
    // 标题行特征：很短、没有分隔符、包含常见标题词
    final headerKeywords = ['学期', '学年', '学号', '姓名', '时间表', '课程表', '周', '节次'];
    if (line.length < 10) {
      for (final kw in headerKeywords) {
        if (line.contains(kw)) return true;
      }
    }
    return false;
  }

  bool _isLikelyMetadata(String line) {
    // 元数据行特征：包含大量冒号分隔的键值对
    final colonCount = ':'.allMatches(line).length;
    return colonCount >= 3;
  }

  String? _cleanCourseName(String line) {
    // 清理课程名：移除尾部的冒号分隔内容
    var cleaned = line;

    // 移除尾部冒号后的元数据
    final lastColon = cleaned.lastIndexOf(':');
    if (lastColon > cleaned.length ~/ 2) {
      cleaned = cleaned.substring(0, lastColon);
    }

    // 移除括号内容（通常是课程号之类的）
    cleaned = cleaned.replaceAll(RegExp(r'\([^\)]*\)'), '');

    // 清理多余空白
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) return null;

    // 限制长度
    if (cleaned.length > 30) {
      cleaned = cleaned.substring(0, 30);
    }

    return cleaned;
  }

  String? _extractCourseNameFromContext(List<String> lines, int currentIndex, String? pendingName) {
    // 从当前行往前找最多3行，找到最近的疑似课程名
    for (int offset = 1; offset <= 3 && currentIndex - offset >= 0; offset++) {
      final prevLine = lines[currentIndex - offset];

      // 跳过空白行、标题行、课程详情行
      if (prevLine.isEmpty) continue;
      if (_isHeaderLine(prevLine)) continue;
      if (_isCourseDetailLine(prevLine)) break;
      if (_isLikelyMetadata(prevLine)) continue;

      // 如果之前有 pendingName 且当前行很短，可能是课程名
      if (pendingName != null && prevLine.length <= 20 && _courseNameCandidatePattern.hasMatch(prevLine)) {
        return _cleanCourseName(prevLine);
      }
    }

    // 向前看：找第一行包含中文且长度适中的行
    for (int offset = 1; offset <= 3 && currentIndex - offset >= 0; offset++) {
      final prevLine = lines[currentIndex - offset];
      if (prevLine.length >= 4 && prevLine.length <= 25 && _courseNameCandidatePattern.hasMatch(prevLine)) {
        if (!_isHeaderLine(prevLine) && !_isLikelyMetadata(prevLine)) {
          return _cleanCourseName(prevLine);
        }
      }
    }

    return pendingName;
  }

  StructuredCourse? _parseCourseDetailLine(String line) {
    // 提取节次
    int? startPeriod;
    int? endPeriod;
    final periodMatch = RegExp(r'(\d+)\s*[-–~]\s*(\d+)\s*节').firstMatch(line);
    if (periodMatch != null) {
      startPeriod = int.tryParse(periodMatch.group(1)!);
      endPeriod = int.tryParse(periodMatch.group(2)!);
    } else {
      final singleMatch = RegExp(r'(\d+)\s*节').firstMatch(line);
      if (singleMatch != null) {
        startPeriod = endPeriod = int.tryParse(singleMatch.group(1)!);
      }
    }

    // 提取周次
    int? weekStart;
    int? weekEnd;
    List<int>? weeks;

    final weekMatch = RegExp(r'(\d+)\s*[-–~]\s*(\d+)\s*周').firstMatch(line);
    if (weekMatch != null) {
      weekStart = int.tryParse(weekMatch.group(1)!);
      weekEnd = int.tryParse(weekMatch.group(2)!);
    }

    // 提取单双周
    if (line.contains('单周') || line.contains('奇数周')) {
      final start = weekStart ?? 1;
      final end = weekEnd ?? 20;
      weeks = List.generate(
        ((end - start) ~/ 2) + 1,
        (i) => start + i * 2,
      );
    } else if (line.contains('双周') || line.contains('偶数周')) {
      final start = weekStart ?? 2;
      final end = weekEnd ?? 20;
      weeks = List.generate(
        ((end - start) ~/ 2) + 1,
        (i) => start + i * 2,
      );
    }

    // 提取地点
    String? location;
    final locationMatch = _locationPattern.firstMatch(line);
    if (locationMatch != null) {
      location = locationMatch.group(1) ?? locationMatch.group(2);
    }

    // 提取教师
    String? teacher;
    final teacherMatch = _teacherPattern.firstMatch(line);
    if (teacherMatch != null) {
      teacher = teacherMatch.group(1);
    }

    // 推断星期：从行号/位置推断（这个 PDF 里行号=星期几）
    // 需要结合上下文来判断

    if (startPeriod == null && weekStart == null) {
      return null; // 不是有效的课程详情行
    }

    return StructuredCourse(
      name: '', // 由调用方填充
      teacher: teacher,
      location: location,
      dayOfWeek: null, // 需要额外推断
      startPeriod: startPeriod,
      endPeriod: endPeriod,
      weekStart: weekStart,
      weekEnd: weekEnd,
      weeks: weeks,
    );
  }

  List<StructuredCourse> _deduplicateAndMerge(List<StructuredCourse> courses) {
    final Map<String, StructuredCourse> merged = {};

    for (final course in courses) {
      if (course.startPeriod == null && course.weekStart == null) continue;

      final key = '${course.name}_${course.startPeriod}_${course.weekStart}_${course.location}';
      if (merged.containsKey(key)) {
        final existing = merged[key]!;
        merged[key] = StructuredCourse(
          name: course.name.isNotEmpty && course.name != '未知课程' ? course.name : existing.name,
          teacher: course.teacher ?? existing.teacher,
          location: course.location ?? existing.location,
          dayOfWeek: course.dayOfWeek ?? existing.dayOfWeek,
          startPeriod: course.startPeriod ?? existing.startPeriod,
          endPeriod: course.endPeriod ?? existing.endPeriod,
          weekStart: course.weekStart ?? existing.weekStart,
          weekEnd: course.weekEnd ?? existing.weekEnd,
          weeks: course.weeks ?? existing.weeks,
          colorHex: course.colorHex ?? existing.colorHex,
        );
      } else {
        merged[key] = course;
      }
    }

    return merged.values.where((c) => c.name.isNotEmpty && c.name != '未知课程').toList();
  }
}

/// Extension to add copyWith to StructuredCourse for this parser
extension StructuredCourseCopyWith on StructuredCourse {
  StructuredCourse copyWith({
    String? name,
    String? teacher,
    String? location,
    int? dayOfWeek,
    int? startPeriod,
    int? endPeriod,
    int? weekStart,
    int? weekEnd,
    List<int>? weeks,
    String? colorHex,
  }) {
    return StructuredCourse(
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startPeriod: startPeriod ?? this.startPeriod,
      endPeriod: endPeriod ?? this.endPeriod,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      weeks: weeks ?? this.weeks,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
