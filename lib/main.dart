import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/storage_service.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await StorageService.init();
  FirebaseService.init();
  FirebaseService.setupAutoSync();
  runApp(const GoGrowApp());
}

class GoGrowApp extends StatelessWidget {
  const GoGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoGrow',
      theme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.darkTheme.textTheme)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const SplashScreen(),
    );
  }
}