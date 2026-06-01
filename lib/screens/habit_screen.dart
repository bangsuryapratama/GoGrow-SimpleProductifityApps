import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  DateTime _selectedDay = DateTime.now();
  late List<DateTime> _weekDays;

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
    super.dispose();
  }

  // Sinkron — tidak ada await
  void _onSync() {
    if (mounted) setState(() {});
  }

  List<DateTime> _buildWeekDays() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String _dayKey(DateTime d) => d.toIso8601String().substring(0, 10);

  // ─── Actions (semua sinkron) ───────────────────────────────────────────────
  void _toggleHabit(int index) {
    final dayKey = _dayKey(_selectedDay);
    final completed = StorageService.toggleHabitDay(index, dayKey);
    if (completed) {
      StorageService.addXP(10);
      final habits = StorageService.getHabits();
      if (index < habits.length) {
        NotificationService.showHabitDone(habits[index]['title'] ?? '');
      }
    } else {
      StorageService.addXP(-10);
    }
  }

  void _deleteHabit(int index) {
    final habits = StorageService.getHabits();
    if (index >= habits.length) return;
    final title = habits[index]['title'] as String? ?? '';
    StorageService.deleteHabit(index);
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
            top: 24, left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Tanam Kebiasaan Baru', style: AppTheme.headingMedium),
              const SizedBox(height: 18),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nama kebiasaan',
                  prefixIcon: Icon(Icons.edit, color: AppTheme.textMuted, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  hintText: 'Waktu pengingat (06:00)',
                  prefixIcon: Icon(Icons.alarm, color: AppTheme.textMuted, size: 18),
                ),
              ),
              const SizedBox(height: 18),
              const Text('PILIH SIMBOL', style: AppTheme.labelSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _iconMap.entries.map((e) {
                  final sel = selIcon == e.key;
                  return GestureDetector(
                    onTap: () => setModal(() => selIcon = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.accent : AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: sel ? AppTheme.accent : AppTheme.borderSubtle),
                      ),
                      child: Icon(e.value,
                          color: sel ? Colors.black : AppTheme.textSecondary,
                          size: 20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('WARNA', style: AppTheme.labelSmall),
              const SizedBox(height: 10),
              Row(
                children: _colorKeys.keys.map((key) {
                  final sel   = selColor == key;
                  final color = AppTheme.habitColor(key);
                  return GestureDetector(
                    onTap: () => setModal(() => selColor = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 10),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: sel ? Border.all(color: Colors.white, width: 2.5) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Tanam Habit',
                icon: Icons.spa,
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

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Sinkron dari cache — instant
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
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppTheme.pagePadding, 20, AppTheme.pagePadding, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Habit Tracker', style: AppTheme.headingLarge),
                  SizedBox(height: 4),
                  Text('Konsistensi kecil setiap hari menghasilkan perubahan besar.',
                      style: AppTheme.bodyMedium),
                ],
              ),
            ),

            _buildWeekCalendar(days, habits),
            const SizedBox(height: 16),
            _buildStatsRow(completedCount, habits.length),
            const SizedBox(height: 16),
            const SectionLabel('Kebiasaan Hari Ini'),
            const SizedBox(height: 10),

            Expanded(
              child: habits.isEmpty
                  ? const EmptyState(
                      icon: Icons.spa_outlined,
                      message: 'Belum ada habit yang ditanam.',
                      subtitle: 'Tekan tombol + untuk memulai!',
                    )
                  : _buildHabitList(habits, dayKey),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Week Calendar ──────────────────────────────────────────────────────────
  Widget _buildWeekCalendar(List<String> daysAbbr, List<Map<String, dynamic>> habits) =>
      Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
    child: SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_weekDays.length, (i) {
          final day      = _weekDays[i];
          final key      = _dayKey(day);
          final isSel    = key == _dayKey(_selectedDay);
          final isToday  = key == _dayKey(DateTime.now());

          final doneCount = habits.where((h) {
            final List dates = h['completedDates'] ?? [];
            return dates.contains(key);
          }).length;

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  Text(daysAbbr[i],
                      style: TextStyle(
                        color: isSel ? Colors.black : (isToday ? AppTheme.accent : AppTheme.textMuted),
                        fontSize: 10, fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 6),
                  Text(day.day.toString(),
                      style: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                        fontSize: 15, fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  // Dot indikator progress
                  doneCount == 0
                      ? const SizedBox(height: 5, width: 5)
                      : Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: isSel
                                ? Colors.black
                                : (doneCount == habits.length
                                    ? AppTheme.accent
                                    : AppTheme.accent.withOpacity(0.45)),
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

  // ─── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(int done, int total) {
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selesai', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('$done/$total',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progres', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: AppTheme.surfaceAlt,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(progress * 100).toInt()}%',
                      style: const TextStyle(
                          color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Habit List ─────────────────────────────────────────────────────────────
  Widget _buildHabitList(List<Map<String, dynamic>> habits, String dayKey) =>
      ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
    itemCount: habits.length,
    itemBuilder: (ctx, i) {
      final habit  = habits[i];
      final List dates = habit['completedDates'] ?? [];
      final isDone = dates.contains(dayKey);
      final color  = AppTheme.habitColor(habit['color']);
      final streak = StorageService.habitStreak(habit);

      return Dismissible(
        key: Key('habit_${habit['id'] ?? i}'),
        direction: DismissDirection.endToStart,
        background: const DismissBackground(),
        onDismissed: (_) => _deleteHabit(i),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isDone ? color.withOpacity(0.3) : AppTheme.borderSubtle,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            onTap: () => _toggleHabit(i),
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isDone ? color : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : (_iconMap[habit['icon']] ?? Icons.spa),
                color: isDone ? Colors.white : color,
                size: 20,
              ),
            ),
            title: Text(
              habit['title'] ?? '',
              style: TextStyle(
                color: isDone ? AppTheme.textMuted : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppTheme.textMuted,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  const Icon(Icons.alarm, color: AppTheme.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(habit['time'] ?? '06:00',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  if (streak > 0) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.local_fire_department,
                        color: Colors.orangeAccent, size: 12),
                    const SizedBox(width: 3),
                    Text('$streak hari',
                        style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}