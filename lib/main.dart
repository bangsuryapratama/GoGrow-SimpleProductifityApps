import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const GoGrowApp());

class GoGrowApp extends StatelessWidget {
  const GoGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}