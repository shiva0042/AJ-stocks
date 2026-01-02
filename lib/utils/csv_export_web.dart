// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CsvExportHelper {
  static void downloadCsv(String csvData, String fileName) {
    // Add BOM for Excel compatibility (supports UTF-8 characters)
    final blob = html.Blob(["\uFEFF", csvData], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
