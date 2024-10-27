import 'package:flutter/material.dart';
import 'package:scannar_app2/parser.dart';
import 'barcode_details.dart';
import 'scan_result.dart';

class ScanResultsScreen extends StatelessWidget {
  final String title;

  const ScanResultsScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve ScanResult objects directly from arguments
    final List<ScanResult> results =
        ModalRoute.of(context)?.settings.arguments as List<ScanResult>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 20),
            height: 100,
            width: 150,
            child: Image.asset(
              'assets/images/sg_labs_logo.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: results.length,
              itemBuilder: (BuildContext context, int index) {
                var result = results[index];
                ParsedData parsedData =
                    result.data; // Access BarcodeDetails directly

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.teal, width: 1),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Symbology: ${result.symbology}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildParsedFields(parsedData), // Display parsed fields
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _scanAgain(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                child: const Text(
                  'Scan Again',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedFields(ParsedData details) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (details.gtin != null && details.gtin!.isNotEmpty)
        Text("GTIN: ${details.gtin}", style: _fieldTextStyle()),
      if (details.lot != null && details.lot!.isNotEmpty)
        Text("Lot: ${details.lot}", style: _fieldTextStyle()),
      if (details.serial != null && details.serial!.isNotEmpty)
        Text("Serial: ${details.serial}", style: _fieldTextStyle()),
      if ((details.expiry?['day'] ?? 0) != 0 &&
          (details.expiry?['month'] ?? 0) != 0 &&
          (details.expiry?['year'] ?? 0) != 0)
        Text(
          "Expiry Date: ${details.expiry?['day']?.toString().padLeft(2, '0')}-${details.expiry?['month']?.toString().padLeft(2, '0')}-${details.expiry?['year']}",
          style: _fieldTextStyle(),
        ),
      if (details.qty != null && details.qty!.isNotEmpty)
        Text("Quantity: ${details.qty}", style: _fieldTextStyle()),
    //  if (details.sscc != null && details.sscc!.isNotEmpty)
     //   Text("SSCC: ${details.sscc}", style: _fieldTextStyle()),
      if (details.gln != null && details.gln!.isNotEmpty)
        Text("GLN: ${details.gln}", style: _fieldTextStyle()),
    ],
  );
}


  TextStyle _fieldTextStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
  }

  // Action to scan again (pop the current page)
  void _scanAgain(BuildContext context) {
    Navigator.pop(context);
  }
}
