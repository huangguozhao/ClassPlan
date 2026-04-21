/// 原始课表数据
/// 来自不同导入源（PDF/图片/手动）的原始数据，统一封装成这个结构

class RawScheduleData {
  final String sourceType;      // 来源类型：'pdf', 'image', 'manual'
  final String sourceName;      // 文件名或来源描述
  final String rawText;         // 原始文本内容
  final Map<String, dynamic>? extra; // 额外数据（如图片路径等）

  RawScheduleData({
    required this.sourceType,
    required this.sourceName,
    required this.rawText,
    this.extra,
  });
}
