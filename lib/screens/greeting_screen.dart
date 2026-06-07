import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'main_layout_screen.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> with TickerProviderStateMixin {
  int _step = 0;
  final _nameController = TextEditingController(text: 'Surya');
  int _selectedAvatar = 0;
  final List<String> _selectedGoals = [];
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _bgController;
  late Animation<Alignment> _bgAnim;

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

  final List<Map<String, dynamic>> _goalOptions = [
    {'id': 'productivity', 'label': '⚡ Produktivitas', 'desc': 'Fokus, Deep Work'},
    {'id': 'health', 'label': '💪 Kesehatan', 'desc': 'Olahraga, Tidur'},
    {'id': 'learning', 'label': '📚 Belajar', 'desc': 'Buku, Kursus'},
    {'id': 'mindfulness', 'label': '🧘 Mindfulness', 'desc': 'Meditasi, Stoic'},
    {'id': 'finance', 'label': '💰 Finansial', 'desc': 'Investasi, Nabung'},
    {'id': 'social', 'label': '🤝 Sosial', 'desc': 'Relasi, Networking'},
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _bgAnim = AlignmentTween(begin: const Alignment(-1, -1), end: const Alignment(1, 1))
        .animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_step == 0) {
      // Welcome → Name
      await _fadeController.reverse();
      setState(() => _step = 1);
      _fadeController.forward();
    } else if (_step == 1) {
      // Name → Goals
      final name = _nameController.text.trim();
      if (name.isEmpty) return;
      StorageService.saveUserName(name);
      StorageService.setAvatarIndex(_selectedAvatar);
      HapticFeedback.lightImpact();
      await _fadeController.reverse();
      setState(() => _step = 2);
      _fadeController.forward();
    } else {
      // Goals → Main App
      await _fadeController.reverse();
      setState(() => _isLoading = true);
      StorageService.setOnboarded();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const MainLayout(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    final user = await FirebaseService.signInWithGoogle();
    if (!mounted) return;
    if (user != null) {
      StorageService.setOnboarded();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const MainLayout(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
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
              radius: 1.8,
              colors: [AppTheme.purple.withOpacity(0.08), AppTheme.bg],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildWelcomeStep();
      case 1: return _buildNameStep();
      case 2: return _buildGoalsStep();
      default: return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          // Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.glowShadow(AppTheme.accent, blur: 24),
            ),
            child: const Icon(Icons.trending_up_rounded, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 40),
          const Text('1 2 3', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 4)),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
            child: const Text(
              'Mulai\nPerjalanan\nMu.',
              style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'GoGrow membantu kamu membangun kebiasaan baik, fokus pada tujuan, dan terus bertumbuh setiap hari.',
            style: AppTheme.bodyMedium.copyWith(fontSize: 15, height: 1.7),
          ),
          const Spacer(),
          // Google Sign In
          GestureDetector(
            onTap: _isLoading ? null : _signInWithGoogle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 20)],
              ),
              child: _isLoading
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google "G" logo menggunakan Text
                        const Text('G', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                        const SizedBox(width: 10),
                        const Text('Masuk dengan Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Skip / Local mode
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isLoading ? null : _nextStep,
              child: Text('Lanjut tanpa akun →', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildStepIndicator(1),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
            child: const Text('Siapa\nNama Kamu?', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -1)),
          ),
          const SizedBox(height: 12),
          Text('Kita akan personalisasi pengalaman kamu', style: AppTheme.bodyMedium),
          const SizedBox(height: 40),

          // Pilih Avatar
          Text('PILIH AVATAR', style: AppTheme.labelSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_avatarOptions.length, (i) {
              final opt = _avatarOptions[i];
              final isSelected = _selectedAvatar == i;
              return GestureDetector(
                onTap: () { setState(() => _selectedAvatar = i); HapticFeedback.selectionClick(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? (opt['color'] as Color).withOpacity(0.2) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? opt['color'] as Color : AppTheme.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? AppTheme.glowShadow(opt['color'] as Color, blur: 16) : null,
                  ),
                  child: Icon(opt['icon'] as IconData, color: opt['color'] as Color, size: 28),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Input Nama
          Text('NAMA KAMU', style: AppTheme.labelSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Masukkan namamu...',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.accent),
            ),
          ),

          const Spacer(),
          PrimaryButton(label: 'Lanjut →', onTap: _nextStep),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildStepIndicator(2),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
            child: const Text('Apa Fokus\nUtamamu?', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -1)),
          ),
          const SizedBox(height: 12),
          Text('Pilih satu atau lebih (bisa diubah nanti)', style: AppTheme.bodyMedium),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemCount: _goalOptions.length,
              itemBuilder: (_, i) {
                final goal = _goalOptions[i];
                final isSelected = _selectedGoals.contains(goal['id']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) _selectedGoals.remove(goal['id']);
                      else _selectedGoals.add(goal['id'] as String);
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentDim : AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.borderSubtle, width: isSelected ? 1.5 : 1),
                      boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.accent, blur: 12) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(goal['label'] as String, style: TextStyle(color: isSelected ? AppTheme.accent : AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(goal['desc'] as String, style: AppTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _isLoading ? 'Memulai...' : 'Mulai GoGrow 🚀',
            loading: _isLoading,
            onTap: _nextStep,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int current) {
    return Row(
      children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 8),
        width: i == current ? 28 : 8,
        height: 8,
        decoration: BoxDecoration(
          gradient: i == current ? AppTheme.accentGradient : null,
          color: i < current ? AppTheme.accent : (i == current ? null : AppTheme.borderMedium),
          borderRadius: BorderRadius.circular(4),
        ),
      )),
    );
  }
}