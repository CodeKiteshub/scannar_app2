import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:scannar_app2/parser.dart' as aadi;
import 'dart:developer';

import 'barcode_details.dart';
import 'gs1_parser.dart';
import 'scan_result.dart';

class MatrixScanScreen extends StatefulWidget {
  @override
  _MatrixScanScreenState createState() => _MatrixScanScreenState();
}

class _MatrixScanScreenState extends State<MatrixScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  List<ScanResult> scanResults = [];
  Set<String> scannedCodes = {};
  AudioPlayer audioPlayer = AudioPlayer();
  late GS1DataParser parser;
  bool isBarcodeDetected = false;

  @override
  void initState() {
    super.initState();
    parser = GS1DataParser(); // Initialize GS1DataParser without format parameter
  }

  @override
  void dispose() {
    controller?.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playBeepSound() async {
    await audioPlayer.play(AssetSource('sounds/beep-01a.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              formatsAllowed: const [
                BarcodeFormat.qrcode,
                BarcodeFormat.dataMatrix,
                BarcodeFormat.code128,
                BarcodeFormat.code39,
                BarcodeFormat.ean13,
                BarcodeFormat.ean8,
                BarcodeFormat.upcA,
                BarcodeFormat.upcE,
              ],
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutWidth: 450,
                cutOutHeight: 700,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: MediaQuery.of(context).size.width / 3,
            height: 100,
            width: 150,
            child: Image.asset(
              'assets/images/sg_labs_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => _showScanResults(context),
              child: const Text('Show Scan Results'),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code == null || scanData.code!.isEmpty) return;
      String scannedCode = scanData.code!;

      // Check if already scanning or if code has already been processed
      if (isBarcodeDetected || scannedCodes.contains(scannedCode)) return;

      isBarcodeDetected = true;
      scannedCodes.add(scannedCode); // Add to set to prevent duplicates

  final aadi.GS1DataParser parser = aadi.GS1DataParser();

    aadi.ParsedData result = parser.parse(scannedCode);
    log('Parsed Data: ${result.toJson()}');
    //  BarcodeDetails parsedData = parser.parse(scannedCode);
      String symbology = scanData.format.formatName;
      // Prevent duplicate scans
      // if (scannedCodes.contains(scanData.code)) return;

      // // Parse the barcode data using GS1DataParser
      // BarcodeDetails parsedData = parser.parse(scanData.code!);
      // String symbology = scanData.format.formatName;

      // Add to scanned codes and play sound
      // scannedCodes.add(scanData.code!);
      await playBeepSound();

      // Add the parsed result to the list
      setState(() {
        scanResults.add(ScanResult(result, symbology));
      });

      log('Barcode Detected: $scannedCode');
     // log('Parsed Data: ${parsedData.toString()}');
      log('Symbology: $symbology');

      // Debounce to prevent immediate re-scanning
      await Future.delayed(const Duration(seconds: 1));
      isBarcodeDetected = false;
    });
  }

  void _showScanResults(BuildContext context) {
    Navigator.pushNamed(context, "/scanResults", arguments: scanResults);
  }
}

