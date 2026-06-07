import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import 'greeting_screen.dart';
import 'main_layout_screen.dart';
import '../widgets/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _bgController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  late Animation<Alignment> _bgAnim;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgAnim = AlignmentTween(
      begin: const Alignment(-1, -1),
      end: const Alignment(1, 1),
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _logoController.forward();

    Timer(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    final hasOnboarded = StorageService.hasOnboarded();

    Widget destination;
    if (user != null || hasOnboarded) {
      destination = const MainLayout();
    } else {
      destination = const GreetingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _bgAnim.value,
              radius: 1.5,
              colors: [
                AppTheme.accent.withOpacity(0.08),
                AppTheme.bg,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glow behind logo
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, child) => Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow ring
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.3 * _glowAnim.value),
                              blurRadius: 60 * _glowAnim.value,
                              spreadRadius: 10 * _glowAnim.value,
                            ),
                          ],
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(Icons.trending_up_rounded, size: 52, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
                        child: const Text(
                          'GOGROW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grow Every Day',
                        style: AppTheme.bodyMedium.copyWith(letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}