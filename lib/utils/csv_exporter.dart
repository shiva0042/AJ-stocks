import 'csv_export_stub.dart'
    if (dart.library.html) 'csv_export_web.dart'
    if (dart.library.io) 'csv_export_mobile.dart';

class CsvExporter {
  static void export(String csvData, String fileName) {
    CsvExportHelper.downloadCsv(csvData, fileName);
  }
}
