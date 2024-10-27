import 'dart:developer';

import 'barcode_details.dart';

class GS1DataParser {
  BarcodeDetails parse(String barcode) {
    BarcodeDetails details = BarcodeDetails();
    int cursor = 0;

    // Remove whitespace and check if separators are present
    barcode = barcode.trim();
    bool isGroupSeparatorAvailable =
        SEPARATORS.any((sep) => barcode.contains(sep));

    while (cursor < barcode.length - 2) {
      if (SEPARATORS.contains(barcode[cursor])) {
        cursor += 1;
      }

      if (cursor >= barcode.length - 2) break;
      // Ensure that cursor range is within bounds
      if (cursor + 2 > barcode.length) break;

      String ai = barcode.substring(cursor, cursor + 2);

      if (AI_LIST.containsKey(ai)) {
        cursor += 2;
        AIDetails aiDetails = AI_LIST[ai]!;

        String value = '';

        // Handle fixed-length AIs
        if (aiDetails.fixedLength) {
          if (cursor + aiDetails.maxLength <= barcode.length) {
            value = barcode.substring(cursor, cursor + aiDetails.maxLength);
            cursor += aiDetails.maxLength;
          } else {
            log("Warning: Fixed-length AI exceeds barcode length. AI: $ai, Cursor: $cursor");
            break;
          }
        } else {
          // Handle variable-length AIs (up to maxLength or separator)
          int maxLength = aiDetails.maxLength;
          int separatorPos =
              barcode.indexOf(RegExp(SEPARATORS.join('|')), cursor);
          int end = (separatorPos != -1 && separatorPos < cursor + maxLength)
              ? separatorPos
              : (cursor + maxLength).clamp(cursor, barcode.length);
          value = barcode.substring(cursor, end);
          cursor = end;
        }

        // Assign parsed value to respective fields
        switch (ai) {
          case '21':
            details.serial = value;
            log("Serial Detected: $value at cursor $cursor");
            break;
          case '10':
            details.lot = value;
            log("Lot Detected: $value at cursor $cursor");
            break;
          case '17':
            details.expiry = _parseExpiryDate(value);
            log("Expiry Detected: $value (parsed to ${details.expiry}) at cursor $cursor");
            break;
          case '01':
            details.gtin = value;
            log("GTIN Detected: $value at cursor $cursor");
            break;
          case '30':
            details.qty = value;
            log("Quantity Detected: $value at cursor $cursor");
            break;
          case '00':
            details.sscc = value;
            log("SSCC Detected: $value at cursor $cursor");
            break;
          case '414':
            details.gln = value;
            log("GLN Detected: $value at cursor $cursor");
            break;
        }
      } else {
        cursor = barcode.length;
      }
    }

    return details;
  }

  Map<String, int> _parseExpiryDate(String expiry) {
    if (expiry.length == 6) {
      try {
        int year = 2000 + int.parse(expiry.substring(0, 2));
        int month = int.parse(expiry.substring(2, 4));
        int day = int.parse(expiry.substring(4, 6));
        return {'day': day, 'month': month, 'year': year};
      } catch (e) {
        log("Error parsing expiry date: $e");
      }
    }
    return {'day': 0, 'month': 0, 'year': 0};
  }
}
