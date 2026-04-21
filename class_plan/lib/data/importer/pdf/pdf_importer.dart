import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../domain/model/raw_schedule_data.dart';
import '../course_importer.dart';

/// PDF 文件导入器
class PdfImporter implements CourseImporter {
  @override
  String get name => 'PDF 文件';

  @override
  Future<RawScheduleData> import(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('文件不存在：$sourcePath');
    }

    final bytes = await file.readAsBytes();
    final text = await _extractTextFromPdf(bytes);

    return RawScheduleData(
      sourceType: 'pdf',
      sourceName: sourcePath.split('/').last.split('\\').last,
      rawText: text,
      extra: {'filePath': sourcePath},
    );
  }

  Future<String> _extractTextFromPdf(List<int> bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('PDF 解析失败：$e');
    }
  }
}
