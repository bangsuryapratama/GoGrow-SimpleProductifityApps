import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _xp = 0;
  int _taskCount = 0;
  int _habitCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
    StorageService.syncNotifier.addListener(_onDataSynced);
  }

  @override
  void dispose() {
    StorageService.syncNotifier.removeListener(_onDataSynced);
    super.dispose();
  }

  void _onDataSynced() {
    if (mounted) {
      _loadProfileStats();
    }
  }

  Future<void> _loadProfileStats() async {
    final xp = await StorageService.getXP();
    final tasks = await StorageService.getTasks();
    final habits = await StorageService.getHabits();
    
    setState(() {
      _xp = xp;
      _taskCount = tasks.length;
      _habitCount = habits.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int level = (_xp / 100).floor() + 1;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Stoic & Wealth Profile", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // --- AVATAR & LEVEL ---
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFF00C853).withOpacity(0.12),
                          child: const Icon(Icons.psychology, color: Color(0xFF00C853), size: 48),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
                          child: Text("L$level", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text("Pengguna Hebat", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Pencari Kebijaksanaan Sejati", style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- STATS GRID VIEW (RESPONSIVE) ---
              isLandscape ? _buildLandscapeStats() : _buildPortraitStats(),

              const SizedBox(height: 28),

              // --- STOIC DAILY REMINDER ---
              const Text("FILOSOFIS HARI INI", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "“Jangan biarkan masa depan mengganggumu. Anda akan menemuinya, jika harus, dengan senjata nalar yang sama seperti saat menghadapi masa kini.”",
                      style: TextStyle(color: Colors.white70, height: 1.6, fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                    SizedBox(height: 12),
                    Text("- Marcus Aurelius, Meditations", style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.bold))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("Total XP", "$_xp", Icons.bolt, const Color(0xFF00C853))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Target Fokus", "$_taskCount", Icons.task_alt, Colors.cyanAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard("Rencana Habit", "$_habitCount", Icons.repeat, Colors.orangeAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Level Mental", "Stoic III", Icons.shield_outlined, Colors.redAccent)),
          ],
        )
      ],
    );
  }

  Widget _buildLandscapeStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total XP", "$_xp", Icons.bolt, const Color(0xFF00C853))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Target Fokus", "$_taskCount", Icons.task_alt, Colors.cyanAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Rencana Habit", "$_habitCount", Icons.repeat, Colors.orangeAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Level Mental", "Stoic III", Icons.shield_outlined, Colors.redAccent)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white30, fontSize: 11)),
        ],
      ),
    );
  }
}