import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvExportHelper {
  static Future<String?> downloadCsv(String csvData, String fileName) async {
    try {
      // Save to temporary directory first
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);
      
      print("CSV created at: ${file.path}");
      
      // Share the file using Share dialog
      // User can choose: Save to Files, Drive, WhatsApp, etc.
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AJ Stocks Report - $fileName',
        subject: 'Export CSV',
      );
      
      if (result.status == ShareResultStatus.success) {
        return file.path;
      } else {
        return null;
      }
    } catch (e) {
      print("Error sharing CSV: $e");
      return null;
    }
  }
}
