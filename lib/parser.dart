// Enum for AI Types
import 'dart:math';

enum AIType {
  SERIAL_NUMBER_AI('21'),
  LOT_NUMBER_AI('10'),
  EXPR_DATE_AI('17'),
  GTIN_AI('01'),
  QTY_AI('30'),
  SSCC_AI('00'),
  GLN_AI('414');

  final String value;
  const AIType(this.value);
}

// Constants
class Constants {
  static const List<String> SEPARATORS = [
    '\u0017', // ETB
    '\u001D', // GS
    '\u001E', // RS
    'GS',
    'RS',
    'ETB',
    '{GS}',
    '<GS>',
    '↔',
    'FNC1',
    'F',
    '/F'
  ];

  static const List<String> SINGLE_CODES = ['EAN', 'UPCA'];

  static const Map<String, Map<String, dynamic>> AI_LIST = {
    '21': {'fixedLength': false, 'maxLength': 20},
    '10': {'fixedLength': false, 'maxLength': 20},
    '30': {'fixedLength': false, 'maxLength': 8},
    '17': {'fixedLength': true, 'maxLength': 6},
    '01': {'fixedLength': true, 'maxLength': 14},
    '00': {'fixedLength': true, 'maxLength': 18},
    // Add other AIs as needed
  };

  static const List<String> ILPN_PATTERN_LIST = [
    '0190',
    '0191',
    '0192',
    '0193',
    '0194',
    '0195',
    '0196',
    '0197',
    '0198',
    '0199',
  ];

  static const List<String> GLN_PATTERN_LIST = ['414'];
}

// BarcodeDetails class
class BarcodeDetails {
  String? tempSerial;
  String? tempLot;
  Map<String, int> tempExp = {'day': 0, 'month': 0, 'year': 0};
  String? tempNDC;
  String? tempGTIN;
  String? tempQTY;
  String? tempSSCC;
  String? tempGLN;
  bool? expDateCheck;
  bool? isExpValid;

  BarcodeDetails();
}

// ParsedData class
class ParsedData {
  String? gtin;
  String? lot;
  String? serial;
  Map<String, int>? expiry = {'day': 0, 'month': 0, 'year': 0};
  String? qty;
  String? lpnNumber;
  String? gln;

  ParsedData({
    this.gtin,
    this.lot,
    this.serial,
    this.expiry,
    this.qty,
    this.lpnNumber,
    this.gln,
  });

  Map<String, dynamic> toJson() {
    return {
      'gtin': gtin,
      'lot': lot,
      'serial': serial,
      'expiry': expiry,
      'qty': qty,
      'lpnNumber': lpnNumber,
      'gln': gln,
    };
  }
}

// GS1DataParser class
class GS1DataParser {
  ParsedData parse(String barcode, [String barcodeFormat = '']) {
    barcode = barcode.trim();
    bool isGroupSeparatorAvailable = false;
    bool isBuggyCodeWithoutGs = false;
    barcode = _convertBarcodeEscapeSequences(barcode);

    // Check if barcode is in HRI format
    if (barcode.contains('(') && barcode.contains(')')) {
      return _parseHRI(barcode);
    }

    ParsedData parsedData = ParsedData();

    // Handle single codes
    if (barcodeFormat.isNotEmpty) {
      bool foundSingleCode = false;
      for (String format in Constants.SINGLE_CODES) {
        if (barcodeFormat.contains(format)) {
          parsedData.gtin = barcode;
          foundSingleCode = true;
          break;
        }
      }
      if (foundSingleCode) {
        return parsedData;
      }
    }

    // Check for ILPN number
    if (Constants.ILPN_PATTERN_LIST.contains(barcode.substring(0, 4))) {
      parsedData.lpnNumber = barcode;
      return parsedData;
    }

    // Check for GLN number
    if (Constants.GLN_PATTERN_LIST.contains(barcode.substring(0, 3))) {
      parsedData.gln = barcode;
      return parsedData;
    }

    BarcodeDetails barcodeDetails = BarcodeDetails();
    int parseCursor = 0;

    try {
      while (parseCursor < barcode.length - 2) {
        if (Constants.SEPARATORS.contains(barcode[parseCursor])) {
          parseCursor++;
        }

        if (parseCursor > barcode.length - 2) break;

        String ai = barcode.substring(parseCursor, parseCursor + 2);

        if (Constants.AI_LIST.containsKey(ai)) {
          parseCursor += 2;
          Map<String, dynamic> bt = Constants.AI_LIST[ai]!;

          String value;
          if (bt['fixedLength']) {
            if (barcode.length >= (parseCursor + bt['maxLength'])) {
              value = barcode.substring(
                  parseCursor, parseCursor + (bt['maxLength'] as int));
              parseCursor += bt['maxLength'] as int;

              // Handle separators
              String nextChars = barcode.substring(
                  parseCursor,
                  parseCursor +
                      Constants.SEPARATORS
                          .map((e) => e.length)
                          .reduce((a, b) => a > b ? a : b));

              for (String sep in Constants.SEPARATORS) {
                if (nextChars.startsWith(sep)) {
                  parseCursor += sep.length;
                  isGroupSeparatorAvailable = true;
                  break;
                }
              }
            } else {
              break;
            }
          } else {
            // Handle variable length AIs
            value = barcode.substring(parseCursor);
            int? sepIndex;

            for (String sep in Constants.SEPARATORS) {
              if (value.contains(sep)) {
                int idx = value.indexOf(sep);
                sepIndex = sepIndex == null ? idx : min(sepIndex, idx);
              }
            }

            if (sepIndex != null) {
              value = value.substring(0, sepIndex);
              parseCursor += value.length + 1;
              isGroupSeparatorAvailable = true;
            } else {
              parseCursor += value.length;
            }
          }

          // Assign values based on AI type
          _assignValue(ai, value, barcodeDetails);
        }
      }

      // Populate parsed data
      if (!isBuggyCodeWithoutGs) {
        _populateParsedData(parsedData, barcodeDetails);
      } else {
        parsedData = _getParsedDataFromCodeWithoutGS(barcode);
      }

      if (parsedData.lpnNumber != null) {
        parsedData.lpnNumber = '00${parsedData.lpnNumber}';
      }
    } catch (e) {
      print('Exception in parsing: $e');
    }

    return parsedData;
  }

  void _assignValue(String ai, String value, BarcodeDetails details) {
    switch (ai) {
      case '21':
        details.tempSerial = value;
        break;
      case '10':
        details.tempLot = value;
        break;
      case '17':
        details.tempExp = _parseExpiryDate(value);
        break;
      case '01':
        details.tempNDC = value.substring(3, 13);
        details.tempGTIN = value;
        break;
      case '30':
        details.tempQTY = value;
        break;
      case '00':
        details.tempSSCC = value;
        break;
    }
  }

  Map<String, int> _parseExpiryDate(String expiry) {
    if (expiry.length == 6) {
      try {
        int year = 2000 + int.parse(expiry.substring(0, 2));
        int month = int.parse(expiry.substring(2, 4));
        int day = int.parse(expiry.substring(4, 6));
        return {'day': day, 'month': month, 'year': year};
      } catch (e) {
        print("Error parsing expiry date: $e");
      }
    }
    return {'day': 0, 'month': 0, 'year': 0};
  }

  void _populateParsedData(ParsedData parsedData, BarcodeDetails details) {
    parsedData.gtin = details.tempGTIN;
    parsedData.lot = details.tempLot;
    parsedData.serial = details.tempSerial;
    parsedData.expiry = details.tempExp;
    parsedData.lpnNumber = details.tempSSCC;
    parsedData.qty = details.tempQTY;
  }

  ParsedData _parseHRI(String barcode) {
    ParsedData parsedData = ParsedData();
    List<String> barcodeElements = barcode.split('(');

    for (String element in barcodeElements.skip(1)) {
      if (element.split(')').length == 2) {
        List<String> parts = element.split(')');
        String ai = parts[0];
        String value = parts[1];

        switch (ai) {
          case '01':
            parsedData.gtin = value;
            break;
          case '21':
            parsedData.serial = value;
            break;
          case '17':
            parsedData.expiry = _parseExpiryDate(value);
            break;
          case '10':
            parsedData.lot = value;
            break;
          case '30':
            parsedData.qty = value;
            break;
          case '00':
            parsedData.lpnNumber = value;
            break;
        }
      }
    }
    return parsedData;
  }

  String _convertBarcodeEscapeSequences(String barcode) {
    RegExp escapeSequences = RegExp(r'\\x..');
    return barcode.replaceAllMapped(escapeSequences, (match) {
      String hex = match.group(0)!.substring(2);
      int charCode = int.parse(hex, radix: 16);
      return String.fromCharCode(charCode);
    });
  }

  ParsedData _getParsedDataFromCodeWithoutGS(String barcode) {
    // Implement the logic for parsing barcodes without group separators
    // This would be similar to the Python implementation but adapted for Dart
    return ParsedData();
  }
}
