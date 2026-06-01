import 'package:flutter/material.dart';
import 'package:GoGrow/screens/dashboard_screen.dart';
import 'package:GoGrow/screens/growmind_screen.dart';
import 'package:GoGrow/screens/habit_screen.dart';
import 'package:GoGrow/screens/profile_screen.dart';
import 'package:GoGrow/widgets/app_nav_bar.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    HabitScreen(),
    GrowMindScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ProfessionalNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}