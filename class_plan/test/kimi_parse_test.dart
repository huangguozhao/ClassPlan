import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Test KIMI API with course table prompt', () async {
    // 1. 读取 PDF
    final pdfPath = 'D:/Project/ClassPlan/doc/郑金凤(2025-2026-2)课表.pdf';
    final file = File(pdfPath);
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final rawText = extractor.extractText();
    document.dispose();

    print('PDF 提取文本长度: ${rawText.length}');

    // 2. 调用 KIMI API
    const apiKey = 'sk-NkApZ7gg2gAY9vjM3qWznon5TtIukGNVOuTcq9LLr0srIh7d';

    // 使用优化后的课程表 prompt
    const systemPrompt = '''你是一个专业的课表解析助手，擅长从PDF表格提取的文本中解析课程信息。

## 输入格式
课表文本来自PDF表格提取，格式如下（示例）：
```
2025-2026学年第2学期
郑金凤课表
学号：231060117
时间段
节次
星期一  星期二  星期三  星期四  星期五  星期六  星期日
上午
1
人体及动物生理学实验★
(1-4节)1-15周/校区:江北校区/场地:田科403/教师:刘雄军,...
...
```

## 解析规则
1. **时间段识别**：表格中的"上午"对应早上课程，"下午"对应下午课程，"晚上"对应晚上课程
2. **课程块识别**：每门课由课程名开始，后面跟着详细信息
3. **字段映射**：dayOfWeek: 1=周一, 2=周二, ..., 7=周日

## 重要提醒
1. **不要合并重复课程**：如果 PDF 中同一课程名出现多次（如在不同行），每行都解析为独立的课程条目。
2. **dayOfWeek 不要猜测**：如果文本中无法确定星期几，dayOfWeek 设为 null。

## 输出要求
只返回JSON数组，每项包含：
- name: 课程名（必填）
- teacher: 教师名（从"教师:"后提取）
- location: 上课地点（从"场地:"后提取）
- dayOfWeek: 1-7（如果无法确定则设为 null）
- startPeriod: 1-12
- endPeriod: 1-12
- weekStart: 数字
- weekEnd: 数字
- weeks: 可选
''';

    final body = {
      'model': 'moonshot-v1-8k',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': '请解析以下课表文本：\n\n$rawText'},
      ],
      'max_tokens': 4096,
    };

    print('\n调用 KIMI API...');

    final response = await http.post(
      Uri.parse('https://api.moonshot.cn/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    ).timeout(Duration(seconds: 120));

    print('状态码: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('API 错误: ${response.body}');
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      print('无解析结果');
      return;
    }

    final firstChoice = choices.first as Map<String, dynamic>;
    final message = firstChoice['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String? ?? '';

    print('\nKIMI 返回内容:');
    print(content.substring(0, 200));

    // 解析 JSON - KIMI 可能返回 ```json 包裹的内容
    var cleaned = content.trim();
    // 去掉开头的说明文字
    final jsonStart = cleaned.indexOf('[');
    if (jsonStart > 0) {
      cleaned = cleaned.substring(jsonStart);
    }
    if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
    if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();

    if (cleaned.isEmpty) {
      print('JSON 内容为空');
      return;
    }

    final List<dynamic> jsonList = jsonDecode(cleaned);

    print('\n=== 解析结果: ${jsonList.length} 门课程 ===');

    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    for (int i = 0; i < jsonList.length; i++) {
      final course = jsonList[i] as Map<String, dynamic>;
      final dayOfWeek = course['dayOfWeek'] as int?;
      final startPeriod = course['startPeriod'] as int?;
      final endPeriod = course['endPeriod'] as int?;

      print('${i + 1}. ${course['name']}');
      if (dayOfWeek != null) {
        print('   星期: ${dayNames[dayOfWeek - 1]}');
      } else {
        print('   星期: null (待拖拽)');
      }
      if (startPeriod != null) {
        print('   节次: ${startPeriod}${endPeriod != null ? '-$endPeriod' : ''}节');
      }
    }

    print('\n=== 测试完成 ===');
  }, timeout: Timeout(Duration(seconds: 150)));
}