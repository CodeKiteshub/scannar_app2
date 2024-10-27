import 'dart:core';

enum AIType {
  serialNumberAI('21'),
  lotNumberAI('10'),
  exprDateAI('17'),
  gtinAI('01'),
  qtyAI('30'),
  ssccAI('00'),
  glnAI('414');

  final String code;
  const AIType(this.code);
}

// List of possible group separators.
List<String> SEPARATORS = [
  String.fromCharCode(23),
  String.fromCharCode(29),
  String.fromCharCode(30),
  '\GS',
  '\RS',
  '\ETB',
  '{GS}',
  '<GS>',
  '↔',
  'FNC1',
  // '\F',
  // '/F'
];

// Structure for AI details
class AIDetails {
  final bool fixedLength;
  final int maxLength;

  AIDetails({required this.fixedLength, required this.maxLength});
}

// AI mapping similar to AI_LIST
Map<String, AIDetails> AI_LIST = {
  '21': AIDetails(fixedLength: false, maxLength: 20),
  '10': AIDetails(fixedLength: false, maxLength: 20),
  '30': AIDetails(fixedLength: false, maxLength: 8),
  '17': AIDetails(fixedLength: true, maxLength: 6),
  '01': AIDetails(fixedLength: true, maxLength: 14),
  '00': AIDetails(fixedLength: true, maxLength: 18),
  '414': AIDetails(fixedLength: true, maxLength: 11),
  // Add more as needed
};

class BarcodeDetails {
  String? serial;
  String? lot;
  Map<String, int> expiry = {'day': 0, 'month': 0, 'year': 0};
  String? gtin;
  String? qty;
  String? sscc;
  String? gln;

  @override
  String toString() {
    return 'BarcodeDetails(serial: $serial, lot: $lot, expiry: day: ${expiry['day']}, month: ${expiry['month']}, year: ${expiry['year']}, gtin: $gtin, qty: $qty, sscc: $sscc, gln: $gln)';
  }
}
