import 'csv_export_stub.dart'
    if (dart.library.html) 'csv_export_web.dart'
    if (dart.library.io) 'csv_export_mobile.dart';

class CsvExporter {
  static Future<String?> export(String csvData, String fileName) async {
    return await CsvExportHelper.downloadCsv(csvData, fileName);
  }
}
