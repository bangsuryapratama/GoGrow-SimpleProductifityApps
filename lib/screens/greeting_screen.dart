import 'dart:math';
import 'package:GoGrow/screens/main_layout_screen.dart';
import 'package:flutter/material.dart';



class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> with SingleTickerProviderStateMixin {
  final List<String> _affirmations = [
    "Kendalikan pikiranmu, kendalikan realitasmu.",
    "Bukan tentang durasi, tapi tentang intensitas.",
    "Hapus yang tidak perlu. Tumbuhkan yang esensial.",
    "Dedikasi adalah bentuk tertinggi dari kebebasan."
  ];

  late String _currentAffirmation;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _currentAffirmation = _affirmations[Random().nextInt(_affirmations.length)];
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _controller.forward();
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1200),
          pageBuilder: (_, __, ___) => const MainLayout(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Garis dekoratif premium
              Container(width: 40, height: 1, color: Colors.white24),
              const SizedBox(height: 32),
              Text(
                _currentAffirmation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Garis dekoratif premium
              Container(width: 40, height: 1, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}