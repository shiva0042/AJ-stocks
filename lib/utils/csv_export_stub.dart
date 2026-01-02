import 'package:flutter/foundation.dart';

/// Abstract class for CSV Exporting
abstract class CsvExportHelper {
  static void downloadCsv(String csvData, String fileName) {
     // This will be overridden by conditional imports
  }
}
