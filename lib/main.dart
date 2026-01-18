import 'package:flutter/material.dart';
import 'package:karrolle/features/studio/presentation/screens/studio_screen.dart';

void main() {
  runApp(const KarrolleApp());
}

class KarrolleApp extends StatelessWidget {
  const KarrolleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karrolle Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF252526),
        ),
      ),
      home: const StudioScreen(),
    );
  }
}
