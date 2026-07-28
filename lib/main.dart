import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReportesRD',
      theme: AppTheme.temaClaro,
      debugShowCheckedModeBanner: false,
      home: const Placeholder(), // esto lo cambiamos por HomeScreen() más adelante
    );
  }
}