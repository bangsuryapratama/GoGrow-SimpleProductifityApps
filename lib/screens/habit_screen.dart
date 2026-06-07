import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> with TickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  late List<DateTime> _weekDays;

  // Tracks which habit is animating (check bounce)
  final Map<String, AnimationController> _checkControllers = {};

  static const Map<String, IconData> _iconMap = {
    'spa':      Icons.spa,
    'book':     Icons.menu_book,
    'computer': Icons.computer,
    'sport':    Icons.directions_run,
    'water':    Icons.local_drink,
    'sleep':    Icons.bedtime,
    'heart':    Icons.favorite,
    'music':    Icons.music_note,
  };

  static const Map<String, String> _colorKeys = {
    'green':  'Hijau',
    'blue':   'Biru',
    'orange': 'Oranye',
    'red':    'Merah',
    'purple': 'Ungu',
    'cyan':   'Cyan',
  };

  @override
  void initState() {
    super.initState();
    _weekDays = _buildWeekDays();
    StorageService.syncNotifier.addListener(_onSync);
  }

  @override
  void dispose() {
    StorageService.syncNotifier.removeListener(_onSync);
    for (final c in _checkControllers.values) { c.dispose(); }
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  List<DateTime> _buildWeekDays() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String _dayKey(DateTime d) => d.toIso8601String().substring(0, 10);

  AnimationController _getOrCreateController(String habitId) {
    return _checkControllers.putIfAbsent(
      habitId,
      () => AnimationController(vsync: this, duration: const Duration(milliseconds: 400)),
    );
  }

  void _toggleHabit(int index) {
    final dayKey   = _dayKey(_selectedDay);
    final completed = StorageService.toggleHabitDay(index, dayKey);
    final habits   = StorageService.getHabits();

    if (completed) {
      StorageService.addXP(10);
      HapticFeedback.mediumImpact();
      if (index < habits.length) {
        final habitId = habits[index]['id'] as String? ?? '$index';
        final ctrl = _getOrCreateController(habitId);
        ctrl.forward(from: 0);
        NotificationService.showHabitDone(habits[index]['title'] ?? '');
      }
    } else {
      StorageService.addXP(-10);
      HapticFeedback.lightImpact();
    }
  }

  void _deleteHabit(int index) {
    final habits = StorageService.getHabits();
    if (index >= habits.length) return;
    final title = habits[index]['title'] as String? ?? '';
    StorageService.deleteHabit(index);
    HapticFeedback.lightImpact();
    NotificationService.show(
      title: 'Habit Dihapus',
      message: "'$title' telah dicabut dari jadwal.",
      icon: Icons.delete_outline,
      accentColor: AppTheme.danger,
    );
  }

  void _showAddSheet() {
    final titleCtrl = TextEditingController();
    final timeCtrl  = TextEditingController(text: '06:00');
    String selIcon  = 'spa';
    String selColor = 'green';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            top: 8, left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Tanam Kebiasaan Baru', style: AppTheme.headingMedium),
              const SizedBox(height: 18),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nama kebiasaan...',
                  prefixIcon: const Icon(Icons.edit_outlined, color: AppTheme.textMuted, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  hintText: 'Waktu (06:00)',
                  prefixIcon: const Icon(Icons.alarm_outlined, color: AppTheme.textMuted, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              Text('PILIH SIMBOL', style: AppTheme.labelSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _iconMap.entries.map((e) {
                  final sel = selIcon == e.key;
                  return GestureDetector(
                    onTap: () { setModal(() => selIcon = e.key); HapticFeedback.selectionClick(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: sel ? AppTheme.accentGradient : null,
                        color: sel ? null : AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: sel ? AppTheme.accent : AppTheme.borderSubtle),
                        boxShadow: sel ? AppTheme.glowShadow(AppTheme.accent, blur: 12) : null,
                      ),
                      child: Icon(e.value, color: sel ? Colors.black : AppTheme.textSecondary, size: 20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('WARNA', style: AppTheme.labelSmall),
              const SizedBox(height: 12),
              Row(
                children: _colorKeys.keys.map((key) {
                  final sel   = selColor == key;
                  final color = AppTheme.habitColor(key);
                  return GestureDetector(
                    onTap: () { setModal(() => selColor = key); HapticFeedback.selectionClick(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 10),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: sel ? Border.all(color: Colors.white, width: 2.5) : null,
                        boxShadow: sel ? AppTheme.glowShadow(color, blur: 12) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Tanam Habit 🌱',
                onTap: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  StorageService.addHabit({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': titleCtrl.text.trim(),
                    'time': timeCtrl.text.trim(),
                    'icon': selIcon,
                    'color': selColor,
                    'completedDates': <String>[],
                  });
                  HapticFeedback.mediumImpact();
                  NotificationService.showHabitAdded(titleCtrl.text.trim());
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits  = StorageService.getHabits();
    final dayKey  = _dayKey(_selectedDay);
    final days    = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final completedCount = habits.where((h) {
      final List dates = h['completedDates'] ?? [];
      return dates.contains(dayKey);
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        onPressed: _showAddSheet,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habit Tracker', style: AppTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Konsistensi kecil setiap hari menghasilkan perubahan besar.', style: AppTheme.bodyMedium),
                  ],
                ),
              ),
            ),

            // ── Week Calendar / Heatmap ────────────────────────────────────
            SliverToBoxAdapter(child: _buildWeekCalendar(days, habits)),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Stats Row ─────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildStatsRow(completedCount, habits.length)),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KEBIASAAN HARI INI', style: AppTheme.labelSmall),
                    Text('$completedCount/${habits.length}', style: AppTheme.captionStyle),
                  ],
                ),
              ),
            ),

            // ── Habit List ────────────────────────────────────────────────
            habits.isEmpty
                ? SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.spa_outlined,
                      message: 'Belum ada habit yang ditanam.',
                      subtitle: 'Tekan tombol + untuk memulai!',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _buildHabitCard(habits[i], i, dayKey),
                        childCount: habits.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Week Calendar / Heatmap ──────────────────────────────────────────────
  Widget _buildWeekCalendar(List<String> daysAbbr, List<Map<String, dynamic>> habits) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_weekDays.length, (i) {
              final day     = _weekDays[i];
              final key     = _dayKey(day);
              final isSel   = key == _dayKey(_selectedDay);
              final isToday = key == _dayKey(DateTime.now());

              final doneCount = habits.where((h) {
                final List dates = h['completedDates'] ?? [];
                return dates.contains(key);
              }).length;

              // Heatmap: makin banyak selesai, makin terang
              final heatIntensity = habits.isEmpty ? 0.0 : (doneCount / habits.length).clamp(0.0, 1.0);

              return GestureDetector(
                onTap: () { setState(() => _selectedDay = day); HapticFeedback.selectionClick(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSel ? AppTheme.accentGradient : null,
                    color: isSel ? null : (heatIntensity > 0 ? AppTheme.accent.withOpacity(0.08 + 0.12 * heatIntensity) : Colors.transparent),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: isSel ? AppTheme.glowShadow(AppTheme.accent, blur: 12) : null,
                  ),
                  child: Column(
                    children: [
                      Text(daysAbbr[i],
                        style: TextStyle(
                          color: isSel ? Colors.black : (isToday ? AppTheme.accent : AppTheme.textMuted),
                          fontSize: 10, fontWeight: FontWeight.bold,
                        )),
                      const SizedBox(height: 6),
                      Text('${day.day}',
                        style: TextStyle(
                          color: isSel ? Colors.black : AppTheme.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.bold,
                        )),
                      const SizedBox(height: 4),
                      // Dot heatmap
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: doneCount == 0
                              ? Colors.transparent
                              : (isSel ? Colors.black : AppTheme.accent.withOpacity(0.4 + 0.6 * heatIntensity)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      );

  // ── Stats Row ────────────────────────────────────────────────────────────
  Widget _buildStatsRow(int done, int total) {
    final progress = total == 0 ? 0.0 : done / total;
    final allStreaks = StorageService.getHabits().map((h) => StorageService.habitStreak(h));
    final bestStreak = allStreaks.isEmpty ? 0 : allStreaks.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SELESAI', style: AppTheme.labelSmall),
                  const SizedBox(height: 8),
                  Text('$done/$total', style: TextStyle(color: AppTheme.accent, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROGRES', style: AppTheme.labelSmall),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: AppTheme.surfaceHigh,
                        valueColor: AlwaysStoppedAnimation(AppTheme.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(progress * 100).toInt()}%', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STREAK', style: AppTheme.labelSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: AppTheme.orange, size: 20),
                      const SizedBox(width: 4),
                      Text('$bestStreak', style: const TextStyle(color: AppTheme.orange, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Habit Card ────────────────────────────────────────────────────────────
  Widget _buildHabitCard(Map<String, dynamic> habit, int index, String dayKey) {
    final List dates = habit['completedDates'] ?? [];
    final isDone  = dates.contains(dayKey);
    final color   = AppTheme.habitColor(habit['color']);
    final streak  = StorageService.habitStreak(habit);
    final habitId = habit['id'] as String? ?? '$index';
    final ctrl    = _getOrCreateController(habitId);

    return Dismissible(
      key: Key('habit_${habit['id'] ?? index}'),
      direction: DismissDirection.endToStart,
      background: const DismissBackground(),
      onDismissed: (_) => _deleteHabit(index),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 250 + index * 60),
        curve: Curves.easeOut,
        builder: (_, v, child) => Opacity(
          opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
        ),
        child: GestureDetector(
          onTap: () => _toggleHabit(index),
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + 0.04 * (ctrl.status == AnimationStatus.forward
                  ? Curves.elasticOut.transform(ctrl.value)
                  : 0),
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: isDone ? color.withOpacity(0.4) : AppTheme.borderSubtle),
                boxShadow: isDone ? AppTheme.glowShadow(color, blur: 12) : AppTheme.cardShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    // Icon circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: isDone ? AppTheme.accentGradient : null,
                        color: isDone ? null : color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        boxShadow: isDone ? AppTheme.glowShadow(color, blur: 10) : null,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : (_iconMap[habit['icon']] ?? Icons.spa),
                        color: isDone ? Colors.black : color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: isDone ? AppTheme.textMuted : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              decorationColor: AppTheme.textMuted,
                            ),
                            child: Text(habit['title'] ?? ''),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.alarm_outlined, color: AppTheme.textMuted, size: 12),
                              const SizedBox(width: 4),
                              Text(habit['time'] ?? '06:00', style: AppTheme.captionStyle),
                              if (streak > 0) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.local_fire_department, color: AppTheme.orange, size: 13),
                                const SizedBox(width: 2),
                                Text('$streak hari', style: const TextStyle(color: AppTheme.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Check indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        gradient: isDone ? AppTheme.accentGradient : null,
                        color: isDone ? null : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isDone ? null : Border.all(color: AppTheme.textMuted, width: 1.5),
                      ),
                      child: isDone ? const Icon(Icons.check_rounded, color: Colors.black, size: 14) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}