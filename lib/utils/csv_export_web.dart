// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CsvExportHelper {
  static Future<String?> downloadCsv(String csvData, String fileName) async {
    try {
      // Add BOM for Excel compatibility (supports UTF-8 characters)
      final blob = html.Blob(["\uFEFF", csvData], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return "Browser Downloads folder"; // Return a dummy success message for web
    } catch (e) {
      print("Web CSV export error: $e");
      return null;
    }
  }
}
