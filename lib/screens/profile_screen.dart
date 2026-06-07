import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  // BUG FIX: Tidak ada await lagi — semua getter sinkron dari cache
  int get _xp => StorageService.getXP();
  List get _tasks => StorageService.getTasks();
  List get _habits => StorageService.getHabits();
  String get _name => StorageService.getUserName();
  int get _avatarIndex => StorageService.getAvatarIndex();

  late AnimationController _statsController;
  late AnimationController _bgController;
  late Animation<double> _statsAnim;
  late Animation<Alignment> _bgAnim;

  bool _isEditingName = false;
  final _nameEditController = TextEditingController();

  // Quote harian — berputar berdasarkan tanggal
  static const List<Map<String, String>> _quotes = [
    {'text': '"Jangan biarkan masa depan mengganggumu. Kamu akan menemuinya, jika harus, dengan senjata nalar yang sama seperti saat menghadapi masa kini."', 'author': 'Marcus Aurelius'},
    {'text': '"Kita menderita lebih banyak dalam imajinasi daripada dalam kenyataan."', 'author': 'Seneca'},
    {'text': '"Pertama, katakan pada dirimu sendiri apa yang kamu inginkan; lalu lakukan apa yang harus kamu lakukan."', 'author': 'Epictetus'},
    {'text': '"Rugi waktu adalah pencurian terbesar dari dirimu sendiri."', 'author': 'Marcus Aurelius'},
    {'text': '"Bukan kesulitan yang membuat kita takut, melainkan ketakutan yang membuatnya sulit."', 'author': 'Seneca'},
    {'text': '"Setiap hambatan adalah bahan mentah — di tanganmu, ia bisa menjadi keberhasilan."', 'author': 'Marcus Aurelius'},
    {'text': '"Orang yang paling bahagia adalah orang yang tidak butuh orang lain untuk bahagia."', 'author': 'Marcus Aurelius'},
  ];

  Map<String, String> get _todayQuote {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  final List<Map<String, dynamic>> _avatarOptions = [
    {'icon': Icons.psychology, 'color': AppTheme.accent},
    {'icon': Icons.rocket_launch, 'color': AppTheme.purple},
    {'icon': Icons.local_fire_department, 'color': AppTheme.orange},
    {'icon': Icons.bolt, 'color': AppTheme.warning},
    {'icon': Icons.spa, 'color': AppTheme.cyan},
    {'icon': Icons.auto_graph, 'color': AppTheme.blue},
    {'icon': Icons.military_tech, 'color': AppTheme.danger},
    {'icon': Icons.stars, 'color': AppTheme.accent},
  ];

  @override
  void initState() {
    super.initState();
    StorageService.syncNotifier.addListener(_onSync);

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _bgAnim = AlignmentTween(begin: const Alignment(1, -1), end: const Alignment(-1, 1))
        .animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _statsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _statsAnim = CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic);
    _statsController.forward();
  }

  @override
  void dispose() {
    StorageService.syncNotifier.removeListener(_onSync);
    _statsController.dispose();
    _bgController.dispose();
    _nameEditController.dispose();
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  void _startEditName() {
    _nameEditController.text = _name;
    setState(() => _isEditingName = true);
  }

  void _saveName() {
    final trimmed = _nameEditController.text.trim();
    if (trimmed.isNotEmpty) {
      StorageService.saveUserName(trimmed);
      HapticFeedback.lightImpact();
    }
    setState(() => _isEditingName = false);
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PILIH AVATAR', style: AppTheme.labelSmall),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_avatarOptions.length, (i) {
                final opt = _avatarOptions[i];
                final isSelected = _avatarIndex == i;
                return GestureDetector(
                  onTap: () {
                    StorageService.setAvatarIndex(i);
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? (opt['color'] as Color).withOpacity(0.2) : AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? opt['color'] as Color : AppTheme.borderSubtle, width: isSelected ? 2 : 1),
                      boxShadow: isSelected ? AppTheme.glowShadow(opt['color'] as Color, blur: 16) : null,
                    ),
                    child: Icon(opt['icon'] as IconData, color: opt['color'] as Color, size: 30),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xp = _xp;
    final level = StorageService.calculateLevel(xp);
    final progress = StorageService.levelProgress(xp);
    final xpNext = StorageService.xpForNextLevel(xp);
    final tasksDone = _tasks.where((t) => t['isDone'] == true).length;
    final totalTasks = _tasks.length;
    final totalHabits = _habits.length;
    final avatar = _avatarOptions[_avatarIndex.clamp(0, _avatarOptions.length - 1)];
    final isLoggedIn = FirebaseService.isLoggedIn;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _bgAnim.value,
              radius: 1.5,
              colors: [AppTheme.purple.withOpacity(0.05), AppTheme.bg],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profil', style: AppTheme.headingLarge),
                        if (isLoggedIn)
                          GestureDetector(
                            onTap: () async {
                              await FirebaseService.syncToCloud();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✓ Data disinkronkan ke cloud'), backgroundColor: AppTheme.accent, duration: Duration(seconds: 2)),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.accentDim, borderRadius: BorderRadius.circular(10)),
                              child: const Row(
                                children: [
                                  Icon(Icons.cloud_done_outlined, color: AppTheme.accent, size: 16),
                                  SizedBox(width: 6),
                                  Text('Sync', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Avatar & Name ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          // Avatar dengan glow
                          GestureDetector(
                            onTap: _showAvatarPicker,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                AnimatedBuilder(
                                  animation: _bgController,
                                  builder: (_, child) => Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [(avatar['color'] as Color).withOpacity(0.2 + 0.05 * sin(_bgController.value * 3.14)), AppTheme.surface],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (avatar['color'] as Color).withOpacity(0.3 + 0.1 * sin(_bgController.value * 3.14)),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(avatar['icon'] as IconData, color: avatar['color'] as Color, size: 48),
                                  ),
                                ),
                                // Level badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('L$level', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 11)),
                                ),
                                // Camera icon untuk edit
                                Positioned(
                                  bottom: 24,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle, border: Border.all(color: AppTheme.borderMedium)),
                                    child: const Icon(Icons.edit, size: 12, color: AppTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nama (editable)
                          GestureDetector(
                            onTap: _startEditName,
                            child: _isEditingName
                                ? SizedBox(
                                    width: 200,
                                    child: TextField(
                                      controller: _nameEditController,
                                      autofocus: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (_) => _saveName(),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.edit_outlined, size: 14, color: AppTheme.textMuted),
                                    ],
                                  ),
                          ),
                          if (_isEditingName) ...[
                            const SizedBox(height: 8),
                            GestureDetector(onTap: _saveName, child: Text('Simpan', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold))),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            isLoggedIn ? (FirebaseService.userEmail ?? 'User GoGrow') : 'Mode Lokal',
                            style: AppTheme.bodySmall,
                          ),

                          const SizedBox(height: 24),

                          // XP Progress Ring
                          AnimatedProgressRing(
                            progress: progress,
                            size: 100,
                            strokeWidth: 7,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$xp', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('XP', style: AppTheme.captionStyle),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('$xpNext XP menuju Level ${level + 1}', style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Stats Grid ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedBuilder(
                      animation: _statsAnim,
                      builder: (_, __) => Opacity(
                        opacity: _statsAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _statsAnim.value)),
                          child: Row(
                            children: [
                              _StatCard(label: 'Task Selesai', value: '$tasksDone/$totalTasks', icon: Icons.task_alt, color: AppTheme.accent),
                              const SizedBox(width: 12),
                              _StatCard(label: 'Habit Aktif', value: '$totalHabits', icon: Icons.repeat_on, color: AppTheme.purple),
                              const SizedBox(width: 12),
                              _StatCard(label: 'Level', value: 'L$level', icon: Icons.shield_outlined, color: AppTheme.orange),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Daily Quote ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FILOSOFI HARI INI', style: AppTheme.labelSmall),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
                                child: const Icon(Icons.format_quote, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _todayQuote['text']!,
                                style: const TextStyle(color: AppTheme.textSecondary, height: 1.7, fontStyle: FontStyle.italic, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '— ${_todayQuote['author']}',
                                style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Google Login / Sign Out ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: isLoggedIn
                        ? GestureDetector(
                            onTap: () async {
                              await FirebaseService.signOut();
                              if (mounted) setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerDim,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, color: AppTheme.danger, size: 18),
                                  SizedBox(width: 8),
                                  Text('Sign Out', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final user = await FirebaseService.signInWithGoogle();
                              if (mounted && user != null) setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('G', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                                  SizedBox(width: 10),
                                  Text('Sambungkan akun Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.captionStyle, maxLines: 2),
        ],
      ),
    ),
  );
}