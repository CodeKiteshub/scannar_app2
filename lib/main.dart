import 'package:flutter/material.dart';

import 'scan_screen.dart';
import 'scan_screen_results.dart';


void main() {
  runApp(const MyApp());
}

const int scanditBlue = 0xFF58B5C2;
const Map<int, Color> scanditBlueShades = {
  50: Color.fromRGBO(88, 181, 194, .1),
  100: Color.fromRGBO(88, 181, 194, .2),
  200: Color.fromRGBO(88, 181, 194, .3),
  300: Color.fromRGBO(88, 181, 194, .4),
  400: Color.fromRGBO(88, 181, 194, .5),
  500: Color.fromRGBO(88, 181, 194, .6),
  600: Color.fromRGBO(88, 181, 194, .7),
  700: Color.fromRGBO(88, 181, 194, .8),
  800: Color.fromRGBO(88, 181, 194, .9),
  900: Color.fromRGBO(88, 181, 194, 1),
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        buttonTheme: const ButtonThemeData(buttonColor: Color(scanditBlue), textTheme: ButtonTextTheme.primary),
        primarySwatch: const MaterialColor(scanditBlue, scanditBlueShades),
        primaryIconTheme: Theme.of(context).primaryIconTheme.copyWith(color: Colors.white),
        primaryTextTheme: const TextTheme(headlineMedium: TextStyle(color: Colors.white)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(color: Colors.white),
            color: Color(scanditBlue),
            titleTextStyle: TextStyle(color: Colors.white)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MatrixScanScreen(),
        '/scanResults': (context) => const ScanResultsScreen("Scan Results")
      },
    );
  }
}
