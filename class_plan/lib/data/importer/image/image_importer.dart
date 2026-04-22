import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as path;

import '../../../domain/model/raw_schedule_data.dart';
import '../course_importer.dart';

/// 图片 OCR 导入器
class ImageImporter implements CourseImporter {
  @override
  String get name => '图片 OCR';

  @override
  Future<RawScheduleData> import(String sourcePath) async {
    if (sourcePath.isEmpty) {
      throw Exception('未选择图片文件');
    }

    // 验证文件是否存在
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('文件不存在：$sourcePath');
    }

    // 验证文件扩展名
    final ext = path.extension(sourcePath).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      throw Exception('不支持的图片格式：$ext，请选择 JPG、PNG 等格式');
    }

    final text = await _recognizeText(sourcePath);

    return RawScheduleData(
      sourceType: 'image',
      sourceName: path.basename(sourcePath),
      rawText: text,
      extra: {'filePath': sourcePath},
    );
  }

  Future<String> _recognizeText(String sourcePath) async {
    final inputImage = InputImage.fromFilePath(sourcePath);
    // 中文课表必须用 chinese 脚本，latin 无法识别中文
    final recognizer = TextRecognizer(script: TextRecognitionScript.chinese);

    try {
      final recognized = await recognizer.processImage(inputImage);
      recognizer.close();
      if (recognized.text.isEmpty) {
        throw Exception('未识别到文字，请确保图片清晰且包含文字');
      }
      return recognized.text;
    } catch (e) {
      recognizer.close();
      throw Exception('OCR 识别失败：$e');
    }
  }
}
