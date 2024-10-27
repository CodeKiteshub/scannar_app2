
// scan_result.dart
import 'package:scannar_app2/parser.dart';

import 'barcode_details.dart';

class ScanResult {
  final ParsedData data;
  final String symbology;

  ScanResult(this.data, this.symbology);

  @override
  String toString() {
    return 'ScanResult(data: ${data.toString()}, symbology: $symbology)';
  }
}